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

/// Cheap to create: SwiftUI may build and discard several instances; the one on screen loads in `load()`.
@Observable
final class EditPasswordViewModel {

    enum PasswordType {
        case new
        case existing(Password)
    }

    let type: PasswordType
    @ObservationIgnored weak var delegate: EditPasswordViewModelDelegate?

    var passwordName = ""
    var passwordLogin = ""
    var passwordValue = ""
    var passwordWebsite = ""
    /// The `otpauth://` link of the one-time codes, or empty.
    var oneTimeCodeURI = ""
    /// A setup key or QR code that isn't one.
    var oneTimeCodeError = false

    private(set) var shouldCloseView = false
    var saveFailed = false

    @ObservationIgnored private let storage: PasswordsStorage
    private var original: Password
    @ObservationIgnored private var isLoaded = false

    init(type: PasswordType, delegate: EditPasswordViewModelDelegate? = nil, storage: PasswordsStorage = PasswordsStorage()) {
        self.type = type
        self.delegate = delegate
        self.storage = storage
        switch type {
        case .new:
            original = Password()
        case .existing(let password):
            original = password
        }
        passwordName = original.name
        passwordLogin = original.login
        passwordValue = original.value
        passwordWebsite = original.website
    }

    /// Reads the value from the keychain once: the caller's copy may be stale or a list item without a value.
    func load() {
        guard !isLoaded else { return }
        isLoaded = true
        guard case .existing(let password) = type else { return }
        let value = storage.value(for: password.id)
        original.value = value
        passwordValue = value
        let oneTimeCode = storage.oneTimeCode(for: password.id)
        original.oneTimeCode = oneTimeCode
        oneTimeCodeURI = oneTimeCode
    }

    // MARK: - One-time codes

    var oneTimeCode: OneTimeCode? {
        OneTimeCode(text: oneTimeCodeURI)
    }

    /// From a setup key or the text of a setup QR code. Fills in an empty name and login from it.
    func setUpOneTimeCode(from text: String) {
        guard let code = OneTimeCode(text: text) else {
            oneTimeCodeError = true
            return
        }
        oneTimeCodeURI = code.uri
        if passwordName.trimmingCharacters(in: .whitespaces).isEmpty, let issuer = code.issuer {
            passwordName = issuer
        }
        if passwordLogin.trimmingCharacters(in: .whitespaces).isEmpty, let account = code.account {
            passwordLogin = account
        }
    }

    func removeOneTimeCode() {
        oneTimeCodeURI = ""
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
        password.oneTimeCode = oneTimeCodeURI
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
