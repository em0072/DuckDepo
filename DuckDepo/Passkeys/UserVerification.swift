//
//  UserVerification.swift
//  DuckDepo
//

import LocalAuthentication

/// Confirms it's the device's owner before a passkey is made or used, so the authenticator data can
/// truthfully say the user was verified.
enum UserVerification {

    enum Result {
        /// Face ID, Touch ID or the passcode succeeded.
        case verified
        /// The device has no passcode, so only presence can be vouched for.
        case unavailable
        /// The user cancelled or failed.
        case failed
    }

    static func verify(reason: String) async -> Result {
        let context = LAContext()
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) else { return .unavailable }
        do {
            return try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) ? .verified : .failed
        } catch {
            return .failed
        }
    }
}
