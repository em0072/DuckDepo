//
//  Passkey.swift
//  DuckDepo
//

import CryptoKit
import Foundation

/// A passkey DuckDepo made for a site: its private key and the account it's for.
struct Passkey: Codable, Identifiable, Hashable {
    /// The AutoFill record identifier.
    let id: UUID
    let credentialID: Data
    /// The site's relying party ID, usually its domain: "github.com".
    let relyingParty: String
    let userName: String
    /// The site's ID for the account, returned when signing in.
    let userHandle: Data
    /// A P-256 signing key, raw.
    let privateKey: Data
    let createdAt: Date

    /// A new passkey with a fresh key and a random 16-byte credential ID.
    static func make(relyingParty: String, userName: String, userHandle: Data, now: Date = .now) -> Passkey {
        var generator = SystemRandomNumberGenerator()
        let idBytes = (0..<16).map { _ in UInt8.random(in: .min ... .max, using: &generator) }
        return Passkey(id: UUID(), credentialID: Data(idBytes), relyingParty: relyingParty, userName: userName,
                       userHandle: userHandle, privateKey: P256.Signing.PrivateKey().rawRepresentation, createdAt: now)
    }

    var signingKey: P256.Signing.PrivateKey? {
        try? P256.Signing.PrivateKey(rawRepresentation: privateKey)
    }
}

/// Passkeys live in iCloud Keychain, one item each, next to passwords: they sync to the user's devices
/// the same way and are end-to-end encrypted. Nothing about them is in Core Data.
final class PasskeyStorage {

    static let keyPrefix = "passkey."

    private let keychain: KeychainStoring

    init(keychain: KeychainStoring = Keychain.shared) {
        self.keychain = keychain
    }

    /// How many passkeys there are, without reading them.
    func count() -> Int {
        keychain.allKeys().filter { $0.hasPrefix(Self.keyPrefix) }.count
    }

    /// Every passkey, by site and then account.
    func all() -> [Passkey] {
        let decoder = JSONDecoder()
        return keychain.allKeys()
            .filter { $0.hasPrefix(Self.keyPrefix) }
            .compactMap { keychain.string(forKey: $0)?.data(using: .utf8) }
            .compactMap { try? decoder.decode(Passkey.self, from: $0) }
            .sorted { ($0.relyingParty, $0.userName) < ($1.relyingParty, $1.userName) }
    }

    /// The site's passkeys, only those in `allowed` when the site names some.
    func passkeys(for relyingParty: String, allowed: [Data] = []) -> [Passkey] {
        all().filter { $0.relyingParty == relyingParty && (allowed.isEmpty || allowed.contains($0.credentialID)) }
    }

    func passkey(credentialID: Data) -> Passkey? {
        keychain.string(forKey: Self.key(for: credentialID))?.data(using: .utf8)
            .flatMap { try? JSONDecoder().decode(Passkey.self, from: $0) }
    }

    func passkey(id: UUID) -> Passkey? {
        all().first { $0.id == id }
    }

    @discardableResult
    func save(_ passkey: Passkey) -> Bool {
        guard let data = try? JSONEncoder().encode(passkey), let json = String(data: data, encoding: .utf8) else { return false }
        return keychain.set(json, forKey: Self.key(for: passkey.credentialID))
    }

    @discardableResult
    func delete(_ passkey: Passkey) -> Bool {
        keychain.delete(Self.key(for: passkey.credentialID))
    }

    static func key(for credentialID: Data) -> String {
        keyPrefix + credentialID.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
