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
    
}


extension PasswordViewModel: EditPasswordViewModelDelegate {
    
    func passwordUpdated(_ password: Password) {
        self.password = password
    }
    
}
