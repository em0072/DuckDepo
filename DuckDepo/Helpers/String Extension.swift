//
//  String Extension.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 29/10/2021.
//

import Foundation

extension String {
    
    public func containsAnyCharacter(from characters: [Character]) -> Bool {
        for letter in Set(self) {
            for char in characters {
                if char == letter {
                    return true
                }
            }
        }
        return false
    }
    
    func localized() -> String {
        return NSLocalizedString(self, comment: self)
    }
    
    func localizedPlurual(_ number: Int) -> String {
        let localzedString = NSLocalizedString(self, comment: self)
        return String.localizedStringWithFormat(localzedString, number)
    }
    
}
