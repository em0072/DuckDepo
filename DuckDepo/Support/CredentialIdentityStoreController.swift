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
        // Passkeys aren't in Core Data, but replacing the identities would drop them if they weren't here.
        identities += PasskeyStorage(keychain: keychain).all().map(Self.identity(for:))
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

    static func identity(for passkey: PasskeySummary) -> ASPasskeyCredentialIdentity {
        ASPasskeyCredentialIdentity(relyingPartyIdentifier: passkey.relyingParty, userName: passkey.userName,
                                    credentialID: passkey.credentialID, userHandle: passkey.userHandle,
                                    recordIdentifier: passkey.id.uuidString)
    }

    /// Adds one passkey without waiting for the next full refresh, which only the app does.
    func add(_ passkey: PasskeySummary) {
        let identity = Self.identity(for: passkey)
        ASCredentialIdentityStore.shared.getState { [logger] state in
            guard state.isEnabled else { return }
            ASCredentialIdentityStore.shared.saveCredentialIdentities([identity]) { _, error in
                if let error {
                    logger.error("Saving a passkey identity failed: \(String(describing: error), privacy: .public)")
                }
            }
        }
    }

    /// Removes only these passkeys' suggestions. A full refresh would rebuild every suggestion from the
    /// database, and drop all the passwords' if it couldn't be read.
    func remove(_ passkeys: [PasskeySummary]) {
        guard !passkeys.isEmpty else { return }
        let identities: [any ASCredentialIdentity] = passkeys.map(Self.identity(for:))
        ASCredentialIdentityStore.shared.getState { [logger] state in
            guard state.isEnabled else { return }
            ASCredentialIdentityStore.shared.removeCredentialIdentities(identities) { _, error in
                if let error {
                    logger.error("Removing passkey identities failed: \(String(describing: error), privacy: .public)")
                }
            }
        }
    }

    static func identity(for password: DDPassword) -> ASPasswordCredentialIdentity? {
        guard let id = password.id, let host = DomainMatcher.host(from: password.website) else { return nil }
        let service = ASCredentialServiceIdentifier(identifier: host, type: .domain)
        return ASPasswordCredentialIdentity(serviceIdentifier: service, user: password.login, recordIdentifier: id.uuidString)
    }
}
