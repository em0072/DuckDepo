//
//  CredentialIdentityStoreController.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 27/06/2022.
//

import AuthenticationServices
import CoreData
import os

/// Keeps the system's AutoFill suggestions (QuickType bar) in sync with the saved passwords.
///
/// The whole list is replaced each time instead of being updated incrementally, so passwords that
/// arrive from other devices through iCloud are included too.
final class CredentialIdentityStoreController {

    static let shared = CredentialIdentityStoreController()

    private let logger = Logger(subsystem: "DuckDepo", category: "AutoFill")

    func refresh(context: NSManagedObjectContext = PersistenceController.shared.context,
                 keychain: KeychainStoring = Keychain.shared) {
        var identities: [any ASCredentialIdentity] = []
        context.performAndWait {
            let passwords = (try? context.fetch(DDPassword.fetchRequest())) ?? []
            identities = passwords.compactMap(Self.identity(for:))
            // One-time codes are offered on their own, when a site asks for a code.
            identities += passwords.compactMap { Self.oneTimeCodeIdentity(for: $0, keychain: keychain) }
        }
        let store = ASCredentialIdentityStore.shared
        store.getState { [logger] state in
            guard state.isEnabled else { return }
            store.replaceCredentialIdentities(identities) { _, error in
                if let error {
                    logger.error("Replacing AutoFill identities failed: \(String(describing: error), privacy: .public)")
                }
            }
        }
    }

    func removeAll() {
        ASCredentialIdentityStore.shared.removeAllCredentialIdentities { [logger] _, error in
            if let error {
                logger.error("Removing AutoFill identities failed: \(String(describing: error), privacy: .public)")
            }
        }
    }

    static func oneTimeCodeIdentity(for password: DDPassword, keychain: KeychainStoring) -> ASOneTimeCodeCredentialIdentity? {
        guard let id = password.id, let host = DomainMatcher.host(from: password.website),
              keychain.string(forKey: PasswordsStorage.oneTimeCodeKey(for: id)) != nil else { return nil }
        let service = ASCredentialServiceIdentifier(identifier: host, type: .domain)
        let label = !password.login.isEmpty ? password.login : (password.name.isEmpty ? host : password.name)
        return ASOneTimeCodeCredentialIdentity(serviceIdentifier: service, label: label, recordIdentifier: id.uuidString)
    }

    static func identity(for password: DDPassword) -> ASPasswordCredentialIdentity? {
        guard let id = password.id, let host = DomainMatcher.host(from: password.website) else { return nil }
        let service = ASCredentialServiceIdentifier(identifier: host, type: .domain)
        return ASPasswordCredentialIdentity(serviceIdentifier: service, user: password.login, recordIdentifier: id.uuidString)
    }
}
