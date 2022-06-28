//
//  AutoFillPasswordsListViewModel.swift
//  DuckDepoAutoFillExtension
//
//  Created by Evgeny Mitko on 28/06/2022.
//

import Foundation
import SwiftUI
import Combine

class AutoFillPasswordsListViewModel: ObservableObject {
    
    @Published var passwords = [Password]()
    @Published var recomendedPasswords = [Password]()
    @Published var selectedPassword: Password? {
        didSet {
            showPasswordView = selectedPassword != nil
        }
    }
    @Published var showPasswordView: Bool = false
    @Published var isAddingNewPassword: Bool = false

    let identifiers: [String]
    private let passwordStorage = PasswordsStorage()
    
    private var cancellable = Set<AnyCancellable>()
    
    init(identifiers: [String]) {
        self.identifiers = identifiers
        passwordStorage.passwords.sink { passwords in
            self.passwords = passwords
            self.recomendedPasswords = passwords.filter({ password in
                for identifier in identifiers {
                    return identifier.contains(password.website)
                }
                return false
            })
        }.store(in: &cancellable)
    }

    func addNewPasswordButtonPressed() {
        isAddingNewPassword = true
    }
    
    func showPassword(_ password: Password) {
        selectedPassword = password
    }

    
}
