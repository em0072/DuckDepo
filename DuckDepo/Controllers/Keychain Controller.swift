//
//  Keychain Controller.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 24/06/2022.
//

import Foundation
import KeychainSwift

class Keychain {
        
    static var shared: KeychainSwift = {
        let keychain = KeychainSwift()
        keychain.accessGroup = "group.evgenymitko.duckdepo" // Use your own access goup
        keychain.synchronizable = true
        return keychain
    }()

}
