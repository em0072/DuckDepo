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

    init(id: UUID = UUID(), name: String = "", login: String = "", value: String = "", website: String = "") {
        self.id = id
        self.name = name
        self.login = login
        self.value = value
        self.website = website
    }

    var websiteURL: URL? {
        let trimmed = website.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return URL(string: trimmed.contains("://") ? trimmed : "https://\(trimmed)")
    }

    static var test: Password {
        Password(name: "Google", login: "alpaca@google.com", value: "", website: "https://google.com")
    }
}
