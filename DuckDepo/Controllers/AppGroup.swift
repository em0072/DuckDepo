//
//  AppGroup.swift
//  DuckDepo
//

import Foundation

/// The App Group shared by the app and the AutoFill extension.
enum AppGroup {
    static let identifier = "group.evgenymitko.duckdepo"

    /// `nil` when the build isn't signed with the App Group entitlement.
    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }

    static var userDefaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }
}
