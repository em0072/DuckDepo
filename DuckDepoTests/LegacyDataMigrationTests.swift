//
//  LegacyDataMigrationTests.swift
//  DuckDepoTests
//

import CoreData
import Testing
@testable import DuckDepo

@MainActor
struct LegacyDataMigrationTests {

    private let database = TestStack.makeDatabase()
    private let keychain = InMemoryKeychain()

    private var context: NSManagedObjectContext { database.context }

    @discardableResult
    private func insertPassword(id: UUID?, legacyValue: String) throws -> DDPassword {
        let password = DDPassword(context: context)
        password.id = id
        password.name = "Bank"
        password.value = legacyValue
        try context.save()
        return password
    }

    @Test func movesVersion1ValueIntoKeychain() throws {
        let password = try insertPassword(id: nil, legacyValue: "hunter2")

        let result = LegacyDataMigration.run(in: context, keychain: keychain)

        let id = try #require(password.id)
        #expect(keychain.items[id.uuidString] == "hunter2")
        #expect(password.value == "")
        #expect(result.assignedPasswordIDs == 1)
        #expect(result.movedPasswordValues == 1)
    }

    /// The old migration re-ran on new installs, gave passwords new IDs and wrote the old value back.
    @Test func keepsIDAndNewerKeychainValue() throws {
        let id = UUID()
        keychain.items[id.uuidString] = "edited-later"
        let password = try insertPassword(id: id, legacyValue: "old-v1-value")

        LegacyDataMigration.run(in: context, keychain: keychain)

        #expect(password.id == id)
        #expect(keychain.items[id.uuidString] == "edited-later")
        #expect(password.value == "")
    }

    @Test func secondRunDoesNothing() throws {
        try insertPassword(id: nil, legacyValue: "hunter2")
        LegacyDataMigration.run(in: context, keychain: keychain)

        let second = LegacyDataMigration.run(in: context, keychain: keychain)

        #expect(second == LegacyDataMigration.Result())
    }

    @Test func keepsLegacyValueWhenKeychainWriteFails() throws {
        keychain.failWrites = true
        let password = try insertPassword(id: UUID(), legacyValue: "hunter2")

        LegacyDataMigration.run(in: context, keychain: keychain)

        #expect(password.value == "hunter2")
    }

    @Test func assignsMissingDocumentIdentifiers() throws {
        let document = DDDocument(context: context)
        document.name = "Passport"
        try context.save()

        let result = LegacyDataMigration.run(in: context, keychain: keychain)

        #expect(document.identifier != nil)
        #expect(result.assignedDocumentIDs == 1)
    }
}
