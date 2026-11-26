//
//  Password Generator.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/11/2021.
//

import Foundation

public enum CharactersGroup: CaseIterable {
    case letters
    case numbers
    case capitals
    case symbols

    public var characters: [Character] {
        switch self {
        case .letters: return Array("abcdefghijklmnopqrstuvwxyz")
        case .numbers: return Array("0123456789")
        case .capitals: return Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        case .symbols: return Array(";,&%$@#^*~")
        }
    }
}

/// Generates passwords with the system's cryptographically secure random generator.
/// Every character in the selected groups is equally likely, and each selected group appears at least once.
public final class PasswordGenerator {

    public static let sharedInstance = PasswordGenerator()

    public func generatePassword(includeNumbers: Bool = true, includeCapitals: Bool = true, includeSymbols: Bool = true, length: Int = 16) -> String {
        var generator = SystemRandomNumberGenerator()
        return generatePassword(includeNumbers: includeNumbers, includeCapitals: includeCapitals,
                                includeSymbols: includeSymbols, length: length, using: &generator)
    }

    func generatePassword<G: RandomNumberGenerator>(includeNumbers: Bool, includeCapitals: Bool, includeSymbols: Bool,
                                                    length: Int, using generator: inout G) -> String {
        var groups: [CharactersGroup] = [.letters]
        if includeNumbers { groups.append(.numbers) }
        if includeCapitals { groups.append(.capitals) }
        if includeSymbols { groups.append(.symbols) }

        let length = max(length, groups.count)
        let all = groups.flatMap(\.characters)
        var password = groups.map { $0.characters.randomElement(using: &generator)! }
        while password.count < length {
            password.append(all.randomElement(using: &generator)!)
        }
        password.shuffle(using: &generator)
        return String(password)
    }
}
