//
//  ListAndExpiryTests.swift
//  DuckDepoTests
//

import Foundation
import Testing
@testable import DuckDepo

struct ExpiryStatusTests {

    /// A time zone far from UTC, so a wrong day boundary shows up.
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return calendar
    }()

    private func expiry(_ storedValue: String) -> Date {
        FieldDate.utcDate(from: storedValue)!
    }

    private func localTime(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    @Test func theExpiryDayItselfIsStillValid() {
        let status = ExpiryStatus(expiryDate: expiry("2027-03-10"), today: localTime(2027, 3, 10), calendar: calendar)
        #expect(status == .expiresSoon(days: 0))
    }

    @Test func theDayAfterIsExpired() {
        let status = ExpiryStatus(expiryDate: expiry("2027-03-10"), today: localTime(2027, 3, 11, hour: 0), calendar: calendar)
        #expect(status == .expired)
    }

    /// 23:00 on 9 March in Los Angeles is already 10 March in UTC; it still counts as 9 March.
    @Test func usesTheLocalDayLateInTheEvening() {
        let status = ExpiryStatus(expiryDate: expiry("2027-03-10"), today: localTime(2027, 3, 9, hour: 23), calendar: calendar)
        #expect(status == .expiresSoon(days: 1))
    }

    @Test func flagsOnlyDocumentsWithinTheThreshold() {
        let today = localTime(2027, 1, 1)
        let edge = calendar.date(byAdding: .day, value: ExpiryStatus.soonThreshold, to: today)!
        let edgeValue = FieldDate.storedValue(fromLocalDate: edge, calendar: calendar)!
        #expect(ExpiryStatus(expiryDate: expiry(edgeValue), today: today, calendar: calendar)
                == .expiresSoon(days: ExpiryStatus.soonThreshold))
        let later = calendar.date(byAdding: .day, value: 1, to: edge)!
        let laterValue = FieldDate.storedValue(fromLocalDate: later, calendar: calendar)!
        #expect(ExpiryStatus(expiryDate: expiry(laterValue), today: today, calendar: calendar) == .valid)
        #expect(ExpiryStatus.valid.badgeText == nil)
    }

    @Test func documentExpiryComesFromItsExpiryDateField() {
        var field = FieldKey.expiryDate.makeField()
        field.value = "2000-01-31"
        let document = Document(name: "Old Passport", sections: [DocSection(name: "Info", fields: [field])])
        #expect(document.expiryStatus == .expired)
        #expect(Document(name: "No Expiry").expiryStatus == nil)
    }

    @Test func predefinedSectionsStartWithTheirUsualFields() {
        let section = SectionKey.documentInfo.makeSection()
        #expect(section.fields.compactMap(\.fieldKey) == SectionKey.documentInfo.fields)
        #expect(section.fields.allSatisfy { $0.value.isEmpty })
        #expect(section.missingPredefinedFields.isEmpty)
    }

    /// Stored days are Gregorian whatever calendar the user picked in Settings.
    @Test func dateFieldsConvertWithTheGregorianCalendar() {
        #expect(FieldDate.localCalendar.identifier == .gregorian)
        let date = FieldDate.localDate(from: "2027-03-10")!
        #expect(FieldDate.storedValue(fromLocalDate: date) == "2027-03-10")
    }
}

struct DocumentSearchTests {

    private let documents = [
        Document(name: "Passport", description: "Jane Doe", documentType: .identification,
                 sections: [DocSection(name: "Document Info", fields: [Field(title: "Number", value: "AB 1234")])]),
        Document(name: "Car", description: "Ford", documentType: .transport),
        Document(name: "Résumé", documentType: .work),
        Document(name: "ID Card", documentType: .identification),
    ]

    @Test func groupsByTypeInListOrderAndKeepsTheOrderWithinAType() {
        let groups = DocumentSearch.groups(for: documents, matching: "")
        #expect(groups.map(\.type) == [.identification, .transport, .work])
        #expect(groups[0].documents.map(\.name) == ["Passport", "ID Card"])
    }

    @Test func findsFieldValues() {
        let groups = DocumentSearch.groups(for: documents, matching: "ab 12")
        #expect(groups.flatMap(\.documents).map(\.name) == ["Passport"])
    }

    @Test func ignoresCaseAndDiacritics() {
        let groups = DocumentSearch.groups(for: documents, matching: "RESUME")
        #expect(groups.flatMap(\.documents).map(\.name) == ["Résumé"])
    }

    @Test func noMatchMeansNoGroups() {
        #expect(DocumentSearch.groups(for: documents, matching: "zebra").isEmpty)
    }
}

struct PasswordSearchTests {

    private let password = Password(name: "Github", login: "jane@example.com", website: "github.com")

    @Test func matchesNameLoginOrWebsite() {
        #expect(password.matches("git"))
        #expect(password.matches("JANE@"))
        #expect(password.matches("hub.com"))
        #expect(!password.matches("gitlab"))
    }

    @Test func blankQueryMatchesEverything() {
        #expect(password.matches(""))
        #expect(password.matches("  "))
    }
}

@MainActor
struct DocumentListTests {

    private let database = TestStack.makeDatabase()

    @Test func listItemsCarryTheFirstPhotosThumbnailButNoPhotos() throws {
        let first = DocumentPhoto.sample(color: .red)
        let second = DocumentPhoto.sample(color: .blue)
        #expect(database.save(Document(name: "Passport", photos: [first, second])))

        let item = try #require(DocumentsStorage(database: database).documents.value.first)

        #expect(item.photos.isEmpty)
        #expect(item.thumbnail?.id == first.id)
        #expect(item.thumbnail?.data.isEmpty == false)
    }

    @Test func deletingFromTheListRemovesTheDocument() {
        let document = Document(name: "Passport")
        #expect(database.save(document))
        let viewModel = DepoListViewModel(database: database)
        viewModel.start()
        #expect(viewModel.documents.count == 1)

        viewModel.delete(document)

        #expect(viewModel.documents.isEmpty)
        #expect(database.fetchDocumentCount() == 0)
    }
}
