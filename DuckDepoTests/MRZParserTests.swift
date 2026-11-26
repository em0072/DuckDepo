//
//  MRZParserTests.swift
//  DuckDepoTests
//

import Foundation
import Testing
@testable import DuckDepo

struct MRZParserTests {

    /// Sample documents from ICAO 9303 parts 4–6.
    private let passport = ["P<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<<<<<<<<<",
                            "L898902C36UTO7408122F1204159ZE184226B<<<<<10"]
    private let idCard = ["I<UTOD231458907<<<<<<<<<<<<<<<",
                          "7408122F1204159UTO<<<<<<<<<<<6",
                          "ERIKSSON<<ANNA<MARIA<<<<<<<<<<"]
    private let td2 = ["I<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<",
                       "D231458907UTO7408122F1204159<<<<<<<6"]

    private let today: Date = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar.date(from: DateComponents(year: 2026, month: 11, day: 26))!
    }()

    @Test func readsAPassport() throws {
        let mrz = try #require(MRZParser.parse(lines: passport, today: today))
        #expect(mrz.isVerified)
        #expect(mrz.format == .td3)
        #expect(mrz.kind == .passport)
        #expect(mrz.issuingCountry == "UTO")
        #expect(mrz.surname == "ERIKSSON")
        #expect(mrz.givenNames == "ANNA MARIA")
        #expect(mrz.fullName == "Anna Maria Eriksson")
        #expect(mrz.documentNumber == "L898902C3")
        #expect(mrz.nationality == "UTO")
        #expect(mrz.birthDate == "1974-08-12")
        #expect(mrz.expiryDate == "2012-04-15")
        #expect(mrz.sex == .female)
        #expect(mrz.optionalData == "ZE184226B")
    }

    @Test func readsAnIDCard() throws {
        let mrz = try #require(MRZParser.parse(lines: idCard, today: today))
        #expect(mrz.isVerified)
        #expect(mrz.format == .td1)
        #expect(mrz.kind == .idCard)
        #expect(mrz.documentNumber == "D23145890")
        #expect(mrz.fullName == "Anna Maria Eriksson")
        #expect(mrz.birthDate == "1974-08-12")
        #expect(mrz.expiryDate == "2012-04-15")
    }

    @Test func readsATwoLineCard() throws {
        let mrz = try #require(MRZParser.parse(lines: td2, today: today))
        #expect(mrz.isVerified)
        #expect(mrz.format == .td2)
        #expect(mrz.documentNumber == "D23145890")
        #expect(mrz.surname == "ERIKSSON")
    }

    @Test func findsTheZoneAmongOtherTextWithRecognitionMistakes() throws {
        let lines = ["PASSPORT / PASSEPORT", "Surname / Nom", "ERIKSSON", "Date of birth 12 AUG 1974",
                     // Spaces, « for <<, and a K read in the filler.
                     "P<UTO ERIKSSON«ANNA<MARIA<<<<<<K<<<<<<<<<<<<<",
                     // Letter O for the zero in the expiry date.
                     "L898902C36UTO7408122F12O4159ZE184226B<<<<<10"]
        let mrz = try #require(MRZParser.parse(lines: lines, today: today))
        #expect(mrz.isVerified)
        #expect(mrz.givenNames == "ANNA MARIA")
        #expect(mrz.expiryDate == "2012-04-15")
    }

    @Test func correctsAMisreadCharacterInTheNumber() throws {
        // The zero in the number read as the letter O; only the check digit tells which is right.
        let lines = [passport[0], "L8989O2C36UTO7408122F1204159ZE184226B<<<<<10"]
        let mrz = try #require(MRZParser.parse(lines: lines, today: today))
        #expect(mrz.isVerified)
        #expect(mrz.documentNumber == "L898902C3")
    }

    @Test func padsFillerThatRecognitionDropped() throws {
        let lines = ["P<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<<<<<<", passport[1]]
        let mrz = try #require(MRZParser.parse(lines: lines, today: today))
        #expect(mrz.isVerified)
        #expect(mrz.givenNames == "ANNA MARIA")
    }

    @Test func splitsTwoLinesRecognizedAsOne() throws {
        let mrz = try #require(MRZParser.parse(lines: [passport.joined()], today: today))
        #expect(mrz.isVerified)
        #expect(mrz.documentNumber == "L898902C3")
    }

    @Test func returnsAZoneThatFailsACheckAsUnverified() throws {
        // Expiry day 15 misread as 16: the expiry and composite checks fail.
        let lines = [passport[0], "L898902C36UTO7408122F1204169ZE184226B<<<<<10"]
        let mrz = try #require(MRZParser.parse(lines: lines, today: today))
        #expect(!mrz.isVerified)
        #expect(mrz.documentNumber == "L898902C3")
    }

    @Test func ignoresOrdinaryText() {
        let lines = ["KONINKRIJK DER NEDERLANDEN", "Achternaam / Surname / Nom", "Date of expiry 01 JAN 2030",
                     "THISISAVERYLONGLINEOFTEXTWITHOUTANYFILLERATALL"]
        #expect(MRZParser.parse(lines: lines, today: today) == nil)
    }

    @Test func picksTheCenturyFromToday() throws {
        // Born '25 is 2025 (not in the future); born '30 is 1930. Expiring '30 is 2030.
        let born2025 = try #require(MRZParser.parse(lines: makePassport(birth: "250101", expiry: "300101"), today: today))
        #expect(born2025.birthDate == "2025-01-01")
        #expect(born2025.expiryDate == "2030-01-01")
        let born1930 = try #require(MRZParser.parse(lines: makePassport(birth: "300101", expiry: "300101"), today: today))
        #expect(born1930.birthDate == "1930-01-01")
    }

    @Test func checkDigitsFollowICAO() {
        #expect(MRZParser.checkDigit("L898902C3") == 6)
        #expect(MRZParser.checkDigit("740812") == 2)
        #expect(MRZParser.checkDigit("<<<<<") == 0)
        #expect(MRZParser.checkDigit("a12") == nil)
    }

    /// A valid passport zone with the given dates.
    private func makePassport(birth: String, expiry: String) -> [String] {
        let number = "AB1234567"
        let optional = String(repeating: "<", count: 14)
        func check(_ text: String) -> String { String(MRZParser.checkDigit(text)!) }
        let body = number + check(number) + "NLD" + birth + check(birth) + "M" + expiry + check(expiry)
            + optional + check(optional)
        let composite = number + check(number) + birth + check(birth) + expiry + check(expiry) + optional + check(optional)
        return ["P<NLDDE<VRIES<<JAN<<<<<<<<<<<<<<<<<<<<<<<<<<", body + check(composite)]
    }
}
