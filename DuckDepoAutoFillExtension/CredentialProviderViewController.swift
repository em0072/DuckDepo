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
    /// The passkey request on screen was answered or cancelled. Close can be tapped while it's being answered,
    /// so whichever comes first wins.
    private var isPasskeyRequestFinished = false

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
        // A passkey is only used after Face ID or the passcode, so its response can say the user was verified.
        guard credentialRequest.type != .passkeyAssertion, !requiresAuthentication else {
            cancel(.userInteractionRequired)
            return
        }
        complete(credentialRequest)
    }

    override func prepareInterfaceToProvideCredential(for credentialRequest: any ASCredentialRequest) {
        if credentialRequest.type == .passkeyAssertion, let request = credentialRequest as? ASPasskeyCredentialRequest {
            guard let identity = request.credentialIdentity as? ASPasskeyCredentialIdentity else {
                cancel(.credentialIdentityNotFound)
                return
            }
            signIn(credentialID: identity.credentialID, clientDataHash: request.clientDataHash,
                   preference: request.userVerificationPreference)
            return
        }
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

    // MARK: - Passkeys

    /// A site that accepts passkeys asked to sign in and the user opened DuckDepo's list. Passwords are
    /// listed too, as Apple asks: the user may not have a passkey for the site.
    override func prepareCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier],
                                        requestParameters: ASPasskeyCredentialRequestParameters) {
        let passkeys = PasskeyStorage().passkeys(for: requestParameters.relyingPartyIdentifier,
                                                 allowed: requestParameters.allowedCredentials)
        let viewModel = AutoFillPasswordsListViewModel(identifiers: serviceIdentifiers.map(\.identifier), passkeys: passkeys)
        show(AutoFillPasswordsListView(viewModel: viewModel, onClose: { [weak self] in
            self?.cancel(.userCanceled)
        }, onSelect: { [weak self] credential in
            self?.extensionContext.completeRequest(withSelectedCredential: credential, completionHandler: nil)
        }, onSelectPasskey: { [weak self, weak viewModel] passkey in
            self?.signIn(credentialID: passkey.credentialID, clientDataHash: requestParameters.clientDataHash,
                         preference: requestParameters.userVerificationPreference,
                         userJustVerified: viewModel?.wasUnlockedByUser ?? false)
        }))
    }

    /// A site wants to make a passkey and the user chose DuckDepo to keep it.
    override func prepareInterface(forPasskeyRegistration registrationRequest: any ASCredentialRequest) {
        guard let request = registrationRequest as? ASPasskeyCredentialRequest,
              let identity = request.credentialIdentity as? ASPasskeyCredentialIdentity,
              request.supportedAlgorithms.contains(.ES256) else {
            cancel(.failed)
            return
        }
        // The site already has one of DuckDepo's passkeys for this account.
        let storage = PasskeyStorage()
        if let excluded = request.excludedCredentials,
           excluded.contains(where: { storage.passkey(credentialID: $0.credentialID)?.relyingParty == identity.relyingPartyIdentifier }) {
            cancel(.matchedExcludedCredential)
            return
        }
        show(PasskeyRegistrationView(relyingParty: identity.relyingPartyIdentifier, userName: identity.userName, onCancel: { [weak self] in
            self?.cancel(.userCanceled)
        }, onSave: { [weak self] in
            self?.register(identity: identity, request: request)
        }))
    }

    private func register(identity: ASPasskeyCredentialIdentity, request: ASPasskeyCredentialRequest) {
        showWorking()
        Task {
            let verification = await UserVerification.verify(reason: String(localized: "passkey_save_reason \(identity.relyingPartyIdentifier)"))
            // Closed meanwhile: save nothing.
            guard claimPasskeyRequest() else { return }
            guard let userVerified = Self.userVerified(verification, preference: request.userVerificationPreference) else {
                cancel(verification == .failed ? .userCanceled : .failed)
                return
            }
            let passkey = Passkey.make(relyingParty: identity.relyingPartyIdentifier, userName: identity.userName,
                                       userHandle: identity.userHandle)
            guard let attestation = try? PasskeyAuthenticator.attestationObject(for: passkey, userVerified: userVerified),
                  let replaced = PasskeyStorage().saveReplacingEarlier(passkey) else {
                cancel(.failed)
                return
            }
            CredentialIdentityStoreController.shared.remove(replaced)
            CredentialIdentityStoreController.shared.add(passkey.summary)
            let credential = ASPasskeyRegistrationCredential(relyingParty: identity.relyingPartyIdentifier,
                                                             clientDataHash: request.clientDataHash,
                                                             credentialID: passkey.credentialID,
                                                             attestationObject: attestation)
            await extensionContext.completeRegistrationRequest(using: credential)
        }
    }

    /// Confirms it's the owner, unless they just unlocked DuckDepo with Face ID or the passcode, then signs.
    private func signIn(credentialID: Data, clientDataHash: Data,
                        preference: ASAuthorizationPublicKeyCredentialUserVerificationPreference,
                        userJustVerified: Bool = false) {
        guard let passkey = PasskeyStorage().passkey(credentialID: credentialID) else {
            cancel(.credentialIdentityNotFound)
            return
        }
        showWorking()
        Task {
            let verification: UserVerification.Result = if userJustVerified {
                .verified
            } else {
                await UserVerification.verify(reason: String(localized: "passkey_sign_in_reason \(passkey.relyingParty)"))
            }
            guard claimPasskeyRequest() else { return }
            guard let userVerified = Self.userVerified(verification, preference: preference) else {
                cancel(verification == .failed ? .userCanceled : .failed)
                return
            }
            guard let assertion = try? PasskeyAuthenticator.assertion(for: passkey, clientDataHash: clientDataHash,
                                                                     userVerified: userVerified) else {
                cancel(.failed)
                return
            }
            let credential = ASPasskeyAssertionCredential(userHandle: passkey.userHandle, relyingParty: passkey.relyingParty,
                                                          signature: assertion.signature, clientDataHash: clientDataHash,
                                                          authenticatorData: assertion.authenticatorData,
                                                          credentialID: passkey.credentialID)
            await extensionContext.completeAssertionRequest(using: credential)
        }
    }

    /// Replaces the screen that was tapped, so a second tap can't start the same thing again.
    private func showWorking() {
        isPasskeyRequestFinished = false
        show(PasskeyWorkingView(onCancel: { [weak self] in
            guard let self, claimPasskeyRequest() else { return }
            cancel(.userCanceled)
        }))
    }

    /// True only for the first of answering and Close.
    private func claimPasskeyRequest() -> Bool {
        guard !isPasskeyRequestFinished else { return false }
        isPasskeyRequestFinished = true
        return true
    }

    /// Whether to report the user as verified; nil when the request can't go ahead.
    private static func userVerified(_ verification: UserVerification.Result,
                                     preference: ASAuthorizationPublicKeyCredentialUserVerificationPreference) -> Bool? {
        switch verification {
        case .verified: true
        case .failed: nil
        // Without a passcode the user can't be verified; fine unless the site insists.
        case .unavailable: preference == .required ? nil : false
        }
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
