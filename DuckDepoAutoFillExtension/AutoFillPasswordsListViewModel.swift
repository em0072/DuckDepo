//
//  AutoFillPasswordsListViewModel.swift
//  DuckDepoAutoFillExtension
//
//  Created by Evgeny Mitko on 28/06/2022.
//

import AuthenticationServices
import Combine
import Foundation

@Observable
final class AutoFillPasswordsListViewModel {

    var passwords: [Password] = []
    var recommendedPasswords: [Password] = []
    var selectedPassword: Password?
    var isAddingNewPassword = false
    var searchText = ""
    private(set) var isLocked: Bool

    let identifiers: [String]
    /// `false` until the app has been opened once after updating and moved its data where the extension can read it.
    let isStoreReady: Bool

    @ObservationIgnored private let lock: BiometricController
    @ObservationIgnored private var storage: PasswordsStorage?
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()

    init(identifiers: [String],
         isStoreReady: Bool = DefaultsController.shared.isSharedStoreReady,
         lock: BiometricController = .shared) {
        self.identifiers = identifiers
        self.isStoreReady = isStoreReady
        self.lock = lock
        // Respect the app's lock setting: nothing is listed until the user authenticates.
        isLocked = lock.isLockRequired

        guard isStoreReady else { return }
        let storage = PasswordsStorage()
        storage.startObserving()
        storage.passwords
            .sink { [weak self] passwords in
                guard let self else { return }
                self.passwords = passwords
                self.recommendedPasswords = Self.recommended(from: passwords, for: identifiers)
            }
            .store(in: &cancellables)
        self.storage = storage
    }

    var filteredPasswords: [Password] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return passwords }
        return passwords.filter {
            $0.name.localizedCaseInsensitiveContains(query)
                || $0.login.localizedCaseInsensitiveContains(query)
                || $0.website.localizedCaseInsensitiveContains(query)
        }
    }

    static func recommended(from passwords: [Password], for identifiers: [String]) -> [Password] {
        passwords.filter { password in
            identifiers.contains { DomainMatcher.matches(website: password.website, serviceIdentifier: $0) }
        }
    }

    func unlock() {
        guard isLocked else { return }
        lock.authenticate { [weak self] success in
            if success {
                self?.isLocked = false
            }
        }
    }

    func credential(for password: Password) -> ASPasswordCredential {
        ASPasswordCredential(user: password.login, password: storage?.value(for: password.id) ?? "")
    }

    func addNewPasswordButtonPressed() {
        isAddingNewPassword = true
    }

    func showPassword(_ password: Password) {
        selectedPassword = password
    }
}
