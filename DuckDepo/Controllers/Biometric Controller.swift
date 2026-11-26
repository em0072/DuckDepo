//
//  Biometric Controller.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 04/11/2021.
//

import Foundation
import LocalAuthentication
import Observation

/// App lock state.
///
/// - The app always starts locked when the lock is on. Lock state is never persisted, so a crash
///   or a kill can't leave the app unlocked.
/// - `isObscured` hides the content whenever the app isn't active (app switcher snapshot, Control Center).
/// - The "ask after" delay counts from the moment the app went to the background.
@Observable
final class BiometricController {

    enum BiometricType {
        case none
        case touch
        case face
        case opticId
    }

    /// Raw values are persisted; don't reorder.
    enum BiometricDelay: Int, CaseIterable {
        case none
        case fiveSeconds
        case fifteenSeconds
        case minute
        case fiveMinutes
        case fifteenMinutes

        var seconds: TimeInterval {
            switch self {
            case .none: return 0
            case .fiveSeconds: return 5
            case .fifteenSeconds: return 15
            case .minute: return 60
            case .fiveMinutes: return 60 * 5
            case .fifteenMinutes: return 60 * 15
            }
        }
    }

    /// Calls the completion on the main queue with `true` when the user authenticated.
    typealias Authenticator = (_ reason: String, _ completion: @escaping (Bool) -> Void) -> Void

    static let shared = BiometricController()

    var isBiometryEnabled: Bool {
        didSet {
            defaults.isBiometryEnabled = isBiometryEnabled
            if !isBiometryEnabled {
                isLocked = false
                isObscured = false
            }
        }
    }

    var biometricDelay: BiometricDelay {
        didSet {
            defaults.biometricDelay = biometricDelay.rawValue
        }
    }

    private(set) var isLocked: Bool {
        didSet { reportContentHidden() }
    }
    private(set) var isObscured = false {
        didSet { reportContentHidden() }
    }
    private(set) var isAuthenticating = false

    /// Called synchronously whenever `isContentHidden` changes. Observation reports changes later, which
    /// is too late for the cover to be in place before the app-switcher snapshot.
    @ObservationIgnored var onContentHiddenChange: ((Bool) -> Void)?
    @ObservationIgnored private var reportedContentHidden: Bool?

    /// `true` while content must be hidden.
    var isContentHidden: Bool {
        isLocked || isObscured
    }

    @ObservationIgnored private let defaults: DefaultsController
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private let canAuthenticate: () -> Bool
    @ObservationIgnored private let authenticator: Authenticator
    @ObservationIgnored private var backgroundedAt: Date?

    init(
        defaults: DefaultsController = .shared,
        now: @escaping () -> Date = Date.init,
        canAuthenticate: @escaping () -> Bool = BiometricController.deviceCanAuthenticate,
        authenticator: @escaping Authenticator = BiometricController.systemAuthenticate
    ) {
        self.defaults = defaults
        self.now = now
        self.canAuthenticate = canAuthenticate
        self.authenticator = authenticator
        let enabled = defaults.isBiometryEnabled
        isBiometryEnabled = enabled
        biometricDelay = BiometricDelay(rawValue: defaults.biometricDelay) ?? .none
        isLocked = enabled && canAuthenticate()
    }

    /// The lock only applies when the device has a passcode; without one there is nothing to authenticate with.
    var isLockRequired: Bool {
        isBiometryEnabled && canAuthenticate()
    }

    // MARK: - Scene phases

    func sceneDidBecomeActive() {
        isObscured = false
        if let backgroundedAt, isLockRequired, now().timeIntervalSince(backgroundedAt) >= biometricDelay.seconds {
            isLocked = true
        }
        backgroundedAt = nil
        if !isLockRequired {
            isLocked = false
        }
        if isLocked {
            unlock()
        }
    }

    func sceneWillResignActive() {
        // The Face ID sheet itself makes the app inactive; don't cover it.
        guard isLockRequired, !isAuthenticating else { return }
        isObscured = true
    }

    func sceneDidEnterBackground() {
        guard isLockRequired else { return }
        isObscured = true
        if backgroundedAt == nil {
            backgroundedAt = now()
        }
        if biometricDelay == .none {
            isLocked = true
        }
    }

    private func reportContentHidden() {
        let hidden = isContentHidden
        guard hidden != reportedContentHidden else { return }
        reportedContentHidden = hidden
        onContentHiddenChange?(hidden)
    }

    // MARK: - Authentication

    func unlock() {
        guard isLocked, !isAuthenticating else { return }
        guard isLockRequired else {
            isLocked = false
            return
        }
        isAuthenticating = true
        authenticator(String(localized: "lock_auth_reason")) { [weak self] success in
            guard let self else { return }
            self.isAuthenticating = false
            if success {
                self.isLocked = false
            }
        }
    }

    /// One-off check, e.g. in the AutoFill extension, independent of the app's lock state.
    func authenticate(completion: @escaping (Bool) -> Void) {
        authenticator(String(localized: "lock_auth_reason"), completion)
    }

    // MARK: - Device capabilities

    func biometricType() -> BiometricType {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        switch context.biometryType {
        case .touchID: return .touch
        case .faceID: return .face
        case .opticID: return .opticId
        default: return .none
        }
    }

    /// `true` when the device has a passcode (with or without biometrics).
    static func deviceCanAuthenticate() -> Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }

    func deviceHasPasscode() -> Bool {
        canAuthenticate()
    }

    static func systemAuthenticate(reason: String, completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) else {
            DispatchQueue.main.async { completion(false) }
            return
        }
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, _ in
            DispatchQueue.main.async { completion(success) }
        }
    }
}
