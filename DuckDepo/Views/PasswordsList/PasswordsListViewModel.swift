//
//  NewPasswordsListViewModel.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 27/06/2022.
//

import Foundation
import Combine

class PasswordsListViewModel: ObservableObject {

    @Published var passwords: [Password] = []
    
    @Published var isAddingNewPassword: Bool = false
    @Published var selectedDocument: Document?

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
