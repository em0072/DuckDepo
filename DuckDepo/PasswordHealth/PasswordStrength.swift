//
//  PasswordStrength.swift
//  DuckDepo
//

import Foundation

/// Estimates how easy a password is to guess, on the device. A rough model of how cracking tools try
/// passwords: common passwords and words first (with capitals, digits and look-alike symbols), then
/// runs, repeats, keyboard rows and years, and only the rest character by character.
enum PasswordStrength {

    enum Weakness: Hashable {
        /// Fewer than `minimumLength` characters.
        case short
        /// A common password, maybe with capitals, look-alike symbols or digits around it.
        case common
        /// Made of guessable parts: words, runs, repeats, years.
        case predictable
    }

    static let minimumLength = 8
    /// Guessing work, in bits, below which a password is easy to guess: about 7·10¹⁰ guesses, which an
    /// offline attack on a fast hash gets through in seconds.
    static let minimumBits: Double = 36

    /// Characters judged. Any password this long is fine unless its start is guessable, and judging a
    /// pasted page of text would hold up the whole report.
    static let maximumJudgedLength = 256

    /// Nil for a password that is fine, and for an empty one (nothing to judge).
    static func weakness(of password: String) -> Weakness? {
        guard !password.isEmpty else { return nil }
        let password = String(password.prefix(maximumJudgedLength))
        if isCommon(password) {
            return .common
        }
        if password.count < minimumLength {
            return .short
        }
        return bits(of: password) < minimumBits ? .predictable : nil
    }

    // MARK: - Common passwords

    /// The most digits and symbols, in all, around a common password that still make it that password
    /// ("Password123!"). Past this they're mostly random, and the guessing work decides.
    static let maximumAffix = 6

    /// The password is a common one once capitals, look-alike symbols, and a few digits or symbols around
    /// it are taken away ("P@ssw0rd123!" is "password", "Footba11" is "football").
    static func isCommon(_ password: String) -> Bool {
        spellings(of: password.lowercased()).contains(where: isCommonWithAffixes)
    }

    /// The password as typed, and with look-alikes read as letters ("1" as "i" and as "l"), either only
    /// between letters ("p@ssw0rd", leaving "123" in "abc123" alone) or everywhere ("footba11").
    private static func spellings(of lowered: String) -> [String] {
        var spellings = [lowered]
        for table in [lookAlikesAsI, lookAlikesAsL] {
            for insideOnly in [true, false] {
                let spelling = replacingLookAlikes(in: lowered, using: table, insideOnly: insideOnly)
                if !spellings.contains(spelling) {
                    spellings.append(spelling)
                }
            }
        }
        return spellings
    }

    /// A list entry once up to `maximumAffix` digits and symbols in all come off its ends. Only off the
    /// ends: "1q2w3e4r!" is "1q2w3e4r", which keeps its own digits.
    private static func isCommonWithAffixes(_ text: String) -> Bool {
        let characters = Array(text)
        let leading = characters.prefix { !$0.isLetter }.count
        let trailing = characters.reversed().prefix { !$0.isLetter }.count
        for front in 0...min(leading, maximumAffix) {
            for back in 0...min(trailing, maximumAffix - front) where front + back < characters.count {
                let candidate = String(characters[front..<characters.count - back])
                if candidate.count >= 3, CommonPasswords.all.contains(candidate) {
                    return true
                }
            }
        }
        return false
    }

    private static func replacingLookAlikes(in lowered: String, using table: [Character: Character], insideOnly: Bool) -> String {
        let characters = Array(lowered)
        let first = characters.firstIndex(where: \.isLetter)
        let last = characters.lastIndex(where: \.isLetter)
        return String(characters.enumerated().map { index, character in
            guard let letter = table[character] else { return character }
            if insideOnly {
                guard let first, let last, index > first, index < last else { return character }
            }
            return letter
        })
    }

    private static let lookAlikesAsI: [Character: Character] = [
        "@": "a", "4": "a", "8": "b", "3": "e", "6": "g", "1": "i", "!": "i", "|": "i", "0": "o", "5": "s", "$": "s",
        "7": "t",
    ]
    private static let lookAlikesAsL = lookAlikesAsI.merging(["1": "l", "!": "l", "|": "l"]) { $1 }

    // MARK: - Guessing work

    /// Roughly log₂ of the guesses needed: each guessable part (word, run, repeat, year) costs a few bits,
    /// every other character the log₂ of the alphabet the password draws from.
    static func bits(of password: String) -> Double {
        let characters = Array(password)
        let lowered = Array(password.lowercased())
        let alphabet = log2(Double(alphabetSize(of: characters)))
        var bits = 0.0
        var index = 0
        while index < characters.count {
            if let part = guessablePart(in: characters, lowered: lowered, at: index) {
                bits += part.bits
                index += part.length
            } else {
                bits += alphabet
                index += 1
            }
        }
        return bits
    }

    private struct Part {
        let length: Int
        let bits: Double
    }

    /// The longest guessable part starting at `index`.
    private static func guessablePart(in characters: [Character], lowered: [Character], at index: Int) -> Part? {
        [word(in: characters, lowered: lowered, at: index),
         repeated(in: lowered, at: index),
         run(in: lowered, at: index),
         year(in: characters, at: index)]
            .compactMap { $0 }
            .max { $0.length < $1.length }
    }

    /// A common password or word of four or more characters, as typed or with look-alikes read as letters.
    private static func word(in characters: [Character], lowered: [Character], at index: Int) -> Part? {
        let longest = min(CommonPasswords.longest, lowered.count - index)
        guard longest >= 4 else { return nil }
        for length in stride(from: longest, through: 4, by: -1) {
            let slice = lowered[index..<index + length]
            let typed = String(slice)
            // About 2¹⁰ common words, a bit more for capitals, a bit more for look-alikes.
            let capitals: Double = characters[index..<index + length].contains(where: \.isUppercase) ? 1 : 0
            if CommonPasswords.all.contains(typed) {
                return Part(length: length, bits: 10 + capitals)
            }
            for table in [lookAlikesAsI, lookAlikesAsL] {
                let plain = String(slice.map { table[$0] ?? $0 })
                if plain != typed, plain.allSatisfy(\.isLetter), CommonPasswords.all.contains(plain) {
                    return Part(length: length, bits: 11 + capitals)
                }
            }
        }
        return nil
    }

    /// The same character three or more times, or the same two to six characters twice or more ("abab",
    /// "blahblah", "1a1a1a").
    private static func repeated(in lowered: [Character], at index: Int) -> Part? {
        var best: Part?
        var end = index + 1
        while end < lowered.count, lowered[end] == lowered[index] {
            end += 1
        }
        if end - index >= 3 {
            best = Part(length: end - index, bits: log2(Double(alphabetSize(of: [lowered[index]]))) + log2(Double(end - index)))
        }
        for unit in 2...6 where index + unit * 2 <= lowered.count {
            let pattern = lowered[index..<index + unit]
            var count = 1
            while index + unit * (count + 1) <= lowered.count,
                  lowered[(index + unit * count)..<(index + unit * (count + 1))] == pattern {
                count += 1
            }
            guard count >= 2, unit * count > (best?.length ?? 0) else { continue }
            // The unit once, then how many times.
            let unitBits = Double(unit) * log2(Double(alphabetSize(of: Array(pattern))))
            best = Part(length: unit * count, bits: unitBits + log2(Double(count)))
        }
        return best
    }

    /// Three or more neighbours in the alphabet, the digits or a keyboard row or column, either way ("abc",
    /// "987", "qwerty", "!@#$", "1q2w3e", "1qaz2wsx", "йцукен").
    private static func run(in lowered: [Character], at index: Int) -> Part? {
        guard index + 2 < lowered.count else { return nil }
        var best = 0
        for sequence in sequences {
            guard let start = sequence.firstIndex(of: lowered[index]) else { continue }
            for step in [1, -1] {
                var length = 1
                var position = start
                while index + length < lowered.count {
                    let next = position + step
                    guard sequence.indices.contains(next), sequence[next] == lowered[index + length] else { break }
                    position = next
                    length += 1
                }
                best = max(best, length)
            }
        }
        guard best >= 3 else { return nil }
        // Which run, where it starts, which way, how long.
        return Part(length: best, bits: log2(Double(sequences.count)) + log2(30) + 1 + log2(Double(best)))
    }

    private static let sequences: [[Character]] = [
        "abcdefghijklmnopqrstuvwxyz", "0123456789", "qwertyuiop", "asdfghjkl", "zxcvbnm", "1234567890",
        // The digit row shifted (US and Russian layouts), and walks down the keyboard.
        "!@#$%^&*()", "!\"№;%:?*()", "1q2w3e4r5t6y7u8i9o0p", "1qaz2wsx3edc4rfv5tgb6yhn7ujm8ik9ol0p",
        "абвгдеёжзийклмнопрстуфхцчшщъыьэюя", "йцукенгшщзхъ", "фывапролджэ", "ячсмитьбю",
    ].map(Array.init)

    /// A year from 1900 to 2099.
    private static func year(in characters: [Character], at index: Int) -> Part? {
        guard index + 4 <= characters.count else { return nil }
        let digits = String(characters[index..<index + 4])
        guard digits.allSatisfy(\.isASCIIDigit), let value = Int(digits), (1900...2099).contains(value) else { return nil }
        return Part(length: 4, bits: log2(200))
    }

    /// How many characters a guesser would try for each position: the sum of the kinds the password uses.
    private static func alphabetSize(of characters: [Character]) -> Int {
        var size = 0
        if characters.contains(where: { $0.isASCIILowercase }) { size += 26 }
        if characters.contains(where: { $0.isASCIIUppercase }) { size += 26 }
        if characters.contains(where: \.isASCIIDigit) { size += 10 }
        if characters.contains(where: { $0.isASCII && !$0.isLetter && !$0.isNumber }) { size += 33 }
        if characters.contains(where: { !$0.isASCII && $0.isLowercase }) { size += 33 }
        if characters.contains(where: { !$0.isASCII && $0.isUppercase }) { size += 33 }
        // Scripts without capitals (Hebrew, Arabic, Chinese, Japanese, Korean, Thai...): tens of letters to
        // thousands of characters.
        if characters.contains(where: { !$0.isASCII && $0.isLetter && !$0.isLowercase && !$0.isUppercase }) { size += 50 }
        if characters.contains(where: { !$0.isASCII && !$0.isLetter }) { size += 100 }
        return max(size, 1)
    }
}

private extension Character {
    var isASCIIDigit: Bool { isASCII && isNumber }
    var isASCIILowercase: Bool { isASCII && isLowercase }
    var isASCIIUppercase: Bool { isASCII && isUppercase }
}
