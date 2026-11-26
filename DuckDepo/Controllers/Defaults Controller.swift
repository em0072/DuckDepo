//
//  Defaults Controller.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 12/11/2021.
//

import CoreData
import Foundation

/// Settings shared by the app and the AutoFill extension (stored in the App Group suite).
final class DefaultsController {

    private enum Keys {
        static let isBiometryEnabled = "biometryEnabled"
        static let biometricDelay = "biometricDelay"
        static let isSharedStoreReady = "sharedStoreReady"
        static let didMigrateStandardDefaults = "didMigrateStandardDefaults"
        static func historyToken(_ author: String) -> String { "historyToken.\(author)" }

        /// Keys from older versions that are no longer used.
        static let obsolete = ["isUnlocked", "lastAuthenticate", "manualMigrationV1toV2"]
    }

    static let shared: DefaultsController = {
        #if AUTOFILL_EXTENSION
        // Only the app owns the old settings; the extension must not mark them as migrated.
        return DefaultsController(defaults: AppGroup.userDefaults, legacyDefaults: nil)
        #else
        return DefaultsController(defaults: AppGroup.userDefaults, legacyDefaults: .standard)
        #endif
    }()

    private let defaults: UserDefaults

    init(defaults: UserDefaults, legacyDefaults: UserDefaults?) {
        self.defaults = defaults
        if let legacyDefaults, legacyDefaults !== defaults {
            migrate(from: legacyDefaults)
        }
    }

    // MARK: - App lock

    var isBiometryEnabled: Bool {
        get { defaults.bool(forKey: Keys.isBiometryEnabled) }
        set { defaults.set(newValue, forKey: Keys.isBiometryEnabled) }
    }

    var biometricDelay: Int {
        get { defaults.integer(forKey: Keys.biometricDelay) }
        set { defaults.set(newValue, forKey: Keys.biometricDelay) }
    }

    // MARK: - Store

    /// Set by the app once the store is in the App Group container. Until then the extension must not open it.
    var isSharedStoreReady: Bool {
        get { defaults.bool(forKey: Keys.isSharedStoreReady) }
        set { defaults.set(newValue, forKey: Keys.isSharedStoreReady) }
    }

    func historyToken(for author: String) -> NSPersistentHistoryToken? {
        guard let data = defaults.data(forKey: Keys.historyToken(author)) else { return nil }
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSPersistentHistoryToken.self, from: data)
    }

    func setHistoryToken(_ token: NSPersistentHistoryToken, for author: String) {
        let data = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
        defaults.set(data, forKey: Keys.historyToken(author))
    }

    // MARK: - Migration

    /// Settings used to live in the app's standard defaults, which the extension can't read.
    private func migrate(from legacy: UserDefaults) {
        guard !defaults.bool(forKey: Keys.didMigrateStandardDefaults) else { return }
        for key in [Keys.isBiometryEnabled, Keys.biometricDelay] {
            if let value = legacy.object(forKey: key), defaults.object(forKey: key) == nil {
                defaults.set(value, forKey: key)
            }
        }
        Keys.obsolete.forEach(legacy.removeObject(forKey:))
        defaults.set(true, forKey: Keys.didMigrateStandardDefaults)
    }
}
