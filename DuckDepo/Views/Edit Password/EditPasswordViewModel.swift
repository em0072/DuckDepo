//
//  EditPasswordViewModel.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/11/2021.
//

import Foundation
import SwiftUI

extension EditPasswordView {
    class ViewModel: ObservableObject {
        
        enum PasswordType {
            case new
            case existing(DDPassword)
        }
                        
        private let db: DataBase = DataBase.shared
        
        @Published var passwordName: String = ""
        @Published var passwordLogin: String = ""
        @Published var passwordValue: String = ""
        @Published var passwordWebsite: String = ""

//        var inputOption: InputOption = InputOption()
        
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
                return "New Password"
            case .existing(_):
                return "Edit Password"
            }
        }
        
        var saveButtonTitle: String {
            switch type {
            case .new:
                return "Add New Password"
            case .existing(_):
                return "Save Changes"
            }
        }

        func addNewPasswordButtonAction() {
            switch type {
            case .new:
                let password = Password(name: passwordName, login: passwordLogin, value: passwordValue, website: passwordWebsite)
                db.save(password)
            case .existing(let password):
                password.name = passwordName
                password.login = passwordLogin
                password.value = passwordValue
                password.website = passwordWebsite
                db.save()
            }
        }
        
        func delete() {
            if case .existing(let password) = type {
                db.delete(password)
            }
        }

        
        
    }
}
