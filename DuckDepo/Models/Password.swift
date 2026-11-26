//
//  Password.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/11/2021.
//

import Foundation

struct Password: Identifiable, Hashable {
    var id: UUID
    var name: String
    var login: String
    /// Empty in list items; read it with `PasswordsStorage.value(for:)` when needed.
    var value: String
    var website: String
    /// The `otpauth://` link of the account's one-time codes, or empty. Kept in the keychain like `value`
    /// and empty in list items too; read it with `PasswordsStorage.oneTimeCode(for:)`.
    var oneTimeCode: String

    init(id: UUID = UUID(), name: String = "", login: String = "", value: String = "", website: String = "",
         oneTimeCode: String = "") {
        self.id = id
        self.name = name
        self.login = login
        self.value = value
        self.website = website
        self.oneTimeCode = oneTimeCode
    }

    var websiteURL: URL? {
        let trimmed = website.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return URL(string: trimmed.contains("://") ? trimmed : "https://\(trimmed)")
    }

    /// Search by name, login or website, ignoring case and diacritics.
    func matches(_ query: String) -> Bool {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }
        return [name, login, website].contains { $0.localizedStandardContains(query) }
    }

    static var test: Password {
        Password(name: "Google", login: "alpaca@google.com", value: "", website: "https://google.com")
    }
}
