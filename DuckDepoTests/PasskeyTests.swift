//
//  PasskeyTests.swift
//  DuckDepoTests
//

import CryptoKit
import Foundation
import Testing
@testable import DuckDepo

struct CBORTests {

    private func hex(_ data: Data) -> String {
        data.map { String(format: "%02x", $0) }.joined()
    }

    /// RFC 8949 appendix A examples.
    @Test func encodesTheShortestForm() {
        #expect(hex(CBOR.int(0).encoded) == "00")
        #expect(hex(CBOR.int(23).encoded) == "17")
        #expect(hex(CBOR.int(24).encoded) == "1818")
        #expect(hex(CBOR.int(1000).encoded) == "1903e8")
        #expect(hex(CBOR.int(1_000_000).encoded) == "1a000f4240")
        #expect(hex(CBOR.int(-1).encoded) == "20")
        #expect(hex(CBOR.int(-7).encoded) == "26")
        #expect(hex(CBOR.int(-100).encoded) == "3863")
        #expect(hex(CBOR.bytes(Data()).encoded) == "40")
        #expect(hex(CBOR.bytes(Data([1, 2, 3, 4])).encoded) == "4401020304")
        #expect(hex(CBOR.text("IETF").encoded) == "6449455446")
        #expect(hex(CBOR.map([]).encoded) == "a0")
        #expect(hex(CBOR.map([(.int(1), .int(2)), (.int(3), .int(4))]).encoded) == "a201020304")
    }
}

struct PasskeyAuthenticatorTests {

    private let passkey = Passkey.make(relyingParty: "webauthn.io", userName: "jane", userHandle: Data("user-1".utf8))
    private let clientDataHash = Data(SHA256.hash(data: Data(#"{"type":"webauthn.get"}"#.utf8)))

    @Test func theCOSEKeyIsAnES256P256Key() throws {
        let key = try #require(passkey.signingKey).publicKey
        let cose = PasskeyAuthenticator.coseKey(for: key)
        let point = key.x963Representation
        // {1: 2, 3: -7, -1: 1, -2: x, -3: y}
        var expected = Data([0xA5, 0x01, 0x02, 0x03, 0x26, 0x20, 0x01, 0x21, 0x58, 0x20])
        expected.append(point[1..<33])
        expected.append(contentsOf: [0x22, 0x58, 0x20])
        expected.append(point[33..<65])
        #expect(cose == expected)
        #expect(cose.count == 77)
    }

    @Test func theAttestationObjectCarriesTheCredential() throws {
        let object = try PasskeyAuthenticator.attestationObject(for: passkey, userVerified: true)
        // {"fmt": "none", "attStmt": {}, "authData": bytes(148)}
        var header = Data([0xA3, 0x63])
        header.append(Data("fmt".utf8))
        header.append(0x64)
        header.append(Data("none".utf8))
        header.append(0x67)
        header.append(Data("attStmt".utf8))
        header.append(contentsOf: [0xA0, 0x68])
        header.append(Data("authData".utf8))
        header.append(contentsOf: [0x58, 148])
        #expect(object.prefix(header.count) == header)
        let authData = object.dropFirst(header.count)
        #expect(authData.count == 148)
        let bytes = Array(authData)
        #expect(Data(bytes[0..<32]) == Data(SHA256.hash(data: Data("webauthn.io".utf8))))
        // User present, user verified, backup eligible, backed up, attested credential data.
        #expect(bytes[32] == 0x5D)
        #expect(bytes[33..<37] == [0, 0, 0, 0])
        #expect(bytes[37..<53] == ArraySlice(repeating: 0, count: 16))
        #expect(bytes[53..<55] == [0x00, 0x10])
        #expect(Data(bytes[55..<71]) == passkey.credentialID)
        let cose = PasskeyAuthenticator.coseKey(for: try #require(passkey.signingKey).publicKey)
        #expect(Data(bytes[71...]) == cose)
    }

    @Test func signInSignaturesVerifyWithThePublicKey() throws {
        let assertion = try PasskeyAuthenticator.assertion(for: passkey, clientDataHash: clientDataHash, userVerified: true)
        #expect(assertion.authenticatorData.count == 37)
        #expect(assertion.authenticatorData[32] == 0x1D)
        let publicKey = try #require(passkey.signingKey).publicKey
        let signature = try P256.Signing.ECDSASignature(derRepresentation: assertion.signature)
        #expect(publicKey.isValidSignature(signature, for: assertion.authenticatorData + clientDataHash))
        // Bound to this request: another client data hash doesn't verify.
        #expect(!publicKey.isValidSignature(signature, for: assertion.authenticatorData + Data(count: 32)))
    }

    @Test func withoutVerificationTheFlagSaysSo() throws {
        let assertion = try PasskeyAuthenticator.assertion(for: passkey, clientDataHash: clientDataHash, userVerified: false)
        #expect(assertion.authenticatorData[32] == 0x19)
    }
}

struct PasskeyStorageTests {

    @Test func savesListsFindsAndDeletesPasskeys() {
        let keychain = InMemoryKeychain()
        keychain.set("a password", forKey: UUID().uuidString)
        let storage = PasskeyStorage(keychain: keychain)
        let github = Passkey.make(relyingParty: "github.com", userName: "jane", userHandle: Data([1]))
        let github2 = Passkey.make(relyingParty: "github.com", userName: "jane-work", userHandle: Data([2]))
        let example = Passkey.make(relyingParty: "example.com", userName: "joe", userHandle: Data([3]))
        for passkey in [github, github2, example] {
            #expect(storage.save(passkey))
        }

        #expect(storage.all().map(\.userName) == ["joe", "jane", "jane-work"])
        #expect(Set(storage.passkeys(for: "github.com")) == [github, github2])
        #expect(storage.passkeys(for: "github.com", allowed: [github2.credentialID]) == [github2])
        #expect(storage.passkey(credentialID: example.credentialID) == example)
        #expect(storage.passkey(id: github.id) == github)

        #expect(storage.delete(github))
        #expect(storage.passkeys(for: "github.com") == [github2])
        // Passwords are left alone.
        #expect(keychain.items.count == 3)
    }
}
