//
//  Defaults Controller.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 12/11/2021.
//

import Foundation


class DefaultsController {
    
    enum DefaultsKeys {
        static let isBiometryEnabled: String = "biometryEnabled"
        static let isUnlocked: String = "isUnlocked"
        static let isBiometricPolicyEvaluated: String = "isUnlocked"
        static let biometricDelay: String = "biometricDelay"
        static let lastAuthenticate: String = "lastAuthenticate"
    }
    
    static let shared = DefaultsController()
    
    private let defaults = UserDefaults.standard
    
    private init(){}
    
    // MARK: - Biometric properties
    var isBiometryEnabled: Bool {
        get {
            defaults.bool(forKey: DefaultsKeys.isBiometryEnabled)
        }
        set {
            defaults.set(newValue, forKey: DefaultsKeys.isBiometryEnabled)
        }
    }
    
    var biometricDelay: Int {
        get {
            defaults.integer(forKey: DefaultsKeys.biometricDelay)
        }
        set {
            defaults.set(newValue, forKey: DefaultsKeys.biometricDelay)
        }
    }
    
    var lastAuthenticate: Double {
        get {
            defaults.double(forKey: DefaultsKeys.lastAuthenticate)
        }
        set {
            defaults.set(newValue, forKey: DefaultsKeys.lastAuthenticate)
        }
    }
    
    var isBiometricPolicyEvaluated: Bool {
        get {
            defaults.bool(forKey: DefaultsKeys.isBiometricPolicyEvaluated)
        }
        set {
            defaults.set(newValue, forKey: DefaultsKeys.isBiometricPolicyEvaluated)
        }
    }
    
    
    var isUnlocked : Bool {
        get {
            defaults.bool(forKey: DefaultsKeys.isUnlocked)
        }
        set {
            defaults.set(newValue, forKey: DefaultsKeys.isUnlocked)
        }
    }
    
    
    
}
