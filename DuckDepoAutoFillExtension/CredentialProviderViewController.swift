//
//  CredentialProviderViewController.swift
//  DuckDepoAutoFillExtension
//
//  Created by Evgeny Mitko on 27/06/2022.
//
import UIKit
import SwiftUI
import AuthenticationServices
import KeychainSwift
import Combine

class CredentialProviderViewController: ASCredentialProviderViewController {

    /*
     Prepare your UI to list available credentials for the user to choose from. The items in
     'serviceIdentifiers' describe the service the user is logging in to, so your extension can
     prioritize the most relevant credentials in the list.
    */
    override func prepareCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        let viewModel = AutoFillPasswordsListViewModel(identifiers: prepareIdentifiers(serviceIdentifiers))
        let swiftUIView = AutoFillPasswordsListView(viewModel: viewModel) {
            self.extensionContext.cancelRequest(withError: NSError(domain: ASExtensionErrorDomain, code: ASExtensionError.userCanceled.rawValue))
        } onSelect: { password in
            let passwordCredential = ASPasswordCredential(user: password.login, password: password.value)
            self.extensionContext.completeRequest(withSelectedCredential: passwordCredential, completionHandler: nil)
        }
        let hostController = UIHostingController(rootView: swiftUIView)
        addChild(hostController)
        view.addSubview(hostController.view)
        
        hostController.view.translatesAutoresizingMaskIntoConstraints = false
        let constraints =
        [hostController.view.topAnchor.constraint(equalTo: view.topAnchor),
         hostController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
         hostController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
         hostController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)]
        
        NSLayoutConstraint.activate(constraints)
        hostController.didMove(toParent: self)
    }
        
    private func prepareIdentifiers( _ serviceIdentifiers: [ASCredentialServiceIdentifier]) -> [String] {
        serviceIdentifiers.map({ $0.identifier } )
    }
//     Implement this method if your extension supports showing credentials in the QuickType bar.
//     When the user selects a credential from your app, this method will be called with the
//     ASPasswordCredentialIdentity your app has previously saved to the ASCredentialIdentityStore.
//     Provide the password by completing the extension request with the associated ASPasswordCredential.
//     If using the credential would require showing custom UI for authenticating the user, cancel
//     the request with error code ASExtensionError.userInteractionRequired.

    override func provideCredentialWithoutUserInteraction(for credentialIdentity: ASPasswordCredentialIdentity) {
        let keychain = Keychain.shared
        guard let identifier = credentialIdentity.recordIdentifier, let passwordValue = keychain.get(identifier) else {
            self.extensionContext.cancelRequest(withError: NSError(domain: ASExtensionErrorDomain, code: ASExtensionError.credentialIdentityNotFound.rawValue))
            return
        }
        let passwordCredential = ASPasswordCredential(user: credentialIdentity.user, password: passwordValue)
        self.extensionContext.completeRequest(withSelectedCredential: passwordCredential, completionHandler: nil)
    }
    

    /*
     Implement this method if provideCredentialWithoutUserInteraction(for:) can fail with
     ASExtensionError.userInteractionRequired. In this case, the system may present your extension's
     UI and call this method. Show appropriate UI for authenticating the user then provide the password
     by completing the extension request with the associated ASPasswordCredential.

    override func prepareInterfaceToProvideCredential(for credentialIdentity: ASPasswordCredentialIdentity) {
    }
    */
}
