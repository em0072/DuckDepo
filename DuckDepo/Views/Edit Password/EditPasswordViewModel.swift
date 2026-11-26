//
//  EditPasswordViewModel.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/11/2021.
//

import Foundation

protocol EditPasswordViewModelDelegate: AnyObject {
    func passwordUpdated(_ password: Password)
    func passwordDeleted()
}

final class EditPasswordViewModel: ObservableObject {

    enum PasswordType {
        case new
        case existing(Password)
    }

    let type: PasswordType
    weak var delegate: EditPasswordViewModelDelegate?

    @Published var passwordName = ""
    @Published var passwordLogin = ""
    @Published var passwordValue = ""
    @Published var passwordWebsite = ""

    @Published private(set) var shouldCloseView = false
    @Published var saveFailed = false

    private let storage: PasswordsStorage
    private var original: Password

    init(type: PasswordType, delegate: EditPasswordViewModelDelegate? = nil, storage: PasswordsStorage = PasswordsStorage()) {
        self.type = type
        self.delegate = delegate
        self.storage = storage
        switch type {
        case .new:
            original = Password()
        case .existing(let password):
            // Read the value from the keychain: the caller's copy may be stale or a list item without a value.
            original = password
            original.value = storage.value(for: password.id)
        }
        passwordName = original.name
        passwordLogin = original.login
        passwordValue = original.value
        passwordWebsite = original.website
    }

    var isNew: Bool {
        if case .new = type { return true }
        return false
    }

    private var edited: Password {
        var password = original
        password.name = passwordName.trimmingCharacters(in: .whitespacesAndNewlines)
        password.login = passwordLogin.trimmingCharacters(in: .whitespacesAndNewlines)
        password.value = passwordValue
        password.website = passwordWebsite.trimmingCharacters(in: .whitespacesAndNewlines)
        return password
    }

    var hasChanges: Bool {
        edited != original
    }

    var canSave: Bool {
        !edited.name.isEmpty
    }

    var viewTitle: String {
        isNew ? "epv_new_password_title".localized() : "epv_edit_password_title".localized()
    }

    var saveButtonTitle: String {
        isNew ? "epv_add_new_password_button".localized() : "epv_edit_password_button".localized()
    }

    func save() {
        guard canSave else { return }
        let password = edited
        guard storage.save(password) else {
            saveFailed = true
            return
        }
        delegate?.passwordUpdated(password)
        shouldCloseView = true
    }

    func delete() {
        if case .existing(let password) = type {
            storage.delete(password)
        }
        delegate?.passwordDeleted()
        shouldCloseView = true
    }
}
