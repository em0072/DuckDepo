//
//  PasskeyAuthenticator.swift
//  DuckDepo
//

import CryptoKit
import Foundation

/// The WebAuthn authenticator part of passkeys: what a site receives when a passkey is made and when
/// it signs in (W3C Web Authentication, CTAP2 encodings).
///
/// Passkeys are ES256 (ECDSA on P-256 with SHA-256). They sync through iCloud Keychain, so they're
/// reported as backed up, with a signature counter of 0, as Apple's own passkeys are.
enum PasskeyAuthenticator {

    enum Failure: Error {
        case unreadableKey
    }

    /// No attestation, so the authenticator isn't identified.
    static let aaguid = Data(count: 16)

    /// Authenticator data flags.
    struct Flags: OptionSet {
        let rawValue: UInt8
        static let userPresent = Flags(rawValue: 0x01)
        static let userVerified = Flags(rawValue: 0x04)
        static let backupEligible = Flags(rawValue: 0x08)
        static let backedUp = Flags(rawValue: 0x10)
        static let attestedCredentialData = Flags(rawValue: 0x40)
    }

    /// The flags of every response: the user was there, and the passkey syncs.
    static func flags(userVerified: Bool) -> Flags {
        var flags: Flags = [.userPresent, .backupEligible, .backedUp]
        if userVerified {
            flags.insert(.userVerified)
        }
        return flags
    }

    /// SHA-256 of the relying party ID, the flags, a zero signature counter, then attested credential
    /// data when there is any.
    static func authenticatorData(relyingParty: String, flags: Flags, attestedCredentialData: Data? = nil) -> Data {
        var data = Data(SHA256.hash(data: Data(relyingParty.utf8)))
        data.append(flags.rawValue)
        data.append(contentsOf: [0, 0, 0, 0])
        if let attestedCredentialData {
            data.append(attestedCredentialData)
        }
        return data
    }

    /// The public key as a COSE_Key: EC2, ES256, P-256, x, y.
    static func coseKey(for publicKey: P256.Signing.PublicKey) -> Data {
        let point = publicKey.x963Representation   // 0x04 ‖ x ‖ y
        return CBOR.map([
            (.int(1), .int(2)),
            (.int(3), .int(-7)),
            (.int(-1), .int(1)),
            (.int(-2), .bytes(point[1..<33])),
            (.int(-3), .bytes(point[33..<65])),
        ]).encoded
    }

    // MARK: - Registration

    /// The attestation object for a new passkey: "none" attestation and authenticator data carrying the
    /// credential ID and public key.
    static func attestationObject(for passkey: Passkey, userVerified: Bool) throws -> Data {
        guard let key = passkey.signingKey else { throw Failure.unreadableKey }
        var attested = aaguid
        let length = UInt16(passkey.credentialID.count)
        attested.append(UInt8(length >> 8))
        attested.append(UInt8(length & 0xFF))
        attested.append(passkey.credentialID)
        attested.append(coseKey(for: key.publicKey))
        let authenticatorData = authenticatorData(relyingParty: passkey.relyingParty,
                                                  flags: flags(userVerified: userVerified).union(.attestedCredentialData),
                                                  attestedCredentialData: attested)
        // Canonical CTAP2 order: shorter keys first.
        return CBOR.map([
            (.text("fmt"), .text("none")),
            (.text("attStmt"), .map([])),
            (.text("authData"), .bytes(authenticatorData)),
        ]).encoded
    }

    // MARK: - Sign-in

    struct Assertion {
        let authenticatorData: Data
        /// DER-encoded ECDSA signature over the authenticator data followed by the client data hash.
        let signature: Data
    }

    static func assertion(for passkey: Passkey, clientDataHash: Data, userVerified: Bool) throws -> Assertion {
        guard let key = passkey.signingKey else { throw Failure.unreadableKey }
        let authenticatorData = authenticatorData(relyingParty: passkey.relyingParty, flags: flags(userVerified: userVerified))
        let signature = try key.signature(for: authenticatorData + clientDataHash)
        return Assertion(authenticatorData: authenticatorData, signature: signature.derRepresentation)
    }
}

/// The few CBOR types WebAuthn needs (RFC 8949), encoded in the shortest form, as CTAP2 requires.
indirect enum CBOR {
    case int(Int64)
    case bytes(Data)
    case text(String)
    /// Pairs in the order given, which must be CTAP2 canonical order.
    case map([(CBOR, CBOR)])

    var encoded: Data {
        var data = Data()
        append(to: &data)
        return data
    }

    private func append(to data: inout Data) {
        switch self {
        case .int(let value):
            if value >= 0 {
                Self.appendHead(major: 0, value: UInt64(value), to: &data)
            } else {
                Self.appendHead(major: 1, value: UInt64(-1 - value), to: &data)
            }
        case .bytes(let bytes):
            Self.appendHead(major: 2, value: UInt64(bytes.count), to: &data)
            data.append(bytes)
        case .text(let text):
            let utf8 = Data(text.utf8)
            Self.appendHead(major: 3, value: UInt64(utf8.count), to: &data)
            data.append(utf8)
        case .map(let pairs):
            Self.appendHead(major: 5, value: UInt64(pairs.count), to: &data)
            for (key, value) in pairs {
                key.append(to: &data)
                value.append(to: &data)
            }
        }
    }

    private static func appendHead(major: UInt8, value: UInt64, to data: inout Data) {
        let type = major << 5
        switch value {
        case 0..<24:
            data.append(type | UInt8(value))
        case 24..<0x100:
            data.append(type | 24)
            data.append(UInt8(value))
        case 0x100..<0x10000:
            data.append(type | 25)
            data.append(contentsOf: [UInt8(value >> 8), UInt8(value & 0xFF)])
        case 0x10000..<0x1_0000_0000:
            data.append(type | 26)
            data.append(contentsOf: (0..<4).reversed().map { UInt8((value >> (8 * UInt64($0))) & 0xFF) })
        default:
            data.append(type | 27)
            data.append(contentsOf: (0..<8).reversed().map { UInt8((value >> (8 * UInt64($0))) & 0xFF) })
        }
    }
}
