//
//  PasswordViewModel.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/11/2021.
//

import Foundation

final class PasswordViewModel: ObservableObject {

    @Published var password: Password

    @Published var showShareAlert = false
    @Published var showShareSheetView = false
    @Published var isEditingPassword = false
    @Published var isPasswordVisible = false
    @Published var shouldDismissView = false

    var itemsToShare: [Any]?

    /// List items carry no password value; read it from the keychain only for this screen.
    init(password: Password, storage: PasswordsStorage = PasswordsStorage()) {
        var password = password
        password.value = storage.value(for: password.id)
        self.password = password
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
