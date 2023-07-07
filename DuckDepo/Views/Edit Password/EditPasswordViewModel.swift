//
//  EditPasswordViewModel.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/11/2021.
//

import Foundation
import SwiftUI

protocol EditPasswordViewModelDelegate {
    func passwordUpdated(_ password: Password)
    func passwordDeleted()
}

    class EditPasswordViewModel: ObservableObject {
        
        enum PasswordType {
            case new
            case existing(Password)
        }
                        
        private let storage = PasswordsStorage()
        
        @Published var passwordName: String = ""
        @Published var passwordLogin: String = ""
        @Published var passwordValue: String = ""
        @Published var passwordWebsite: String = ""
        
        @Published var shouldCloseView: Bool = false

        var delegate: EditPasswordViewModelDelegate?
        
        var type: PasswordType = .new {
            didSet {
                if case .existing(let password) = type {
                    passwordName = password.name
                    passwordLogin = password.login
                    passwordValue = password.value
                    passwordWebsite = password.website
                }
            }
        }
        
        var viewTitle: String {
            switch type {
            case .new:
                return "epv_new_password_title".localized()
            case .existing(_):
                return "epv_edit_password_title".localized()
            }
        }
        
        var saveButtonTitle: String {
            switch type {
            case .new:
                return "epv_add_new_password_button".localized()
            case .existing(_):
                return "epv_edit_password_button".localized()
            }
        }

        func addNewPasswordButtonAction() {
            switch type {
            case .new:
                let password = Password(name: passwordName, login: passwordLogin, value: passwordValue, website: passwordWebsite)
                storage.saveNewPassword(password)
            case .existing(var password):
                password.name = passwordName
                password.login = passwordLogin
                password.value = passwordValue
                password.website = passwordWebsite
                storage.update(password)
                delegate?.passwordUpdated(password)
            }
            shouldCloseView = true
        }
                
        
        func delete() {
            if case .existing(let password) = type {
                storage.delete(password)
            }
            delegate?.passwordDeleted()
            shouldCloseView = true
        }

        
        
    }
