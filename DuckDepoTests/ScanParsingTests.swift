//
//  ScanParsingTests.swift
//  DuckDepoTests
//

import Foundation
import Testing
@testable import DuckDepo

private let today: Date = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar.date(from: DateComponents(year: 2026, month: 11, day: 26))!
}()

struct ScanDatesTests {

    private func date(_ text: String, _ tense: ScanDates.Tense = .past) -> String? {
        ScanDates.firstDate(in: text, tense: tense, today: today)?.value
    }

    @Test func readsDayFirstDates() {
        #expect(date("15.04.1985") == "1985-04-15")
        #expect(date("Issued 1/2/2020 in Utrecht") == "2020-02-01")
        #expect(date("1985-04-15") == "1985-04-15")
    }

    @Test func readsMonthFirstWhenTheSecondNumberCantBeAMonth() {
        #expect(date("04/25/2020") == "2020-04-25")
    }

    @Test func picksTheCenturyOfTwoDigitYearsByTense() {
        #expect(date("05/12/30", .future) == "2030-12-05")
        #expect(date("05/12/30", .past) == "1930-12-05")
        #expect(date("05/12/26", .past) == "2026-12-05")
    }

    @Test func skipsImpossibleDatesAndLongerNumbers() {
        #expect(date("31.02.2020") == nil)
        #expect(date("123.04.2020") == nil)
        #expect(date("31.02.2020 or 01.03.2020") == "2020-03-01")
    }
}

struct DrivingLicenceParserTests {

    private let dutchLicence = ["RIJBEWIJS", "KONINKRIJK DER NEDERLANDEN",
                                "1. De Vries", "2. Jan Pieter", "3. 15.04.1985 Amsterdam",
                                "4a. 23.03.2023 4c. Gemeente Rotterdam", "4b. 23.03.2033",
                                "5. 5123456789", "9. AM/B"]

    @Test func readsTheNumberedFields() throws {
        let licence = try #require(DrivingLicenceParser.parse(lines: dutchLicence, today: today))
        #expect(licence.surname == "De Vries")
        #expect(licence.givenNames == "Jan Pieter")
        #expect(licence.fullName == "Jan Pieter De Vries")
        #expect(licence.birthDate == "1985-04-15")
        #expect(licence.birthPlace == "Amsterdam")
        #expect(licence.issueDate == "2023-03-23")
        #expect(licence.expiryDate == "2033-03-23")
        #expect(licence.authority == "Gemeente Rotterdam")
        #expect(licence.number == "5123456789")
        #expect(licence.categories == "AM/B")
    }

    @Test func takesAValuePrintedOnTheNextLine() throws {
        let lines = ["1.", "MITKO", "2.", "EVGENY", "4b 01.06.2031", "5.12 345 678"]
        let licence = try #require(DrivingLicenceParser.parse(lines: lines, today: today))
        #expect(licence.surname == "MITKO")
        #expect(licence.givenNames == "EVGENY")
        #expect(licence.expiryDate == "2031-06-01")
        #expect(licence.number == "12345678")
    }

    /// Automatic language detection read the "a" in "4a." as the Cyrillic "а".
    @Test func acceptsACyrillicLookAlikeInTheFieldNumber() throws {
        let lines = ["1. De Vries", "2. Jan Pieter", "4\u{0430}. 23.03.2023", "4b. 23.03.2033", "5.5123456789"]
        let licence = try #require(DrivingLicenceParser.parse(lines: lines, today: today))
        #expect(licence.issueDate == "2023-03-23")
        #expect(licence.number == "5123456789")
    }

    @Test func readsARussianLicence() throws {
        let lines = ["ВОДИТЕЛЬСКОЕ УДОСТОВЕРЕНИЕ", "1. ИВАНОВ IVANOV", "2. ИВАН ИВАНОВИЧ IVAN IVANOVICH",
                     "3. 01.02.1990 МОСКВА MOSKVA", "4a) 05.06.2020 4b) 05.06.2030", "4c) ГИБДД 7701 GIBDD 7701",
                     "5. 77 12 345678"]
        let licence = try #require(DrivingLicenceParser.parse(lines: lines, today: today))
        #expect(licence.surname == "ИВАНОВ IVANOV")
        #expect(licence.birthDate == "1990-02-01")
        #expect(licence.birthPlace == "МОСКВА MOSKVA")
        #expect(licence.issueDate == "2020-06-05")
        #expect(licence.expiryDate == "2030-06-05")
        #expect(licence.authority == "ГИБДД 7701 GIBDD 7701")
        #expect(licence.number == "7712345678")
    }

    @Test func ignoresNumberedListsThatArentALicence() {
        #expect(DrivingLicenceParser.parse(lines: ["1. Milk", "2. Eggs", "3. Bread"], today: today) == nil)
        #expect(DrivingLicenceParser.parse(lines: ["PASSPORT", "Surname", "Given names"], today: today) == nil)
    }
}
