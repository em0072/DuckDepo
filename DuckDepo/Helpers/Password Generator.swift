//
//  Password Generator.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/11/2021.
//

import Foundation

public typealias CharactersArray = [Character]
public typealias CharactersHash = [CharactersGroup : CharactersArray]

public enum CharactersGroup {
    case Letters
    case Numbers
    case Capitals
    case Symbols

    public static var groups: [CharactersGroup] {
        get {
            return [.Letters, .Numbers, .Capitals, .Symbols]
        }
    }

    private static func charactersString(group: CharactersGroup) -> String {
        switch group {
        case .Letters:
            return "abcdefghijklmnopqrstuvwxyz"
        case .Numbers:
            return "0123456789"
        case .Capitals:
            return "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        case .Symbols:
            return ";,&%$@#^*~"
        }
    }

    private static func characters(group: CharactersGroup) -> CharactersArray {
        var array: CharactersArray = []

        let string = charactersString(group: group)
        assert(string.count > 0)
        var index = string.startIndex

        while index != string.endIndex {
            let character = string[index]
            array.append(character)
            index = string.index(index, offsetBy: 1)
        }
        
        return array
    }

    public static var hash: CharactersHash {
        get {
            var hash: CharactersHash = [:]
            for group in groups {
                hash[group] = characters(group: group)
            }
            return hash
        }
    }

}

public class PasswordGenerator {

    private var hash: CharactersHash = [:]

    public static let sharedInstance = PasswordGenerator()

    private init() {
        self.hash = CharactersGroup.hash
    }

    public func generateBasicPassword() -> String {
        return generatePassword(includeNumbers: true, includeCapitals: false, includeSymbols: false, length: 8)
    }

    public func generateComplexPassword() -> String {
        return generatePassword(includeNumbers: true, includeCapitals: true, includeSymbols: true, length: 16)
    }

    private func charactersForGroup(group: CharactersGroup) -> CharactersArray {
        if let characters = hash[group] {
            return characters
        }
        assertionFailure("Characters should always be defined")
        return []
    }

    public func generatePassword(includeNumbers: Bool = true, includeCapitals: Bool = true, includeSymbols: Bool = true, length: Int = 16) -> String {

        var characters: CharactersArray = []
        characters.append(contentsOf: charactersForGroup(group: .Letters))
        if includeNumbers {
            characters.append(contentsOf: charactersForGroup(group: .Numbers))
        }
        if includeCapitals {
            characters.append(contentsOf: charactersForGroup(group: .Capitals))
        }
        if includeSymbols {
            characters.append(contentsOf: charactersForGroup(group: .Symbols))
        }

        var passwordArray: CharactersArray = []

        while passwordArray.count < length {
            let index = Int(arc4random()) % (characters.count - 1)
            passwordArray.append(characters[index])
        }

        var password = String(passwordArray)
        if !password.containsAnyCharacter(from: charactersForGroup(group: .Letters)) {
            password = String(generatePassword(includeNumbers: includeNumbers, includeCapitals: includeCapitals, includeSymbols: includeSymbols, length: length))
        }
        if includeNumbers && !password.containsAnyCharacter(from: charactersForGroup(group: .Numbers)) {
            password = String(generatePassword(includeNumbers: includeNumbers, includeCapitals: includeCapitals, includeSymbols: includeSymbols, length: length))
        }
        if includeCapitals && !password.containsAnyCharacter(from: charactersForGroup(group: .Capitals)) {
            password = String(generatePassword(includeNumbers: includeNumbers, includeCapitals: includeCapitals, includeSymbols: includeSymbols, length: length))
        }
        if includeSymbols && !password.containsAnyCharacter(from: charactersForGroup(group: .Symbols)) {
            password = String(generatePassword(includeNumbers: includeNumbers, includeCapitals: includeCapitals, includeSymbols: includeSymbols, length: length))
        }
        
        return password
    }

}
