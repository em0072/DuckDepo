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
        keychain.synchronizable = true
        keychain.accessGroup = "65952893XA.group.evgenymitko.duckdepo"
        return keychain
    }()

}
