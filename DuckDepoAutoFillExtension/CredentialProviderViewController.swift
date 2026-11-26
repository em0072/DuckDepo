//
//  CredentialProviderViewController.swift
//  DuckDepoAutoFillExtension
//
//  Created by Evgeny Mitko on 27/06/2022.
//

import AuthenticationServices
import SwiftUI
import UIKit

final class CredentialProviderViewController: ASCredentialProviderViewController {

    private let lock = BiometricController.shared

    /// The user opened the AutoFill list from the keyboard or a password field.
    override func prepareCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        let viewModel = AutoFillPasswordsListViewModel(identifiers: serviceIdentifiers.map(\.identifier))
        show(AutoFillPasswordsListView(viewModel: viewModel, onClose: { [weak self] in
            self?.cancel(.userCanceled)
        }, onSelect: { [weak self] credential in
            self?.extensionContext.completeRequest(withSelectedCredential: credential, completionHandler: nil)
        }))
    }

    /// A site asked for a one-time code and the user opened the list.
    override func prepareOneTimeCodeCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        let viewModel = AutoFillPasswordsListViewModel(identifiers: serviceIdentifiers.map(\.identifier), mode: .oneTimeCodes)
        show(AutoFillPasswordsListView(viewModel: viewModel, onClose: { [weak self] in
            self?.cancel(.userCanceled)
        }, onSelectCode: { [weak self] code in
            self?.extensionContext.completeOneTimeCodeRequest(using: ASOneTimeCodeCredential(code: code), completionHandler: nil)
        }))
    }

    /// The user picked a suggestion in the QuickType bar. Without the app lock we can fill right away;
    /// with it, ask the system to show our UI so the user can authenticate first.
    override func provideCredentialWithoutUserInteraction(for credentialRequest: any ASCredentialRequest) {
        guard !requiresAuthentication else {
            cancel(.userInteractionRequired)
            return
        }
        complete(credentialRequest)
    }

    override func prepareInterfaceToProvideCredential(for credentialRequest: any ASCredentialRequest) {
        guard requiresAuthentication else {
            complete(credentialRequest)
            return
        }
        let authenticateAndFill: () -> Void = { [weak self] in
            self?.lock.authenticate { success in
                if success {
                    self?.complete(credentialRequest)
                }
            }
        }
        show(NavigationStack {
            AutoFillUnlockView(onUnlock: authenticateAndFill)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(role: .close) { [weak self] in
                            self?.cancel(.userCanceled)
                        }
                    }
                }
                .task { authenticateAndFill() }
        }
        .tint(.duckYellow))
    }

    // MARK: - Helpers

    /// Until the app has run once after updating, its lock setting may not be readable yet, so authenticate then too.
    private var requiresAuthentication: Bool {
        guard BiometricController.deviceCanAuthenticate() else { return false }
        return lock.isLockRequired || !DefaultsController.shared.isSharedStoreReady
    }

    private func complete(_ request: any ASCredentialRequest) {
        let identity = request.credentialIdentity
        if request.type == .oneTimeCode {
            guard let recordID = identity.recordIdentifier, let id = UUID(uuidString: recordID),
                  let code = Keychain.shared.string(forKey: PasswordsStorage.oneTimeCodeKey(for: id)).flatMap(OneTimeCode.init(text:)) else {
                cancel(.credentialIdentityNotFound)
                return
            }
            extensionContext.completeOneTimeCodeRequest(using: ASOneTimeCodeCredential(code: code.code()), completionHandler: nil)
            return
        }
        guard let recordID = identity.recordIdentifier, let value = Keychain.shared.string(forKey: recordID) else {
            cancel(.credentialIdentityNotFound)
            return
        }
        let credential = ASPasswordCredential(user: (identity as? ASPasswordCredentialIdentity)?.user ?? "", password: value)
        extensionContext.completeRequest(withSelectedCredential: credential, completionHandler: nil)
    }

    private func cancel(_ code: ASExtensionError.Code) {
        extensionContext.cancelRequest(withError: ASExtensionError(code))
    }

    private func show<Content: View>(_ rootView: Content) {
        children.forEach { child in
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }
        let host = UIHostingController(rootView: rootView)
        addChild(host)
        view.addSubview(host.view)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        host.didMove(toParent: self)
    }
}
