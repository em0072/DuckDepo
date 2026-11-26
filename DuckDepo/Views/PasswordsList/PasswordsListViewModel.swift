//
//  PasswordsListViewModel.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 27/06/2022.
//

import Combine
import Foundation

@Observable
final class PasswordsListViewModel {

    var passwords: [Password] = []
    var isAddingNewPassword = false

    @ObservationIgnored private var cancellables = Set<AnyCancellable>()
    @ObservationIgnored private var dataStorage: PasswordsStorage?
    @ObservationIgnored private let makeStorage: () -> PasswordsStorage

    init(makeStorage: @escaping () -> PasswordsStorage = { PasswordsStorage() }) {
        self.makeStorage = makeStorage
    }

    /// Starts fetching passwords. Safe to call more than once.
    func start() {
        guard dataStorage == nil else { return }
        let storage = makeStorage()
        dataStorage = storage
        storage.startObserving()
        storage.passwords
            .sink { [weak self] passwords in
                self?.passwords = passwords
            }
            .store(in: &cancellables)
    }

    func password(with id: Password.ID?) -> Password? {
        guard let id else { return nil }
        return passwords.first { $0.id == id }
    }

    func addNewPasswordButtonPressed() {
        isAddingNewPassword = true
    }

    func copyLogin(of password: Password) {
        ClipboardController.shared.copy(string: password.login)
    }

    /// List items carry no value; this reads it from the keychain.
    func copyValue(of password: Password) {
        guard let value = dataStorage?.value(for: password.id), !value.isEmpty else { return }
        ClipboardController.shared.copy(string: value)
    }

    func delete(_ password: Password) {
        dataStorage?.delete(password)
    }
}
