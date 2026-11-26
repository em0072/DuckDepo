//
//  NewPasswordsListViewModel.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 27/06/2022.
//

import Combine
import Foundation

/// Cheap to create: SwiftUI may build and discard several instances; only the one on screen starts fetching.
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

    func addNewPasswordButtonPressed() {
        isAddingNewPassword = true
    }
}
