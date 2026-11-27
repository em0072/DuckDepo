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

    var summary: PasskeySummary {
        PasskeySummary(id: id, credentialID: credentialID, relyingParty: relyingParty, userName: userName,
                       userHandle: userHandle, createdAt: createdAt)
    }
}

/// A passkey without its private key: what lists and AutoFill suggestions show. Decoded from the same
/// JSON as `Passkey`, so the key is never kept around just to display one.
struct PasskeySummary: Codable, Identifiable, Hashable {
    let id: UUID
    let credentialID: Data
    let relyingParty: String
    let userName: String
    let userHandle: Data
    let createdAt: Date
}

/// Passkeys live in iCloud Keychain, one item each, next to passwords: they sync to the user's devices
/// the same way and are end-to-end encrypted. Nothing about them is in Core Data.
///
/// They have their own keychain service, so listing them doesn't read passwords or code secrets.
final class PasskeyStorage {

    static let keyPrefix = "passkey."
    static let service = "DuckDepo.passkey"
    /// Posted in this process after passkeys are saved or deleted, with their keychain as the object.
    /// The keychain tells nobody else, so screens also look again when the app comes back
    /// (AutoFill runs in another process).
    static let didChange = Notification.Name("PasskeyStorage.didChange")

    private let keychain: KeychainStoring

    init(keychain: KeychainStoring = Keychain.shared) {
        self.keychain = keychain
    }

    /// Changes made in this process to the passkeys in this storage's keychain.
    var changes: NotificationCenter.Publisher {
        NotificationCenter.default.publisher(for: Self.didChange, object: keychain)
    }

    /// How many passkeys there are, without reading them.
    func count() -> Int {
        keychain.keys(service: Self.service).count
    }

    /// Every passkey, by site and then account.
    func all() -> [PasskeySummary] {
        let decoder = JSONDecoder()
        return keychain.strings(service: Self.service).values
            .compactMap { try? decoder.decode(PasskeySummary.self, from: Data($0.utf8)) }
            .sorted { ($0.relyingParty, $0.userName, $0.createdAt) < ($1.relyingParty, $1.userName, $1.createdAt) }
    }

    /// The site's passkeys, only those in `allowed` when the site names some.
    func passkeys(for relyingParty: String, allowed: [Data] = []) -> [PasskeySummary] {
        all().filter { $0.relyingParty == relyingParty && (allowed.isEmpty || allowed.contains($0.credentialID)) }
    }

    /// The whole passkey, with its key, to sign with.
    func passkey(credentialID: Data) -> Passkey? {
        keychain.string(forKey: Self.key(for: credentialID))
            .flatMap { try? JSONDecoder().decode(Passkey.self, from: Data($0.utf8)) }
    }

    /// Every passkey with its key, for an export.
    func allWithKeys() -> [Passkey] {
        let decoder = JSONDecoder()
        return keychain.strings(service: Self.service).values
            .compactMap { try? decoder.decode(Passkey.self, from: Data($0.utf8)) }
            .sorted { ($0.relyingParty, $0.userName, $0.createdAt) < ($1.relyingParty, $1.userName, $1.createdAt) }
    }

    @discardableResult
    func save(_ passkey: Passkey) -> Bool {
        guard write(passkey) else { return false }
        NotificationCenter.default.post(name: Self.didChange, object: keychain)
        return true
    }

    /// Adds passkeys an import brought, telling screens once. One whose credential ID is already here is
    /// left as it is. Returns how many were added and how many couldn't be written.
    func add(_ passkeys: [Passkey]) -> (added: Int, failed: Int) {
        var added = 0
        var failed = 0
        for passkey in passkeys where keychain.string(forKey: Self.key(for: passkey.credentialID)) == nil {
            if write(passkey) {
                added += 1
            } else {
                failed += 1
            }
        }
        if added > 0 {
            NotificationCenter.default.post(name: Self.didChange, object: keychain)
        }
        return (added, failed)
    }

    private func write(_ passkey: Passkey) -> Bool {
        guard let data = try? JSONEncoder().encode(passkey), let json = String(data: data, encoding: .utf8) else { return false }
        return keychain.set(json, forKey: Self.key(for: passkey.credentialID), service: Self.service)
    }

    /// Saves a site's new passkey and deletes the ones it made before for the same account (same site and
    /// user handle), as WebAuthn asks: the site has replaced them. Returns what was deleted, or nil if the
    /// new passkey couldn't be saved, in which case nothing is deleted.
    func saveReplacingEarlier(_ passkey: Passkey) -> [PasskeySummary]? {
        let earlier = passkeys(for: passkey.relyingParty)
            .filter { $0.userHandle == passkey.userHandle && $0.credentialID != passkey.credentialID }
        guard save(passkey) else { return nil }
        for summary in earlier {
            delete(summary)
        }
        return earlier
    }

    @discardableResult
    func delete(_ passkey: PasskeySummary) -> Bool {
        let deleted = keychain.delete(Self.key(for: passkey.credentialID))
        NotificationCenter.default.post(name: Self.didChange, object: keychain)
        return deleted
    }

    static func key(for credentialID: Data) -> String {
        keyPrefix + credentialID.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
