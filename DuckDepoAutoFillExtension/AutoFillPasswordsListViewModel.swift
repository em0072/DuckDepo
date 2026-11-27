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

    /// What the page that asked wants filled in.
    enum Mode {
        case passwords
        /// Only entries with one-time codes are listed.
        case oneTimeCodes
    }

    let mode: Mode
    var passwords: [Password] = []
    /// The one-time code settings of each listed entry, in `oneTimeCodes` mode.
    private(set) var oneTimeCodes: [Password.ID: OneTimeCode] = [:]
    var recommendedPasswords: [Password] = []
    /// When the site asked for a passkey: DuckDepo's passkeys for it, listed above the passwords.
    let passkeys: [PasskeySummary]
    var selectedPassword: Password?
    var isAddingNewPassword = false
    var searchText = ""
    private(set) var isLocked: Bool
    /// The user unlocked the list with Face ID or the passcode, so a passkey picked now needs no second check.
    @ObservationIgnored private(set) var wasUnlockedByUser = false

    let identifiers: [String]
    /// `false` until the app has been opened once after updating and moved its data where the extension can read it.
    let isStoreReady: Bool

    @ObservationIgnored private let lock: BiometricController
    @ObservationIgnored private var storage: PasswordsStorage?
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()

    init(identifiers: [String],
         mode: Mode = .passwords,
         passkeys: [PasskeySummary] = [],
         isStoreReady: Bool = DefaultsController.shared.isSharedStoreReady,
         lock: BiometricController = .shared) {
        self.identifiers = identifiers
        self.mode = mode
        self.passkeys = passkeys
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
                var passwords = passwords
                if mode == .oneTimeCodes {
                    let codes = Dictionary(uniqueKeysWithValues: passwords.compactMap { password in
                        OneTimeCode(text: storage.oneTimeCode(for: password.id)).map { (password.id, $0) }
                    })
                    oneTimeCodes = codes
                    passwords = passwords.filter { codes[$0.id] != nil }
                }
                self.passwords = passwords
                self.recommendedPasswords = Self.recommended(from: passwords, for: identifiers)
            }
            .store(in: &cancellables)
        self.storage = storage
    }

    var filteredPasswords: [Password] {
        passwords.filter { $0.matches(searchText) }
    }

    var filteredPasskeys: [PasskeySummary] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return passkeys }
        return passkeys.filter { $0.userName.localizedStandardContains(query) || $0.relyingParty.localizedStandardContains(query) }
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
                self?.wasUnlockedByUser = true
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
