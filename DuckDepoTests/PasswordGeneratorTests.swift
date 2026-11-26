//
//  PasswordGeneratorTests.swift
//  DuckDepoTests
//

import Testing
@testable import DuckDepo

struct PasswordGeneratorTests {

    private let generator = PasswordGenerator.sharedInstance

    @Test(arguments: [6, 13, 20, 64])
    func respectsLength(length: Int) {
        let password = generator.generatePassword(includeNumbers: true, includeCapitals: true, includeSymbols: true, length: length)
        #expect(password.count == length)
    }

    @Test func lengthIsAtLeastOneCharacterPerSelectedGroup() {
        let password = generator.generatePassword(includeNumbers: true, includeCapitals: true, includeSymbols: true, length: 1)
        #expect(password.count == 4)
    }

    @Test func everySelectedGroupAppears() {
        var rng = SeededGenerator(seed: 1)
        for _ in 0..<500 {
            let password = generator.generatePassword(includeNumbers: true, includeCapitals: true, includeSymbols: true, length: 6, using: &rng)
            for group in CharactersGroup.allCases {
                #expect(password.contains { group.characters.contains($0) }, "missing \(group) in \(password)")
            }
        }
    }

    @Test func excludedGroupsNeverAppear() {
        var rng = SeededGenerator(seed: 2)
        let excluded = Set(CharactersGroup.capitals.characters + CharactersGroup.symbols.characters)
        for _ in 0..<500 {
            let password = generator.generatePassword(includeNumbers: true, includeCapitals: false, includeSymbols: false, length: 16, using: &rng)
            #expect(!password.contains { excluded.contains($0) })
        }
    }

    /// The old generator used `random % (count - 1)` and could never produce the last character of the set.
    @Test func everyCharacterCanAppear() {
        var rng = SeededGenerator(seed: 3)
        var seen = Set<Character>()
        for _ in 0..<2_000 {
            seen.formUnion(generator.generatePassword(includeNumbers: true, includeCapitals: true, includeSymbols: true, length: 20, using: &rng))
        }
        let all = Set(CharactersGroup.allCases.flatMap(\.characters))
        #expect(seen == all)
        #expect(seen.contains("~"))
    }
}
