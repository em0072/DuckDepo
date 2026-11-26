//
//  Keychain Controller.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 24/06/2022.
//

import Foundation
import KeychainSwift
import os

/// Where password values are stored. Abstracted so tests can use an in-memory store.
protocol KeychainStoring: AnyObject {
    func string(forKey key: String) -> String?
    @discardableResult func set(_ value: String, forKey key: String) -> Bool
    @discardableResult func delete(_ key: String) -> Bool
    @discardableResult func clear() -> Bool
    /// The keys of every item DuckDepo has in the keychain.
    func allKeys() -> [String]
}

/// Password values live in the shared, iCloud-synchronized keychain group so the AutoFill
/// extension and the user's other devices can read them.
final class Keychain: KeychainStoring {

    static let shared = Keychain()

    private let keychain: KeychainSwift
    private let logger = Logger(subsystem: "DuckDepo", category: "Keychain")

    init(accessGroup: String = "65952893XA.group.evgenymitko.duckdepo") {
        keychain = KeychainSwift()
        keychain.synchronizable = true
        keychain.accessGroup = accessGroup
    }

    func string(forKey key: String) -> String? {
        keychain.get(key)
    }

    @discardableResult
    func set(_ value: String, forKey key: String) -> Bool {
        let success = keychain.set(value, forKey: key)
        if !success {
            logger.error("Keychain write failed with status \(self.keychain.lastResultCode)")
        }
        return success
    }

    @discardableResult
    func delete(_ key: String) -> Bool {
        keychain.delete(key)
    }

    @discardableResult
    func clear() -> Bool {
        keychain.clear()
    }

    func allKeys() -> [String] {
        keychain.allKeys
    }
}
