//
//  AutoFillPasswordView.swift
//  DuckDepoAutoFillExtension
//
//  Created by Evgeny Mitko on 28/06/2022.
//

import Foundation

class AutoFillPasswordViewModel: ObservableObject {
    
    @Published var password: Password
    @Published var passwordValue: String = ""
    
    @Published var isEditingPassword = false
    @Published var isPasswordVisible = false {
        didSet {
            setPasswordValue()
        }
    }
    
    
    init(password: Password) {
        self.password = password
        setPasswordValue()
    }
    
    private func setPasswordValue() {
        if isPasswordVisible {
            passwordValue = password.value
        } else {
            passwordValue = String(password.value.map({ _ in "•" }))
        }
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


extension AutoFillPasswordViewModel: EditPasswordViewModelDelegate {
    
    func passwordUpdated(_ password: Password) {
        self.password = password
    }
    
}
