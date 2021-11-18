//
//  Biometric Controller.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 04/11/2021.
//

import Foundation
import LocalAuthentication
import SwiftUI


class BiometricController: ObservableObject {
    
    enum BiometricType {
        case unknown
        case none
        case touch
        case face
    }
    
    enum BiometricDelay: Int, CaseIterable {
        case none
        case fiveSeconds
        case fiveteenSeconds
        case minute
        case fiveMinutes
        case fiveteenMinutes
        
        func numberOfSeconds() -> TimeInterval {
            switch self {
            case .none:
                return 0
            case .fiveSeconds:
                return 5
            case .fiveteenSeconds:
                return 15
            case .minute:
                return 60
            case .fiveMinutes:
                return 60 * 5
            case .fiveteenMinutes:
                return 60 * 15
            }
        }
    }

    enum BiometricError: Error {
        case noBiometricAvailable
    }
    
    static let shared = BiometricController()
    
    private init(){
        isUnlocked = defaultController.isUnlocked
        isBiometryEnabled = defaultController.isBiometryEnabled
        biometricDelay = BiometricDelay(rawValue: defaultController.biometricDelay) ?? .none
    }
    
    private let defaultController = DefaultsController.shared
    @Published var isBiometryEnabled = false {
        didSet {
            defaultController.isBiometryEnabled = isBiometryEnabled
            // need to set isUnlocked in userDefaults to make sure password will be asked if isBiometricEnabled is set to true and then quit the app immediatley
            if !isBiometryEnabled {
                defaultController.isUnlocked = !isBiometryEnabled
            }
        }
    }
    @Published var isUnlocked = true {
        didSet {
            print("isUnlocked - \(isUnlocked)")
            defaultController.isUnlocked = isUnlocked
        }
    }
    @Published var biometricDelay: BiometricDelay = .none {
        didSet {
            defaultController.biometricDelay = biometricDelay.rawValue
        }
    }
    private var lastAuthenticate: Double {
        get {
            return defaultController.lastAuthenticate
        }
        set {
            defaultController.lastAuthenticate = newValue
        }
    }
    private var authenticationInProgress = false
    private var isBackgroundState = false

    
    func biometricType() -> BiometricType {
        let authContext = LAContext()
        let _ = authContext.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
            switch(authContext.biometryType) {
            case .none:
                return .none
            case .touchID:
                return .touch
            case .faceID:
                return .face
            @unknown default:
                return .unknown
            }
    }
    
    public func onActiveState() {
        isBackgroundState = false
        print("Check if biometric enabled - \(defaultController.isBiometryEnabled) & device Has passcode - \(deviceHasPasscode())")
        guard defaultController.isBiometryEnabled && deviceHasPasscode() else {
            print("set isUnlocked to true")
            isUnlocked = true
            return
        }
        guard !authenticationInProgress else { return }
        // Check if app should be locked based on the biometricDelay
        print("Now is \(Date().timeIntervalSinceReferenceDate)")
        print("lastAuthenticate is \(lastAuthenticate)")
        print("biometricDelay.numberOfSeconds is \(biometricDelay.numberOfSeconds())")
        if Date().timeIntervalSinceReferenceDate - lastAuthenticate >= biometricDelay.numberOfSeconds() && biometricDelay != .none {
            isUnlocked = false
        }

        if !isUnlocked {
            runAuthentication()
        }
    }
    
    public func onInactiveState() {
        guard defaultController.isBiometryEnabled && deviceHasPasscode() && !authenticationInProgress && !isBackgroundState else { return }
        if biometricDelay == .none {
            isUnlocked = false
        } else {
            updateLastAuthenticated()
        }
    }
    
    public func onBackgroundState() {
        isBackgroundState = true
    }
    
    public func deviceHasPasscode() -> Bool {
        let secret = "Device has passcode set?".data(using: String.Encoding.utf8, allowLossyConversion: false)
        let attributes = [kSecClass as String:kSecClassGenericPassword, kSecAttrService as String:"LocalDeviceServices", kSecAttrAccount as String:"NoAccount", kSecValueData as String:secret!, kSecAttrAccessible as String:kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly] as [String : Any]

        let status = SecItemAdd(attributes as CFDictionary, nil)
        if status == 0 {
            SecItemDelete(attributes as CFDictionary)
            return true
        }

        return false
    }
    
    public func authenicate(completion: @escaping (Result<Bool, Error>) -> Void) {
        authenticationInProgress = true
        let context = LAContext()
        var error: NSError?

        // check whether biometric authentication is possible
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            // it's possible, so go ahead and use it
            let reason = "We need to unlock your data."

            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authenticationError in
                // authentication has now completed
                DispatchQueue.main.async {
                    completion(.success(success))
                    self.authenticationInProgress = false
                }
            }
        } else {
            // no biometrics
            completion(.failure(BiometricError.noBiometricAvailable))
            self.authenticationInProgress = false
        }

    }

    
    private func runAuthentication() {
        //Check if authentication needs to be performed due to the biometric Delay
        authenicate { result in
            if case .success(let successfully) = result {
                self.isUnlocked = successfully
                self.updateLastAuthenticated()
            }
        }
    }

    private func updateLastAuthenticated() {
        lastAuthenticate = Date().timeIntervalSinceReferenceDate
    }


}
