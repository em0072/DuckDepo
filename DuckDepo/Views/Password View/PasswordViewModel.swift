//
//  PasswordViewModel.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/11/2021.
//

import Foundation

class PasswordViewModel: ObservableObject {
    
    @Published var password: Password
    
    @Published var showShareAlert = false
    @Published var showShareSheetView = false
    @Published var isEditingPassword = false
    @Published var isPasswordVisible = false
    @Published var shouldDismissView = false
    
    var itemsToShare: [Any]?
    
    init(password: Password) {
        self.password = password
    }
    
    var shouldShowCredentialsSection: Bool {
        return isLoginExist || isPasswordExist
    }
    
    var isNameExist: Bool {
        return !password.name.isEmpty
    }

    var isLoginExist: Bool {
        return !password.login.isEmpty
    }

    var isPasswordExist: Bool {
        return !password.value.isEmpty
    }
    
    var isWebsiteExist: Bool {
        return !password.website.isEmpty
    }
    
    func sharePassword() {
        var shareString: String = ""
        if isNameExist {
            shareString.append("pv_share_details_title".localized())
            shareString.append(password.name)
            shareString.append("\n\n")
        }
        if isLoginExist {
            shareString.append("Login: ")
            shareString.append(password.login)
            shareString.append("\n\n")
        }
        if isPasswordExist {
            shareString.append("Password: ")
            shareString.append(password.value)
            shareString.append("\n\n")
        }
        if isWebsiteExist {
            shareString.append("Website: ")
            shareString.append(password.website)
            shareString.append("\n\n")
        }

        shareString.append("pv_share_caption".localized())
        shareString.append("\n")
        shareString.append("https://DuckDepo.com")
        share(items: [shareString])
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
