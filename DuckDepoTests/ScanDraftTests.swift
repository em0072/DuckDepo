//
//  ScanDraftTests.swift
//  DuckDepoTests
//

import Foundation
import Testing
@testable import DuckDepo

struct ScanDraftTests {

    private let today: Date = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar.date(from: DateComponents(year: 2026, month: 11, day: 26))!
    }()

    private func draft(_ lines: [String]) async -> ScanDraft {
        let reading = await DocumentScanner.reading(from: lines, today: today, useModel: false)
        return DocumentScanner.makeDraft(from: reading, photos: [])
    }

    private func field(_ key: FieldKey, in draft: ScanDraft) -> Field? {
        draft.document.sections.flatMap(\.fields).first { $0.fieldKey == key }
    }

    @Test func aPassportBecomesAnIdentificationDocumentWithVerifiedFields() async throws {
        let draft = await draft(["P<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<<<<<<<<<",
                                 "L898902C36UTO7408122F1204159ZE184226B<<<<<10"])
        #expect(draft.document.name == String(localized: "scan_kind_passport"))
        #expect(draft.document.description == "Anna Maria Eriksson")
        #expect(draft.document.documentType == .identification)
        #expect(draft.document.sections.compactMap(\.sectionKey) == [.documentInfo, .owner])
        let number = try #require(field(.number, in: draft))
        #expect(number.value == "L898902C3")
        #expect(draft.confidence[number.id] == .verified)
        #expect(field(.expiryDate, in: draft)?.value == "2012-04-15")
        #expect(field(.dateOfBirth, in: draft)?.value == "1974-08-12")
        #expect(field(.sex, in: draft)?.value == "F")
        // "UTO" is ICAO's sample country, not a real one, so it stays a code.
        #expect(field(.nationality, in: draft)?.value == "UTO")
        // Fields the zone doesn't have stay empty for the user to fill in.
        let issueDate = try #require(field(.issueDate, in: draft))
        #expect(issueDate.value.isEmpty)
        #expect(draft.confidence[issueDate.id] == nil)
        #expect(!draft.isEmpty)
    }

    @Test func aDrivingLicenceIsTransportWithReadFields() async throws {
        let draft = await draft(["RIJBEWIJS", "1. De Vries", "2. Jan Pieter", "3. 15.04.1985 Amsterdam",
                                 "4a. 23.03.2023 4c. Gemeente Rotterdam", "4b. 23.03.2033", "5. 5123456789"])
        #expect(draft.document.name == String(localized: "scan_kind_driving_licence"))
        #expect(draft.document.documentType == .transport)
        #expect(draft.document.description == "Jan Pieter De Vries")
        let issuedBy = try #require(field(.issuedBy, in: draft))
        #expect(issuedBy.value == "Gemeente Rotterdam")
        #expect(draft.confidence[issuedBy.id] == .read)
        #expect(field(.placeOfBirth, in: draft)?.value == "Amsterdam")
        #expect(draft.document.expiryDate == FieldDate.utcDate(from: "2033-03-23"))
    }

    @Test func nothingReadLeavesAnEmptyDraft() async {
        let draft = await draft(["Some text", "that isn't a document"])
        #expect(draft.isEmpty)
        #expect(draft.document.name.isEmpty)
        #expect(draft.document.sections.isEmpty)
        #expect(draft.document.documentType == .other)
    }

    @Test func modelValuesAreKeptOnlyWhenPrinted() {
        let text = "ZORGPAS\nHealth Insurance Card\nJ. P. de Vries\nPolicy 123456789\nValid until 31-12-2027"
        let model = ModelReading(title: "Health Insurance Card", category: .medicine, holderName: "J. P. de Vries",
                                 documentNumber: "123456789", issueDate: "", expiryDate: "2027-12-31",
                                 issuedBy: "Acme Health", dateOfBirth: "1985-04-15", placeOfBirth: "",
                                 nationality: "Dutch", sex: "", licencePlate: "", vin: "", make: "", model: "")
        var reading = ScanReading()
        reading.add(model, text: text)
        #expect(reading.modelTitle == "Health Insurance Card")
        #expect(reading.modelCategory == .medicine)
        #expect(reading.holderName == ScanReading.Value(text: "J. P. de Vries", confidence: .suggested))
        #expect(reading.values[.number]?.text == "123456789")
        #expect(reading.values[.expiryDate]?.text == "2027-12-31")
        // Not printed: made up by the model, so dropped.
        #expect(reading.values[.issuedBy] == nil)
        #expect(reading.values[.dateOfBirth] == nil)
        #expect(reading.values[.nationality] == nil)
    }

    /// What the model really answered for an insurance card, with its fields optional.
    @Test func aTitleTheModelMadeUpIsDroppedWithItsCategory() {
        let text = "ZORGPAS\nZilveren Kruis\nNaam: J.P. de Vries\nRelatienummer 123456789\nGeldig tot 31-12-2027"
        let model = ModelReading(title: "Identification", category: .identification, holderName: "J.P. de Vries",
                                 documentNumber: "123456789", issueDate: "2024-01-01", expiryDate: "2027-12-31",
                                 issuedBy: "Zilveren Kruis", dateOfBirth: nil, placeOfBirth: nil, nationality: nil,
                                 sex: nil, licencePlate: nil, vin: nil, make: nil, model: nil)
        var reading = ScanReading()
        reading.add(model, text: text)
        #expect(reading.modelTitle == nil)
        #expect(reading.modelCategory == nil)
        #expect(reading.values[.issueDate] == nil)
        #expect(reading.values[.expiryDate]?.text == "2027-12-31")
        #expect(reading.values[.issuedBy]?.text == "Zilveren Kruis")
    }

    @Test func modelValuesDontReplaceParsedOnes() {
        var reading = ScanReading()
        reading.fill(.number, "L898902C3", .verified)
        let model = ModelReading(title: "Passport", category: .identification, holderName: "", documentNumber: "L898902",
                                 issueDate: "", expiryDate: "", issuedBy: "", dateOfBirth: "", placeOfBirth: "",
                                 nationality: "", sex: "", licencePlate: "", vin: "", make: "", model: "")
        reading.add(model, text: "L898902C3 L898902")
        #expect(reading.values[.number] == ScanReading.Value(text: "L898902C3", confidence: .verified))
    }

    @Test func findsAVehicleIdentificationNumber() {
        #expect(DocumentScanner.vin(in: ["Make: Volkswagen", "VIN: WVWZZZ1KZAW123456"]) == "WVWZZZ1KZAW123456")
        #expect(DocumentScanner.vin(in: ["THISISNOTAVINNUMB"]) == nil)
    }

    @Test func recognizesMostlyCyrillicText() {
        #expect(ModelExtractor.isMostlyCyrillic("ПАСПОРТ Российская Федерация Иванов"))
        #expect(!ModelExtractor.isMostlyCyrillic("PASSPORT Kingdom of the Netherlands"))
    }
}
