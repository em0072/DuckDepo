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
    /// Writes an item that belongs to `service`, so that group can be listed without reading anything else.
    /// `string(forKey:)` and `delete(_:)` find it like any other item.
    @discardableResult func set(_ value: String, forKey key: String, service: String) -> Bool
    /// The values of every item in `service`, by key.
    func strings(service: String) -> [String: String]
    /// The keys of the items in `service`, without reading their values.
    func keys(service: String) -> [String]
}

/// Password values live in the shared, iCloud-synchronized keychain group so the AutoFill
/// extension and the user's other devices can read them.
final class Keychain: KeychainStoring {

    static let shared = Keychain()

    private let keychain: KeychainSwift
    private let accessGroup: String
    private let logger = Logger(subsystem: "DuckDepo", category: "Keychain")

    init(accessGroup: String = "65952893XA.group.evgenymitko.duckdepo") {
        self.accessGroup = accessGroup
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

    // MARK: - Items of one service

    // KeychainSwift has no notion of a service, so these talk to the keychain directly, with the same
    // access group, sync and accessibility it uses.

    @discardableResult
    func set(_ value: String, forKey key: String, service: String) -> Bool {
        keychain.delete(key)
        var item = query(service: service)
        item[kSecAttrSynchronizable as String] = true
        item[kSecAttrAccount as String] = key
        item[kSecValueData as String] = Data(value.utf8)
        item[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlocked
        let status = SecItemAdd(item as CFDictionary, nil)
        if status != errSecSuccess {
            logger.error("Keychain write failed with status \(status)")
        }
        return status == errSecSuccess
    }

    func strings(service: String) -> [String: String] {
        var query = query(service: service)
        query[kSecReturnAttributes as String] = true
        query[kSecReturnData as String] = true
        var values: [String: String] = [:]
        for item in items(matching: query) {
            if let key = item[kSecAttrAccount as String] as? String,
               let data = item[kSecValueData as String] as? Data,
               let value = String(data: data, encoding: .utf8) {
                values[key] = value
            }
        }
        return values
    }

    func keys(service: String) -> [String] {
        var query = query(service: service)
        query[kSecReturnAttributes as String] = true
        return items(matching: query).compactMap { $0[kSecAttrAccount as String] as? String }
    }

    private func query(service: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccessGroup as String: accessGroup,
            kSecAttrService as String: service,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny
        ]
    }

    private func items(matching query: [String: Any]) -> [[String: Any]] {
        var query = query
        query[kSecMatchLimit as String] = kSecMatchLimitAll
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else {
            if status != errSecItemNotFound {
                logger.error("Keychain read failed with status \(status)")
            }
            return []
        }
        return result as? [[String: Any]] ?? []
    }
}
