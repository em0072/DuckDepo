//
//  StorageTests.swift
//  DuckDepoTests
//

import CoreData
import Testing
@testable import DuckDepo

@MainActor
struct DocumentStorageTests {

    private let database = TestStack.makeDatabase()

    private func makeDocument() -> Document {
        Document(name: "Passport", description: "Jane", documentType: .identification,
                 photos: [.sample(), .sample(width: 20, height: 50)],
                 sections: [DocSection(name: "Document Info", fields: [Field(title: "Number", value: "123"),
                                                                       Field(title: "Issued By")])])
    }

    @Test func roundTripKeepsEmptyFieldsAndPhotoBytes() throws {
        let document = makeDocument()
        #expect(database.save(document))

        let loaded = try #require(database.fullDocument(with: document.id))

        #expect(loaded.name == "Passport")
        #expect(loaded.sections.first?.fields.map(\.title) == ["Number", "Issued By"])
        #expect(loaded.photos.map(\.data) == document.photos.map(\.data))
    }

    @Test func listItemsDoNotDecodePhotos() throws {
        #expect(database.save(makeDocument()))
        let storage = DocumentsStorage(database: database)
        let item = try #require(storage.documents.value.first)
        #expect(item.photos.isEmpty)
    }

    /// Photos used to be re-encoded at JPEG quality 0.3 on every save.
    @Test func editingTextDoesNotRewritePhotos() throws {
        let document = makeDocument()
        #expect(database.save(document))
        let stored = try #require(database.fetchFromDB(document))
        let before = stored.photoData

        var edited = try #require(database.fullDocument(with: document.id))
        edited.name = "Passport (renewed)"
        stored.setPhotos(edited.photos)
        #expect(stored.changedValues()["photoData"] == nil)

        #expect(database.update(edited))
        #expect(stored.photoData == before)
    }

    @Test func deletingAPhotoKeepsTheOthersUnchanged() throws {
        let document = makeDocument()
        #expect(database.save(document))
        var edited = try #require(database.fullDocument(with: document.id))
        let kept = edited.photos[1].data
        edited.photos.remove(at: 0)

        #expect(database.update(edited))

        let loaded = try #require(database.fullDocument(with: document.id))
        #expect(loaded.photos.map(\.data) == [kept])
    }
}

@MainActor
struct PasswordsStorageTests {

    private let database = TestStack.makeDatabase()
    private let keychain = InMemoryKeychain()

    private func makeStorage() -> PasswordsStorage {
        PasswordsStorage(database: database, keychain: keychain, identityStore: nil)
    }

    @Test func savesValueInKeychainAndListsWithoutIt() throws {
        let storage = makeStorage()
        storage.startObserving()
        let password = Password(name: "Mail", login: "me", value: "s3cret", website: "mail.example")

        #expect(storage.save(password))

        #expect(keychain.items[password.id.uuidString] == "s3cret")
        let listed = try #require(storage.passwords.value.first)
        #expect(listed.id == password.id)
        #expect(listed.value == "")
        #expect(storage.value(for: password.id) == "s3cret")
    }

    @Test func updateKeepsOneRecord() {
        let storage = makeStorage()
        var password = Password(name: "Mail", value: "one")
        #expect(storage.save(password))
        password.value = "two"
        password.name = "Mail (work)"

        #expect(storage.save(password))

        #expect(storage.count() == 1)
        #expect(storage.fetch(with: password.id)?.name == "Mail (work)")
        #expect(storage.value(for: password.id) == "two")
    }

    @Test func failedKeychainWriteSavesNothing() {
        keychain.failWrites = true
        let storage = makeStorage()

        #expect(!storage.save(Password(name: "Mail", value: "x")))
        #expect(storage.count() == 0)
    }

    @Test func deleteRemovesKeychainValue() {
        let storage = makeStorage()
        let password = Password(name: "Mail", value: "x")
        #expect(storage.save(password))

        storage.delete(password)

        #expect(storage.count() == 0)
        #expect(keychain.items.isEmpty)
    }
}
