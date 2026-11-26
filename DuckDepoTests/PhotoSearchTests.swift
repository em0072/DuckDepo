//
//  PhotoSearchTests.swift
//  DuckDepoTests
//

import Foundation
import Testing
import UIKit
@testable import DuckDepo

struct PhotoTextIndexTests {

    private let passport = PhotoTextIndex.Key(documentID: UUID(), photoID: UUID())
    private let card = PhotoTextIndex.Key(documentID: UUID(), photoID: UUID())

    @Test func findsDocumentsByPhotoTextIgnoringCaseAndAccents() {
        let index = PhotoTextIndex(fileURL: nil)
        index.set("PASSEPORT\nNom: MÜLLER\nNo. AB1234567", for: passport)
        index.set("Zorgpas\nPolis 123456789", for: card)
        #expect(Set(index.matches("muller").keys) == [passport.documentID])
        #expect(Set(index.matches("123456789").keys) == [card.documentID])
        #expect(index.matches("zebra").isEmpty)
        #expect(index.matches("  ").isEmpty)
    }

    @Test func excerptsAreOneLineAroundTheMatch() {
        let text = String(repeating: "a ", count: 30) + "POLICY 123456789\nValid until 2027" + String(repeating: " b", count: 40)
        let excerpt = PhotoTextIndex.excerpt(of: text, around: text.range(of: "123456789")!)
        #expect(excerpt.hasPrefix("…"))
        #expect(excerpt.hasSuffix("…"))
        #expect(excerpt.contains("POLICY 123456789 Valid until 2027"))
        #expect(!excerpt.contains("\n"))
    }

    @Test func forgetsPhotosThatAreGone() {
        let index = PhotoTextIndex(fileURL: nil)
        index.set("one", for: passport)
        index.set("two", for: card)
        #expect(index.removeEntries(notIn: [card]))
        #expect(index.keys == [card])
        #expect(!index.removeEntries(notIn: [card]))
    }

    @Test func savesAndLoadsItsFile() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("index.json")
        let index = PhotoTextIndex(fileURL: url)
        index.set("Polis 123456789", for: card)
        index.save()
        let reloaded = PhotoTextIndex(fileURL: url)
        #expect(reloaded.text(for: card) == "Polis 123456789")
        try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
    }
}

@MainActor
struct PhotoIndexerTests {

    private let database = TestStack.makeDatabase()
    private let index = PhotoTextIndex(fileURL: nil)

    /// The whole path: a photo saved with a document, read by Vision, found by search.
    @Test func readsNewPhotosAndSearchFindsTheirDocument() async throws {
        let image = ScanPipelineTests.render([("ZORGPAS", 40, false), ("Polis 123456789", 36, false)])
        let photo = try #require(DocumentPhoto(image: image))
        let document = Document(name: "Health Insurance", photos: [photo])
        #expect(database.save(document))

        let indexer = PhotoIndexer(database: database, index: index)
        await indexer.indexMissingPhotos()
        let key = PhotoTextIndex.Key(documentID: document.id, photoID: photo.id)
        #expect(index.text(for: key)?.contains("123456789") == true)

        let search = SearchViewModel(database: database, keychain: InMemoryKeychain(), photoText: index)
        search.start()
        search.query = "123456789"
        #expect(search.documentResults.map(\.id) == [document.id])
        #expect(search.photoMatches[document.id]?.contains("123456789") == true)

        // A name match needs no excerpt.
        search.query = "Health"
        #expect(search.documentResults.map(\.id) == [document.id])
        #expect(search.photoMatches.isEmpty)

        // Gone with its document.
        _ = database.delete(document)
        await indexer.indexMissingPhotos()
        #expect(index.keys.isEmpty)
    }
}
