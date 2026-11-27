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
    /// Read from the keychain, which only tells this process: reload when coming back to the app too.
    private(set) var passkeys: [PasskeySummary] = []
    var isAddingNewPassword = false

    @ObservationIgnored private var cancellables = Set<AnyCancellable>()
    @ObservationIgnored private var dataStorage: PasswordsStorage?
    @ObservationIgnored private let makeStorage: () -> PasswordsStorage
    @ObservationIgnored private let passkeyStorage: PasskeyStorage

    init(makeStorage: @escaping () -> PasswordsStorage = { PasswordsStorage() },
         passkeyStorage: PasskeyStorage = PasskeyStorage()) {
        self.makeStorage = makeStorage
        self.passkeyStorage = passkeyStorage
    }

    /// Starts fetching passwords. Safe to call more than once.
    func start() {
        guard dataStorage == nil else { return }
        let storage = makeStorage()
        dataStorage = storage
        storage.startObserving()
        reloadPasskeys()
        storage.passwords
            .sink { [weak self] passwords in
                self?.passwords = passwords
            }
            .store(in: &cancellables)
        // A passkey deleted here, or all of them by Delete All Data in Settings.
        passkeyStorage.changes
            .sink { [weak self] _ in
                self?.reloadPasskeys()
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

    // MARK: - Passkeys

    func reloadPasskeys() {
        let passkeys = passkeyStorage.all()
        if passkeys != self.passkeys {
            self.passkeys = passkeys
        }
    }

    func passkey(with id: PasskeySummary.ID?) -> PasskeySummary? {
        guard let id else { return nil }
        return passkeys.first { $0.id == id }
    }

    /// The list reloads through `PasskeyStorage.didChange`.
    func delete(_ passkey: PasskeySummary) {
        passkeyStorage.delete(passkey)
        CredentialIdentityStoreController.shared.remove([passkey])
    }
}
