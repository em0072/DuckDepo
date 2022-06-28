//
//  CredentialIdentityStoreController.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 27/06/2022.
//

import Foundation
import AuthenticationServices
import Combine

class CredentialIdentityStoreController {
    
    static var shared: CredentialIdentityStoreController = CredentialIdentityStoreController()
    private var cancellable = Set<AnyCancellable>()

    private init() {
        
    }
    
    func checkState() {
        ASCredentialIdentityStore.shared.getState { [weak self] state in
            if state.isEnabled {
                if !state.supportsIncrementalUpdates {
                    self?.replaceIdentityStore()
                }
            }
        }
    }
    
    func replaceIdentityStore() {
        var credentialIdentities = [ASPasswordCredentialIdentity]()
        PasswordsStorage().passwords.sink { [weak self] passwords in
            for password in passwords {
                if let identity = self?.convertToIdentity(password) {
                    credentialIdentities.append(identity)
                }
            }
            ASCredentialIdentityStore.shared.replaceCredentialIdentities(with: credentialIdentities) { _, error in
                if let error = error {
                    print(error.localizedDescription)
                }
                self?.cancellable.removeAll()
            }
        }.store(in: &cancellable)
    }
    
    func save(_ password: Password) {
        let identity = convertToIdentity(password)
        ASCredentialIdentityStore.shared.saveCredentialIdentities([identity])
    }
    
    func remove(_ password: Password) {
        let identity = convertToIdentity(password)
        ASCredentialIdentityStore.shared.removeCredentialIdentities([identity])
    }
    
    func removeAll() {
        ASCredentialIdentityStore.shared.removeAllCredentialIdentities()
    }
    
    private func convertToIdentity(_ password: Password) -> ASPasswordCredentialIdentity {
        let service = password.website
        let serviceIdentifier = ASCredentialServiceIdentifier(identifier: service, type: service.starts(with: "http") ? .URL : .domain)
        let identity = ASPasswordCredentialIdentity(serviceIdentifier: serviceIdentifier, user: password.login, recordIdentifier: password.id.uuidString)
        return identity
    }
}
