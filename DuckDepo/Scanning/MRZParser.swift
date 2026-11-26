//
//  MRZParser.swift
//  DuckDepo
//

import Foundation

/// The machine-readable zone of a passport, ID card or visa (ICAO 9303): the two or three lines of
/// capitals and `<` at the bottom of the photo page.
struct MRZ: Equatable {

    enum Format: Equatable {
        /// ID cards: three lines of 30.
        case td1
        /// Older ID cards and some visas: two lines of 36.
        case td2
        /// Passports and most visas: two lines of 44.
        case td3
    }

    enum Kind: Equatable {
        case passport
        case idCard
        case visa
        case other
    }

    enum Sex: String, Equatable {
        case male = "M"
        case female = "F"
        case unspecified = "X"
    }

    let format: Format
    /// "P" for passports, "I", "A" or "C" for ID cards, "V" for visas, sometimes with a second letter.
    let documentCode: String
    /// ICAO country code, mostly ISO 3166 alpha-3 ("NLD"), but "D" for Germany.
    let issuingCountry: String
    let surname: String
    let givenNames: String
    let documentNumber: String
    let nationality: String
    /// "yyyy-MM-dd", the way `FieldDate` stores days. Nil when the date is unknown or unreadable.
    let birthDate: String?
    let expiryDate: String?
    let sex: Sex?
    /// The personal number or other optional data, without filler.
    let optionalData: String
    /// Every check digit matched. A zone that fails a check may still be mostly right, so it's returned
    /// anyway; its values should be shown as needing review.
    let isVerified: Bool

    var kind: Kind {
        switch documentCode.first {
        case "P": .passport
        case "I", "A", "C": .idCard
        case "V": .visa
        default: .other
        }
    }

    /// Given names then surname, in title case: "Anna Maria Eriksson".
    var fullName: String {
        [givenNames, surname]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .capitalized(with: Locale(identifier: "en_US_POSIX"))
    }
}

enum MRZParser {

    /// Finds and reads a machine-readable zone among recognized text lines, given in reading order.
    /// Tolerates the usual recognition mistakes: spaces, `«` for `<<`, letters for digits and back.
    static func parse(lines: [String], today: Date = .now) -> MRZ? {
        let candidates = lines.flatMap(splitMerged).map(normalized).filter(looksLikeMRZ)
        var best: Reading?
        for index in candidates.indices {
            let next = candidates.dropFirst(index + 1)
            var readings: [Reading?] = []
            if next.count >= 2 {
                readings.append(parseTD1(candidates[index], next[index + 1], next[index + 2], today: today))
            }
            if next.count >= 1 {
                readings.append(parseTD3(candidates[index], next[index + 1], today: today))
                readings.append(parseTD2(candidates[index], next[index + 1], today: today))
            }
            for case let reading? in readings {
                if reading.mrz.isVerified {
                    return reading.mrz
                }
                if reading.isPlausible, reading.passed > best?.passed ?? -1 {
                    best = reading
                }
            }
        }
        return best?.mrz
    }

    /// ICAO 9303 check digit: weights 7, 3, 1; digits as themselves, A–Z as 10–35, `<` as 0.
    static func checkDigit(_ characters: some StringProtocol) -> Int? {
        let weights = [7, 3, 1]
        var sum = 0
        for (index, character) in characters.enumerated() {
            guard let value = value(of: character) else { return nil }
            sum += value * weights[index % 3]
        }
        return sum % 10
    }

    // MARK: - Formats

    private struct Reading {
        let mrz: MRZ
        let passed: Int
        let total: Int

        /// Enough checks pass that this is a zone with a few misread characters, not ordinary text.
        var isPlausible: Bool {
            passed * 2 >= total
        }

        init(_ mrz: (Bool) -> MRZ, checks: [Bool]) {
            passed = checks.filter { $0 }.count
            total = checks.count
            self.mrz = mrz(passed == total)
        }
    }

    private static func parseTD3(_ first: String, _ second: String, today: Date) -> Reading? {
        guard let line1 = Line(first, length: 44), let line2 = Line(second, length: 44),
              isDocumentCode(line1[0]) else { return nil }
        let code = documentCode(line1[0], line1[1])
        let number = documentNumber(line2[0..<9], check: line2[9])
        let birth = digits(line2[13..<19])
        let expiry = digits(line2[21..<27])
        let optional = line2[28..<42]
        var checks = [number.isValid, passes(birth, line2[19]), passes(expiry, line2[27])]
        // Visas have no check over the optional data and no composite check.
        if code.first != "V" {
            checks.append(passes(optional, line2[42]))
            let composite = number.raw + line2[9] + birth + line2[19] + expiry + line2[27] + optional + line2[42]
            checks.append(passes(composite, line2[43]))
        }
        let (surname, givenNames) = names(line1[5..<44])
        return Reading({ verified in
            MRZ(format: .td3, documentCode: code, issuingCountry: country(line1[2..<5]),
                surname: surname, givenNames: givenNames, documentNumber: number.value,
                nationality: country(line2[10..<13]),
                birthDate: date(birth, isBirthDate: true, today: today),
                expiryDate: date(expiry, isBirthDate: false, today: today),
                sex: MRZ.Sex(rawValue: line2[20]), optionalData: withoutFiller(optional),
                isVerified: verified)
        }, checks: checks)
    }

    private static func parseTD2(_ first: String, _ second: String, today: Date) -> Reading? {
        guard let line1 = Line(first, length: 36), let line2 = Line(second, length: 36),
              isDocumentCode(line1[0]) else { return nil }
        let code = documentCode(line1[0], line1[1])
        let number = documentNumber(line2[0..<9], check: line2[9])
        let birth = digits(line2[13..<19])
        let expiry = digits(line2[21..<27])
        let optional = line2[28..<35]
        var checks = [number.isValid, passes(birth, line2[19]), passes(expiry, line2[27])]
        if code.first != "V" {
            let composite = number.raw + line2[9] + birth + line2[19] + expiry + line2[27] + optional
            checks.append(passes(composite, line2[35]))
        }
        let (surname, givenNames) = names(line1[5..<36])
        return Reading({ verified in
            MRZ(format: .td2, documentCode: code, issuingCountry: country(line1[2..<5]),
                surname: surname, givenNames: givenNames, documentNumber: number.value,
                nationality: country(line2[10..<13]),
                birthDate: date(birth, isBirthDate: true, today: today),
                expiryDate: date(expiry, isBirthDate: false, today: today),
                sex: MRZ.Sex(rawValue: line2[20]), optionalData: withoutFiller(optional),
                isVerified: verified)
        }, checks: checks)
    }

    private static func parseTD1(_ first: String, _ second: String, _ third: String, today: Date) -> Reading? {
        guard let line1 = Line(first, length: 30), let line2 = Line(second, length: 30),
              let line3 = Line(third, length: 30), isDocumentCode(line1[0]) else { return nil }
        let code = documentCode(line1[0], line1[1])
        var number = documentNumber(line1[5..<14], check: line1[14])
        var upperLine = number.raw + line1[14..<30]
        var optional = line1[15..<30]
        // A number longer than 9 characters continues in the optional data, followed by its check digit.
        if line1[14] == "<", let check = optional.prefix(while: { $0 != "<" }).last {
            let extended = optional.prefix { $0 != "<" }
            number = documentNumber(line1[5..<14] + extended.dropLast(), check: String(check))
            optional = String(optional.dropFirst(extended.count))
            upperLine = line1[5..<30]
        }
        let birth = digits(line2[0..<6])
        let expiry = digits(line2[8..<14])
        let composite = upperLine + birth + line2[6] + expiry + line2[14] + line2[18..<29]
        let checks = [number.isValid, passes(birth, line2[6]), passes(expiry, line2[14]), passes(composite, line2[29])]
        let (surname, givenNames) = names(line3[0..<30])
        return Reading({ verified in
            MRZ(format: .td1, documentCode: code, issuingCountry: country(line1[2..<5]),
                surname: surname, givenNames: givenNames, documentNumber: number.value,
                nationality: country(line2[15..<18]),
                birthDate: date(birth, isBirthDate: true, today: today),
                expiryDate: date(expiry, isBirthDate: false, today: today),
                sex: MRZ.Sex(rawValue: line2[7]),
                optionalData: withoutFiller(optional + line2[18..<29]),
                isVerified: verified)
        }, checks: checks)
    }

    // MARK: - Check digits

    private static func passes(_ text: String, _ checkCharacter: String) -> Bool {
        guard let computed = checkDigit(text), let printed = digit(checkCharacter) else { return false }
        return computed == printed
    }

    private static func value(of character: Character) -> Int? {
        if character == "<" { return 0 }
        guard let ascii = character.asciiValue else { return nil }
        switch ascii {
        case 48...57: return Int(ascii) - 48
        case 65...90: return Int(ascii) - 55
        default: return nil
        }
    }

    // MARK: - Fields

    private struct DocumentNumber {
        /// As printed (after any correction), with filler, for the composite check.
        let raw: String
        let value: String
        let isValid: Bool
    }

    /// The document number, corrected when a single misread letter or digit makes its check digit match.
    private static func documentNumber(_ raw: String, check: String) -> DocumentNumber {
        if passes(raw, check) {
            return DocumentNumber(raw: raw, value: withoutFiller(raw), isValid: true)
        }
        let swaps: [Character: Character] = ["O": "0", "0": "O", "I": "1", "1": "I", "S": "5", "5": "S",
                                             "B": "8", "8": "B", "Z": "2", "2": "Z", "G": "6", "6": "G"]
        var characters = Array(raw)
        for index in characters.indices {
            guard let swap = swaps[characters[index]] else { continue }
            let original = characters[index]
            characters[index] = swap
            let candidate = String(characters)
            if passes(candidate, check) {
                return DocumentNumber(raw: candidate, value: withoutFiller(candidate), isValid: true)
            }
            characters[index] = original
        }
        return DocumentNumber(raw: raw, value: withoutFiller(raw), isValid: false)
    }

    /// Surname and given names from a name field: `ERIKSSON<<ANNA<MARIA<<<<`.
    private static func names(_ field: String) -> (surname: String, givenNames: String) {
        let parts = withoutTrailingFiller(field).components(separatedBy: "<<")
        let surname = words(parts.first ?? "")
        let givenNames = words(parts.dropFirst().joined(separator: "<"))
        return (surname, givenNames)
    }

    private static func words(_ text: String) -> String {
        text.split(separator: "<").map { alphabetic(String($0)) }.joined(separator: " ")
    }

    /// Drops the trailing `<` filler, and the `K`s recognition often reads in it.
    private static func withoutTrailingFiller(_ field: String) -> String {
        var index = field.endIndex
        var fillerStart = field.endIndex
        while index > field.startIndex {
            let previous = field.index(before: index)
            guard field[previous] == "<" || field[previous] == "K" else { break }
            if field[previous] == "<" {
                fillerStart = previous
            }
            index = previous
        }
        return String(field[..<fillerStart])
    }

    private static func withoutFiller(_ text: some StringProtocol) -> String {
        text.split(separator: "<").joined(separator: " ")
    }

    private static func country(_ code: String) -> String {
        alphabetic(code).replacingOccurrences(of: "<", with: "")
    }

    private static func documentCode(_ first: String, _ second: String) -> String {
        second == "<" ? first : first + alphabetic(second)
    }

    private static func isDocumentCode(_ character: String) -> Bool {
        ["P", "I", "A", "C", "V"].contains(character)
    }

    /// "yyyy-MM-dd" from YYMMDD. Birth dates are in the past; expiry dates are this century unless that
    /// would be more than 50 years away.
    private static func date(_ yymmdd: String, isBirthDate: Bool, today: Date) -> String? {
        guard yymmdd.count == 6, yymmdd.allSatisfy(\.isASCII), let yy = Int(yymmdd.prefix(2)),
              let month = Int(yymmdd.dropFirst(2).prefix(2)), let day = Int(yymmdd.suffix(2)) else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let currentYear = calendar.component(.year, from: today)
        var year = 2000 + yy
        if isBirthDate ? year > currentYear : year > currentYear + 50 {
            year -= 100
        }
        guard DateComponents(year: year, month: month, day: day).isValidDate(in: calendar) else { return nil }
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    // MARK: - Recognition fixes

    /// Letters recognition confuses with digits, in a field that holds only digits.
    private static func digits(_ text: String) -> String {
        String(text.map { character -> Character in
            switch character {
            case "O", "Q", "D": "0"
            case "I", "L": "1"
            case "Z": "2"
            case "S": "5"
            case "G": "6"
            case "B": "8"
            default: character
            }
        })
    }

    private static func digit(_ text: String) -> Int? {
        let fixed = digits(text)
        return fixed == "<" ? 0 : Int(fixed)
    }

    /// Digits recognition confuses with letters, in a field that holds only letters.
    private static func alphabetic(_ text: String) -> String {
        String(text.map { character -> Character in
            switch character {
            case "0": "O"
            case "1": "I"
            case "2": "Z"
            case "5": "S"
            case "6": "G"
            case "8": "B"
            default: character
            }
        })
    }

    // MARK: - Finding the lines

    private static let mrzCharacters = Set("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789<")

    /// Uppercase MRZ characters only. `«` is how recognition often reads `<<`.
    private static func normalized(_ line: String) -> String {
        let replaced = line.uppercased()
            .replacingOccurrences(of: "«", with: "<<")
            .replacingOccurrences(of: "‹", with: "<")
        return String(replaced.filter { mrzCharacters.contains($0) })
    }

    /// Zone lines are long and have filler, except a second line whose optional data is full; that one is
    /// mostly digits.
    private static func looksLikeMRZ(_ line: String) -> Bool {
        guard line.count >= 27 else { return false }
        return line.contains("<") || line.filter(\.isNumber).count >= 12
    }

    /// Recognition sometimes returns two zone lines as one.
    private static func splitMerged(_ line: String) -> [String] {
        let compact = normalized(line)
        for length in [44, 36, 30] where abs(compact.count - 2 * length) <= 1 && compact.contains("<") {
            let index = compact.index(compact.startIndex, offsetBy: length)
            return [String(compact[..<index]), String(compact[index...])]
        }
        return [line]
    }

    /// One zone line at exactly its format's length.
    private struct Line {
        private let characters: [Character]

        /// Pads trailing filler that recognition dropped. Nil when the line is too far off the length.
        init?(_ line: String, length: Int) {
            guard (length - 3...length + 1).contains(line.count) else { return nil }
            var line = line
            if line.count < length {
                line += String(repeating: "<", count: length - line.count)
            } else if line.count > length {
                guard line.hasSuffix("<") else { return nil }
                line = String(line.prefix(length))
            }
            characters = Array(line)
        }

        subscript(index: Int) -> String {
            String(characters[index])
        }

        subscript(range: Range<Int>) -> String {
            String(characters[range])
        }
    }
}
