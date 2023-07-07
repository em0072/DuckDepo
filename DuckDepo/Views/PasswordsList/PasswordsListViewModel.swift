//
//  NewPasswordsListViewModel.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 27/06/2022.
//

import Foundation
import Combine

class PasswordsListViewModel: ObservableObject {
    
    private let testPassword = [Password(name: "Google", login: "alpaca@gmail.com", value: "", website: "https://google.com"),
                        Password(name: "Instagram", login: "alpaca@gmail.com", value: "", website: "https://instagram.com"),
                        Password(name: "Twitter", login: "alpaca@gmail.com", value: "", website: "https://twitter.com")]

    @Published var passwords: [Password] = []
    
    @Published var isAddingNewPassword: Bool = false
    @Published var selectedPassword: Password?

    private var cancellable = Set<AnyCancellable>()
    private var dataStorage = PasswordsStorage()

    
    init() {
        dataStorage.passwords.sink { passwords in
            self.passwords = passwords
        }.store(in: &cancellable)
    }
    
    func addNewPasswordButtonPressed() {
        isAddingNewPassword = true
    }

}
