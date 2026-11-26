//
//  DataModelV3Tests.swift
//  DuckDepoTests
//

import CoreData
import Foundation
import Testing
@testable import DuckDepo

struct FieldDateTests {

    @Test(arguments: [
        ("2032-02-01", "2032-02-01"),
        ("01.02.2032", "2032-02-01"),
        ("1.2.2032", "2032-02-01"),
        (" 13/02/2032 ", "2032-02-13"),
        ("02/13/2032", "2032-02-13"),
        ("13-02-2032", "2032-02-13"),
    ])
    func readsUnambiguousDates(text: String, expected: String) {
        #expect(FieldDate.parseLegacy(text) == expected)
    }

    @Test(arguments: ["01/02/2032", "31.02.2032", "2032-13-01", "1 Feb 2032", "", "12.2032", "01.02.32"])
    func leavesAmbiguousOrInvalidTextAlone(text: String) {
        #expect(FieldDate.parseLegacy(text) == nil)
    }

    /// The stored day must not shift with the device's time zone.
    @Test func dayIsTheSameInEveryTimeZone() throws {
        for identifier in ["Pacific/Kiritimati", "Pacific/Pago_Pago", "Europe/Amsterdam"] {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = try #require(TimeZone(identifier: identifier))
            let picked = try #require(FieldDate.localDate(from: "2032-02-01", calendar: calendar))
            #expect(FieldDate.storedValue(fromLocalDate: picked, calendar: calendar) == "2032-02-01")
        }
    }

    @Test func showsTheDayInTheUsersFormat() {
        #expect(FieldDate.displayString(for: "2032-02-01", locale: Locale(identifier: "en_US")) == "February 1, 2032")
        #expect(FieldDate.displayString(for: "not a date") == "not a date")
    }
}

struct FieldCatalogTests {

    @Test func matchesNamesInEveryLanguageAndFormerSpellings() {
        #expect(FieldCatalog.sectionKey(forStoredName: "Document Info") == .documentInfo)
        #expect(FieldCatalog.sectionKey(forStoredName: "Информация о документе") == .documentInfo)
        #expect(FieldCatalog.sectionKey(forStoredName: "Vehical Info") == .vehicle)
        #expect(FieldCatalog.fieldKey(forStoredTitle: "  date of expiry ") == .expiryDate)
        #expect(FieldCatalog.fieldKey(forStoredTitle: "Действителен до") == .expiryDate)
        #expect(FieldCatalog.fieldKey(forStoredTitle: "Идентификацилонный номер (VIN)") == .vin)
        #expect(FieldCatalog.fieldKey(forStoredTitle: "My own field") == nil)
    }

    @Test func everyPredefinedNameIsTranslated() {
        for key in FieldKey.allCases {
            for localization in ["en", "ru"] {
                let bundle = Bundle(path: Bundle.main.path(forResource: localization, ofType: "lproj")!)!
                let name = bundle.localizedString(forKey: key.localizationKey, value: "MISSING", table: nil)
                #expect(name != "MISSING", "\(key) has no \(localization) name")
            }
        }
    }
}

@MainActor
struct DataModelMigrationTests {

    private let database = TestStack.makeDatabase()
    private let keychain = InMemoryKeychain()
    private var context: NSManagedObjectContext { database.context }

    /// A document as version 2.6 stores it: names in the language of the time, dates as text, photos in `photoData`.
    private func makeLegacyDocument(photos: [DocumentPhoto] = [], expiry: String = "01.02.2032") -> DDDocument {
        let document = DDDocument(context: context)
        document.identifier = UUID()
        document.name = "Паспорт"
        document.setPhotosLikeVersion26(photos)
        let section = DDSection(context: context)
        section.name = "Информация о документе"
        section.document = document
        for (index, (title, value)) in [("Номер", "12 34"), ("Действителен до", expiry), ("Дата выдачи", "01/02/2022")].enumerated() {
            let field = DDField(context: context)
            field.title = title
            field.value = value
            field.order = Int32(index)
            field.section = section
        }
        #expect(database.save())
        return document
    }

    private func migrate() -> LegacyDataMigration.Result {
        LegacyDataMigration.run(in: context, keychain: keychain)
    }

    @Test func keysNamesAndConvertsUnambiguousDates() throws {
        let document = makeLegacyDocument()

        let result = migrate()

        #expect(result.assignedSectionKeys == 1)
        #expect(result.assignedFieldKeys == 3)
        #expect(result.convertedDates == 1)
        let converted = document.convert(includePhotos: false)
        let section = try #require(converted.sections.first)
        #expect(section.sectionKey == .documentInfo)
        let fields = Dictionary(uniqueKeysWithValues: section.fields.compactMap { field in field.fieldKey.map { ($0, field) } })
        #expect(fields[.expiryDate]?.value == "2032-02-01")
        #expect(fields[.expiryDate]?.type == .date)
        // 01/02/2022 could be January or February: kept as typed.
        #expect(fields[.issueDate]?.value == "01/02/2022")
        #expect(fields[.issueDate]?.type == .string)
        #expect(document.expiresAt == FieldDate.utcDate(from: "2032-02-01"))
    }

    @Test func secondRunChangesNothing() {
        _ = makeLegacyDocument(photos: [.sample(color: .red), .sample(color: .blue)])
        #expect(migrate().didChange)
        #expect(!migrate().didChange)
    }

    @Test func convertsOldPhotosToRecordsInOrder() {
        let photos: [DocumentPhoto] = [.sample(color: .red), .sample(color: .blue)]
        let document = makeLegacyDocument(photos: photos)

        #expect(migrate().convertedPhotoDocuments == 1)

        let records = document.photoRecordList()
        #expect(records.compactMap(\.identifier) == photos.map(\.id))
        #expect(records.allSatisfy { $0.thumbnailData != nil })
        #expect(document.photos().map(\.id) == photos.map(\.id))
        // The copy for version 2.6 is left in place.
        #expect(document.photoDataItems() == photos.map(\.data))
    }

    /// Two devices converting the same document at once each create a record per photo. After sync both
    /// sets exist; every device must delete the same extra copies.
    @Test func removesTheSameDuplicateOnEveryDevice() throws {
        let photo = DocumentPhoto.sample(color: .red)
        let document = makeLegacyDocument(photos: [photo])
        _ = migrate()
        let original = try #require(document.photoRecordList().first)
        let copy = DDPhoto(context: context, photo: photo, order: 0, document: document)
        #expect(database.save())
        let expectedSurvivor = [original, copy].min { $0.instanceID!.uuidString < $1.instanceID!.uuidString }

        #expect(migrate().removedDuplicatePhotos == 1)

        #expect(document.photoRecords?.count == 1)
        #expect(document.photoRecords?.first === expectedSurvivor)
    }

    @Test func picksUpPhotosChangedByVersion26() {
        let document = makeLegacyDocument(photos: [.sample(color: .red), .sample(color: .blue)])
        _ = migrate()

        let changed: [DocumentPhoto] = [.sample(color: .green)]
        document.setPhotosLikeVersion26(changed)
        #expect(database.save())
        // Shown right away, before the next migration.
        #expect(document.photos().map(\.id) == changed.map(\.id))

        #expect(migrate().convertedPhotoDocuments == 1)
        #expect(document.photoRecordList().compactMap(\.identifier) == changed.map(\.id))
    }

    @Test func showsOldPhotosUntilRecordsArriveFromICloud() throws {
        let photos: [DocumentPhoto] = [.sample(color: .red)]
        let document = makeLegacyDocument(photos: photos)
        _ = migrate()
        // Another device converted the photos; this one has the document but not the records yet.
        for record in document.photoRecords ?? [] {
            context.delete(record)
        }
        #expect(database.save())

        #expect(document.photos().map(\.id) == photos.map(\.id))
    }
}

@MainActor
struct PhotoStorageTests {

    private let database = TestStack.makeDatabase()

    @Test func savesRecordsAndTheCopyForVersion26() throws {
        let photos: [DocumentPhoto] = [.sample(color: .red), .sample(color: .blue)]
        var document = Document(name: "Passport", photos: photos)
        #expect(database.save(document))
        let stored = try #require(database.fetchFromDB(document))
        #expect(stored.photoRecordList().compactMap(\.identifier) == photos.map(\.id))
        #expect(stored.photoDataItems() == photos.map(\.data))
        #expect(stored.legacyPhotosKey == DDDocument.legacyPhotosKey(for: photos.map(\.data)))

        let kept = photos[1]
        let keptRecord = try #require(stored.photoRecordList().last)
        document.photos = [kept]
        #expect(database.update(document))

        // The remaining photo keeps its record (no new upload) and moves to the front.
        #expect(stored.photoRecordList() == [keptRecord])
        #expect(keptRecord.order == 0)
        #expect(stored.photoDataItems() == [kept.data])
        #expect(database.fullDocument(with: document.id)?.photos.map(\.id) == [kept.id])
    }

    @Test func removingAllPhotosClearsBothCopies() throws {
        var document = Document(name: "Passport", photos: [.sample(color: .red)])
        #expect(database.save(document))
        document.photos = []
        #expect(database.update(document))

        let stored = try #require(database.fetchFromDB(document))
        #expect(stored.photoRecords?.isEmpty ?? true)
        #expect(stored.photoData == nil)
        #expect(stored.legacyPhotosKey == nil)
    }

    @Test func recordsDatesAndExpiry() throws {
        var expiry = FieldKey.expiryDate.makeField()
        expiry.value = "2032-02-01"
        let document = Document(name: "Passport", sections: [DocSection(key: SectionKey.documentInfo.rawValue, name: "Document Info", fields: [expiry])])
        #expect(database.save(document))

        let stored = try #require(database.fetchFromDB(document))
        #expect(stored.createdAt != nil)
        #expect(stored.updatedAt != nil)
        #expect(stored.expiresAt == FieldDate.utcDate(from: "2032-02-01"))
        let converted = stored.convert(includePhotos: false)
        #expect(converted.sections.first?.fields.first?.fieldKey == .expiryDate)
    }
}
