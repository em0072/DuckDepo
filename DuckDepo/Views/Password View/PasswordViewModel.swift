//
//  PasswordViewModel.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/11/2021.
//

import Foundation

/// Cheap to create: SwiftUI may build and discard several instances; the one on screen loads in `load()`.
@Observable
final class PasswordViewModel {

    var password: Password

    var showShareAlert = false
    var showShareSheetView = false
    var isEditingPassword = false
    var shouldDismissView = false

    @ObservationIgnored var itemsToShare: [Any]?
    @ObservationIgnored private let storage: PasswordsStorage
    @ObservationIgnored private var isLoaded = false

    init(password: Password, storage: PasswordsStorage = PasswordsStorage()) {
        self.password = password
        self.storage = storage
    }

    /// List items carry no password value; read it from the keychain once, only for this screen.
    func load() {
        guard !isLoaded else { return }
        isLoaded = true
        password.value = storage.value(for: password.id)
    }

    /// The list's copy changed (edited here, or synced from another device): show its name, login and
    /// website, and read the value again in case it changed too.
    func listItemChanged(_ listItem: Password) {
        guard listItem.id == password.id else { return }
        password.name = listItem.name
        password.login = listItem.login
        password.website = listItem.website
        password.value = storage.value(for: password.id)
    }

    var shouldShowCredentialsSection: Bool {
        isLoginExist || isPasswordExist
    }

    var isNameExist: Bool {
        !password.name.isEmpty
    }

    var isLoginExist: Bool {
        !password.login.isEmpty
    }

    var isPasswordExist: Bool {
        !password.value.isEmpty
    }

    var isWebsiteExist: Bool {
        !password.website.isEmpty
    }

    func sharePassword() {
        var lines: [String] = []
        if isNameExist {
            lines.append("pv_share_details_title".localized() + password.name)
        }
        if isLoginExist {
            lines.append("pv_share_login".localized() + password.login)
        }
        if isPasswordExist {
            lines.append("pv_share_password".localized() + password.value)
        }
        if isWebsiteExist {
            lines.append("pv_share_website".localized() + password.website)
        }
        lines.append("pv_share_caption".localized() + "\nhttps://DuckDepo.com")
        share(items: [lines.joined(separator: "\n\n")])
    }

    private func share(items: [Any]) {
        itemsToShare = items
        showShareSheetView = true
    }
}

extension PasswordViewModel: EditPasswordViewModelDelegate {

    func passwordUpdated(_ password: Password) {
        self.password = password
    }

    func passwordDeleted() {
        shouldDismissView = true
    }
}
