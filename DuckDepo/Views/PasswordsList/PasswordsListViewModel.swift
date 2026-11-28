//
//  PasswordsListViewModel.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 27/06/2022.
//

import Combine
import Foundation
import SwiftUI

@Observable
final class PasswordsListViewModel {

    var passwords: [Password] = []
    /// Read from the keychain, which only tells this process: reload when coming back to the app too.
    private(set) var passkeys: [PasskeySummary] = []
    var isAddingNewPassword = false
    /// Whose passwords the list shows.
    var filter: PersonFilter = .everyone

    @ObservationIgnored let people: PeopleDirectory

    @ObservationIgnored private var cancellables = Set<AnyCancellable>()
    @ObservationIgnored private var dataStorage: PasswordsStorage?
    @ObservationIgnored private let makeStorage: () -> PasswordsStorage
    @ObservationIgnored private let passkeyStorage: PasskeyStorage

    init(makeStorage: @escaping () -> PasswordsStorage = { PasswordsStorage() },
         passkeyStorage: PasskeyStorage = PasskeyStorage(),
         people: PeopleDirectory = .shared) {
        self.makeStorage = makeStorage
        self.passkeyStorage = passkeyStorage
        self.people = people
    }

    /// Starts fetching passwords. Safe to call more than once.
    func start() {
        people.start()
        guard dataStorage == nil else { return }
        let storage = makeStorage()
        dataStorage = storage
        storage.startObserving()
        reloadPasskeys(animated: false)
        storage.passwords
            .sink { [weak self] passwords in
                self?.passwords = passwords
                self?.showEveryoneWhenEmpty()
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

    /// The person the list shows, while they exist (they may be deleted, here or on another device).
    var selectedPersonID: Person.ID? {
        filter.personID.flatMap { people.person(with: $0)?.id }
    }

    var shownPasswords: [Password] {
        guard let selectedPersonID else { return passwords }
        return passwords.filter { $0.personID == selectedPersonID }
    }

    /// Passkeys belong to no one, so they show with everyone's passwords only.
    var shownPasskeys: [PasskeySummary] {
        selectedPersonID == nil ? passkeys : []
    }

    /// The person a row shows: only while the list shows everyone's passwords.
    func person(for password: Password) -> Person? {
        guard selectedPersonID == nil else { return nil }
        return people.person(with: password.personID)
    }

    func setPerson(_ personID: Person.ID?, for password: Password) {
        dataStorage?.setPerson(personID, forPasswordWith: password.id)
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

    /// Animated, except the first time (the list appearing).
    func reloadPasskeys(animated: Bool = true) {
        let passkeys = passkeyStorage.all()
        guard passkeys != self.passkeys else { return }
        if animated {
            withAnimation {
                self.passkeys = passkeys
            }
        } else {
            self.passkeys = passkeys
        }
        showEveryoneWhenEmpty()
    }

    /// The empty list has no filter row: a filter left on would quietly give new passwords to that
    /// person, and hide the ones that aren't theirs once there are some.
    private func showEveryoneWhenEmpty() {
        if passwords.isEmpty && passkeys.isEmpty {
            filter = .everyone
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
