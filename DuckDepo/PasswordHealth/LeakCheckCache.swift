//
//  LeakCheckCache.swift
//  DuckDepo
//

import CryptoKit
import Foundation
import os

/// What the leak check found, so passwords aren't looked up again on every launch (each lookup downloads
/// a few dozen kilobytes).
///
/// - A leaked password stays leaked: that result is kept for as long as the password has that value, so it
///   never drops out of the report because a later lookup failed.
/// - "Not leaked" is looked up again after a week, since new leaks are added.
/// - A local file with complete data protection, left out of backups. It's keyed by an HMAC of each
///   password's hash under a random key kept in this device's keychain (not synced), so the file on its
///   own says nothing about the passwords.
final class LeakCheckCache: @unchecked Sendable {

    static let shared = LeakCheckCache(fileURL: defaultFileURL, keychain: Keychain(synchronizable: false))

    static let maximumAge: TimeInterval = 7 * 24 * 60 * 60
    private static let keyName = "passwordHealth.leakCheckKey"

    private struct Result: Codable {
        let isLeaked: Bool
        let checked: Date
    }

    private let fileURL: URL?
    private let keychain: KeychainStoring
    private let lock = NSLock()
    private var results: [String: Result]?
    private var key: SymmetricKey?
    private let logger = Logger(subsystem: "DuckDepo", category: "LeakCheck")

    /// `fileURL` nil keeps results in memory (tests).
    init(fileURL: URL?, keychain: KeychainStoring) {
        self.fileURL = fileURL
        self.keychain = keychain
    }

    /// Whether the password with this hash leaked: true once found leaked, false if found safe in the last
    /// week, nil if it needs looking up.
    func isLeaked(_ hash: String, now: Date = .now) -> Bool? {
        lock.withLock {
            guard let result = loadedResults()[fingerprint(of: hash)] else { return nil }
            return result.isLeaked || Self.isFresh(result, now: now) ? result.isLeaked : nil
        }
    }

    /// Records hashes just looked up, and which of them leaked. In memory until `save()`.
    func store(checked: Set<String>, leaked: Set<String>, now: Date = .now) {
        lock.withLock {
            var results = loadedResults()
            for hash in checked {
                results[fingerprint(of: hash)] = Result(isLeaked: leaked.contains(hash), checked: now)
            }
            self.results = results
        }
    }

    /// Forgets passwords that are gone (or have new values) and safe results too old to use, and writes the
    /// rest to the file.
    func save(keeping hashes: Set<String>, now: Date = .now) {
        lock.withLock {
            let current = Set(hashes.map(fingerprint(of:)))
            let results = loadedResults().filter { current.contains($0.key) && ($0.value.isLeaked || Self.isFresh($0.value, now: now)) }
            self.results = results
            write(results)
        }
    }

    /// When the check is turned off, or everything is deleted: the results, the file and the key.
    func removeAll() {
        lock.withLock {
            results = [:]
            key = nil
            keychain.delete(Self.keyName)
            if let fileURL {
                try? FileManager.default.removeItem(at: fileURL)
            }
        }
    }

    /// Checked within the last week, and not in the future (a clock that was set ahead).
    private static func isFresh(_ result: Result, now: Date) -> Bool {
        let age = now.timeIntervalSince(result.checked)
        return age >= 0 && age < maximumAge
    }

    // MARK: - Private (called with the lock held)

    private func loadedResults() -> [String: Result] {
        if let results {
            return results
        }
        let loaded = fileURL.flatMap { try? JSONDecoder().decode([String: Result].self, from: Data(contentsOf: $0)) } ?? [:]
        results = loaded
        return loaded
    }

    private func fingerprint(of hash: String) -> String {
        let code = HMAC<SHA256>.authenticationCode(for: Data(hash.utf8), using: fingerprintKey())
        return Data(code).base64EncodedString()
    }

    /// Made once and kept in the keychain. A lost key only means looking everything up again.
    private func fingerprintKey() -> SymmetricKey {
        if let key {
            return key
        }
        let key: SymmetricKey
        if let stored = keychain.string(forKey: Self.keyName).flatMap({ Data(base64Encoded: $0) }), stored.count == 32 {
            key = SymmetricKey(data: stored)
        } else {
            key = SymmetricKey(size: .bits256)
            let data = key.withUnsafeBytes { Data($0) }
            if !keychain.set(data.base64EncodedString(), forKey: Self.keyName) {
                logger.error("Keeping the leak check key failed; results last until the app quits")
            }
            // Results made with another key can't be read with this one.
            results = [:]
        }
        self.key = key
        return key
    }

    private func write(_ results: [String: Result]) {
        guard let fileURL else { return }
        do {
            var folder = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try? folder.setResourceValues(values)
            try JSONEncoder().encode(results).write(to: fileURL, options: [.atomic, .completeFileProtection])
        } catch {
            logger.error("Saving leak check results failed: \(String(describing: error), privacy: .public)")
        }
    }

    private static var defaultFileURL: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("PasswordHealth", isDirectory: true)
            .appendingPathComponent("leak-checks.json")
    }
}
