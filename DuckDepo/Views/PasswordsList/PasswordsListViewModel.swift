//
//  NewPasswordsListViewModel.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 27/06/2022.
//

import Combine
import Foundation

final class PasswordsListViewModel: ObservableObject {

    @Published var passwords: [Password] = []
    @Published var isAddingNewPassword = false

    private var cancellables = Set<AnyCancellable>()
    private let dataStorage: PasswordsStorage

    init(dataStorage: PasswordsStorage = PasswordsStorage()) {
        self.dataStorage = dataStorage
        dataStorage.startObserving()
        dataStorage.passwords
            .sink { [weak self] passwords in
                self?.passwords = passwords
            }
            .store(in: &cancellables)
    }

    func addNewPasswordButtonPressed() {
        isAddingNewPassword = true
    }
}
