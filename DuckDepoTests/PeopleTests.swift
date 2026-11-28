//
//  PeopleTests.swift
//  DuckDepoTests
//

import CoreData
import Foundation
import Testing
@testable import DuckDepo

struct PersonTests {

    @Test(arguments: [
        ("Anna", "A"),
        ("Anna Maria Lee", "AL"),
        ("jean-luc picard", "JP"),
        ("макс", "М"),
        ("  ", ""),
        ("👶 Baby", "👶B"),
    ])
    func initials(name: String, expected: String) {
        #expect(Person(name: name).initials == expected)
    }

    @Test func aNewPersonGetsAColorNobodyHas() {
        #expect(PersonColor.unused(among: []) == .blue)
        #expect(PersonColor.unused(among: [.blue, .green]) == .orange)
        // Everyone has one: the least used.
        let all = PersonColor.allCases + PersonColor.allCases.filter { $0 != .teal }
        #expect(PersonColor.unused(among: all) == .teal)
    }

    @Test func anUnknownColorIsTheSameOnEveryDevice() {
        let id = UUID()
        #expect(PersonColor.fallback(for: id) == PersonColor.fallback(for: id))
    }
}

@MainActor
struct PeopleStorageTests {

    private let database = TestStack.makeDatabase()
    private let keychain = InMemoryKeychain()

    private func passwords() -> PasswordsStorage {
        PasswordsStorage(database: database, keychain: keychain, identityStore: nil)
    }

    @Test func addsRenamesReordersAndDeletesPeople() throws {
        let anna = Person(name: "Anna", color: .pink)
        let max = Person(name: "Max", color: .teal)
        #expect(database.add(anna))
        #expect(database.add(max))
        #expect(!database.add(anna), "the same person twice")
        #expect(database.allPeople().map(\.name) == ["Anna", "Max"])

        var renamed = anna
        renamed.name = "Anya"
        renamed.color = .purple
        #expect(database.update(renamed))
        #expect(database.reorderPeople([max.id, anna.id]))
        #expect(database.allPeople().map(\.name) == ["Max", "Anya"])
        #expect(database.allPeople().last?.color == .purple)

        #expect(database.deletePerson(with: max.id))
        #expect(database.allPeople().map(\.id) == [anna.id])
    }

    @Test func reorderingKeepsSomeoneAddedMeanwhile() {
        let people = ["A", "B", "C"].map { Person(name: $0) }
        people.forEach { database.add($0) }
        // C was added on another device after the list was shown.
        #expect(database.reorderPeople([people[1].id, people[0].id]))
        #expect(database.allPeople().map(\.name) == ["B", "A", "C"])
    }

    @Test func documentsAndPasswordsKeepTheirPerson() throws {
        let anna = Person(name: "Anna")
        database.add(anna)
        let document = Document(name: "Passport", personID: anna.id)
        #expect(database.save(document))
        #expect(database.fullDocument(with: document.id)?.personID == anna.id)

        var password = Password(name: "Mail", value: "secret")
        password.personID = anna.id
        let storage = passwords()
        #expect(storage.save(password))
        storage.startObserving()
        #expect(storage.passwords.value.first?.personID == anna.id)

        // The editor saves no one.
        var edited = try #require(database.fullDocument(with: document.id))
        edited.personID = nil
        #expect(database.update(edited))
        #expect(database.fullDocument(with: document.id)?.personID == nil)
    }

    @Test func deletingSomeoneKeepsTheirDocumentsAndPasswords() {
        let anna = Person(name: "Anna")
        database.add(anna)
        let document = Document(name: "Passport", personID: anna.id)
        database.save(document)
        var password = Password(name: "Mail", value: "secret")
        password.personID = anna.id
        passwords().save(password)

        #expect(database.deletePerson(with: anna.id))

        #expect(database.fullDocument(with: document.id)?.personID == nil)
        #expect(passwords().allRecords().first?.personID == nil)
        #expect(keychain.string(forKey: password.id.uuidString) == "secret")
    }

    @Test func someoneWhoIsGoneMeansNoOne() {
        let document = Document(name: "Passport", personID: UUID())
        #expect(database.save(document))
        #expect(database.fullDocument(with: document.id)?.personID == nil)
    }

    @Test func movesThingsBetweenPeople() {
        let anna = Person(name: "Anna")
        let max = Person(name: "Max")
        database.add(anna)
        database.add(max)
        let document = Document(name: "Passport", personID: anna.id)
        database.save(document)
        let password = Password(name: "Mail", value: "secret")
        passwords().save(password)

        #expect(database.setPerson(max.id, forDocumentWith: document.id))
        #expect(database.setPerson(max.id, forPasswordWith: password.id))
        #expect(database.fullDocument(with: document.id)?.personID == max.id)
        #expect(passwords().allRecords().first?.personID == max.id)

        #expect(database.setPerson(nil, forPasswordWith: password.id))
        #expect(passwords().allRecords().first?.personID == nil)
        #expect(!database.setPerson(max.id, forDocumentWith: UUID()))
    }

    @Test func countsFollowChanges() {
        let anna = Person(name: "Anna")
        database.add(anna)
        let storage = PeopleStorage(database: database)
        #expect(storage.counts.value[anna.id] == PersonCounts())

        let document = Document(name: "Passport", personID: anna.id)
        database.save(document)
        var password = Password(name: "Mail", value: "secret")
        password.personID = anna.id
        passwords().save(password)
        #expect(storage.counts.value[anna.id] == PersonCounts(documents: 1, passwords: 1))

        database.setPerson(nil, forDocumentWith: document.id)
        #expect(storage.counts.value[anna.id] == PersonCounts(documents: 0, passwords: 1))
    }

    @Test func editingADocumentKeepsItAFavorite() throws {
        let document = Document(name: "Passport")
        database.save(document)
        // The editor opened before it was made a favourite (here, or on another device).
        var stale = try #require(database.fullDocument(with: document.id))
        #expect(database.setFavorite(true, forDocumentWith: document.id))

        stale.name = "Passport (new)"
        #expect(database.update(stale))

        let stored = try #require(database.fullDocument(with: document.id))
        #expect(stored.isFavorite)
        #expect(stored.name == "Passport (new)")
        #expect(database.setFavorite(false, forDocumentWith: document.id))
        #expect(database.fullDocument(with: document.id)?.isFavorite == false)
    }

    @Test func editorsKeepAPersonChangedMeanwhile() throws {
        let anna = Person(name: "Anna")
        let max = Person(name: "Max")
        database.add(anna)
        database.add(max)
        let document = Document(name: "Passport", personID: anna.id)
        database.save(document)
        let editor = EditDocumentViewModel(type: .existing(document), database: database)
        editor.load()
        // Moved to Max on another device while the editor is open.
        #expect(database.setPerson(max.id, forDocumentWith: document.id))
        editor.document.name = "Passport (new)"
        editor.save()
        let stored = try #require(database.fullDocument(with: document.id))
        #expect(stored.personID == max.id)
        #expect(stored.name == "Passport (new)")

        var password = Password(name: "Mail", value: "secret")
        password.personID = anna.id
        let storage = passwords()
        storage.save(password)
        let passwordEditor = EditPasswordViewModel(type: .existing(password), storage: storage)
        passwordEditor.load()
        #expect(database.setPerson(max.id, forPasswordWith: password.id))
        passwordEditor.passwordName = "Mail (new)"
        passwordEditor.save()
        #expect(storage.allRecords().first?.personID == max.id)
        #expect(storage.allRecords().first?.name == "Mail (new)")

        // A change made in the editor is saved.
        let another = EditPasswordViewModel(type: .existing(try #require(storage.allRecords().first)), storage: storage)
        another.load()
        another.personID = nil
        another.save()
        #expect(storage.allRecords().first?.personID == nil)
    }

    @Test func renamingKeepsAColorFromANewerVersion() throws {
        let anna = Person(name: "Anna")
        database.add(anna)
        let folder = try #require(DDFolder.fetch(with: anna.id, in: database.context))
        folder.color = "yellow"
        try database.context.save()
        var shown = try #require(database.allPeople().first)
        #expect(shown.color == .fallback(for: anna.id))

        shown.name = "Anya"
        #expect(database.update(shown))
        #expect(folder.color == "yellow")
        #expect(folder.personName == "Anya")

        shown.color = try #require(PersonColor.allCases.first { $0 != .fallback(for: anna.id) })
        #expect(database.update(shown))
        #expect(folder.color == shown.color.rawValue)
    }

    /// Names go to iCloud encrypted, like the names inside documents.
    @Test func namesAreStoredOnlyInTheEncryptedField() throws {
        let anna = Person(name: "Anna Lee")
        database.add(anna)
        let folder = try #require(DDFolder.fetch(with: anna.id, in: database.context))
        #expect(folder.encryptedName == "Anna Lee")
        #expect(folder.name == nil)
        let attributes = try #require(PersistenceController.model.entitiesByName[DDFolder.entityName]?.attributesByName)
        #expect(attributes["encryptedName"]?.allowsCloudEncryption == true)
    }

    @Test func deleteEverythingRemovesPeople() {
        database.add(Person(name: "Anna"))
        database.deleteEverything(keychain: keychain)
        #expect(database.allPeople().isEmpty)
    }

    @Test func oldFoldersGetAnID() throws {
        let folder = DDFolder(context: database.context)
        folder.name = "Family"
        try database.context.save()
        #expect(database.allPeople().isEmpty)

        let result = LegacyDataMigration.run(in: database.context, keychain: keychain)

        #expect(result.assignedFolderIDs == 1)
        #expect(result.encryptedFolderNames == 1)
        #expect(database.allPeople().map(\.name) == ["Family"])
        #expect(folder.name == nil)
        #expect(folder.encryptedName == "Family")
        let again = LegacyDataMigration.run(in: database.context, keychain: keychain)
        #expect(again.assignedFolderIDs == 0 && again.encryptedFolderNames == 0)
    }
}

@MainActor
struct PeopleListTests {

    private let database = TestStack.makeDatabase()
    private let anna = Person(name: "Anna", color: .pink)
    private let max = Person(name: "Max", color: .teal)

    private func makeList() -> DepoListViewModel {
        database.add(anna)
        database.add(max)
        let viewModel = DepoListViewModel(database: database, people: PeopleDirectory(database: self.database))
        viewModel.start()
        return viewModel
    }

    @Test func showsOnePersonsDocumentsWithFavoritesFirst() {
        let viewModel = makeList()
        let passport = Document(name: "Passport", documentType: .identification, personID: anna.id)
        let licence = Document(name: "Licence", documentType: .transport, personID: anna.id)
        let other = Document(name: "Max's passport", documentType: .identification, personID: max.id)
        let shared = Document(name: "Insurance", documentType: .other)
        [passport, licence, other, shared].forEach { database.save($0) }
        viewModel.toggleFavorite(licence)

        #expect(viewModel.favorites.map(\.name) == ["Licence"])
        #expect(viewModel.groups.flatMap(\.documents).count == 3)
        #expect(viewModel.person(for: other)?.name == "Max")

        viewModel.filter = .person(anna.id)
        #expect(viewModel.favorites.map(\.name) == ["Licence"])
        #expect(viewModel.groups.flatMap(\.documents).map(\.name) == ["Passport"])
        // Everything shown is hers: rows don't say so.
        #expect(viewModel.person(for: passport) == nil)
    }

    @Test func aDeletedPersonShowsEveryone() {
        let viewModel = makeList()
        database.save(Document(name: "Passport", personID: anna.id))
        database.save(Document(name: "Insurance"))
        viewModel.filter = .person(anna.id)
        #expect(viewModel.shownDocuments.count == 1)

        database.deletePerson(with: anna.id)

        #expect(viewModel.selectedPersonID == nil)
        #expect(viewModel.shownDocuments.count == 2)
    }

    @Test func anEmptyListShowsEveryone() {
        let viewModel = makeList()
        let passport = Document(name: "Passport", personID: anna.id)
        database.save(passport)
        viewModel.filter = .person(anna.id)

        database.delete(passport)

        // The empty list has no filter row: nothing new should quietly be hers.
        #expect(viewModel.filter == .everyone)
        #expect(viewModel.editDocumentViewModel.document.personID == nil)
    }

    @Test func aStarOrPersonChangeDoesNotReadTheDocumentAgain() throws {
        let document = Document(name: "Passport")
        database.save(document)
        let viewModel = DocumentViewModel(document: document, database: database)
        viewModel.load()
        var stored = try #require(database.fullDocument(with: document.id))
        stored.name = "Renamed"
        database.update(stored)

        var starred = document
        starred.isFavorite = true
        starred.personID = anna.id
        viewModel.listItemChanged(from: document, to: starred)
        #expect(viewModel.document.isFavorite)
        #expect(viewModel.document.personID == anna.id)
        #expect(viewModel.document.name == "Passport", "not read again")

        var renamed = starred
        renamed.name = "Renamed"
        viewModel.listItemChanged(from: starred, to: renamed)
        #expect(viewModel.document.name == "Renamed")
    }

    @Test func newDocumentsAndPasswordsStartWithTheShownPerson() {
        let viewModel = makeList()
        #expect(viewModel.editDocumentViewModel.document.personID == nil)
        viewModel.filter = .person(max.id)
        let editor = viewModel.editDocumentViewModel
        #expect(editor.document.personID == max.id)
        #expect(!editor.hasChanges, "closing it right away asks nothing")

        let passwordEditor = EditPasswordViewModel(type: .new, storage: PasswordsStorage(database: database, keychain: InMemoryKeychain(), identityStore: nil),
                                                   personID: max.id)
        #expect(passwordEditor.personID == max.id)
        #expect(!passwordEditor.hasChanges)
    }

    @Test func passwordsFilterHidesPasskeys() {
        let keychain = InMemoryKeychain()
        database.add(anna)
        var mail = Password(name: "Mail", value: "a")
        mail.personID = anna.id
        let storage = PasswordsStorage(database: database, keychain: keychain, identityStore: nil)
        storage.save(mail)
        storage.save(Password(name: "Bank", value: "b"))
        let passkeys = PasskeyStorage(keychain: keychain)
        #expect(passkeys.save(Passkey.make(relyingParty: "github.com", userName: "anna", userHandle: Data([1]))))
        let viewModel = PasswordsListViewModel(makeStorage: { storage }, passkeyStorage: passkeys,
                                               people: PeopleDirectory(database: self.database))
        viewModel.start()
        #expect(viewModel.shownPasswords.count == 2)
        #expect(viewModel.shownPasskeys.count == 1)

        viewModel.filter = .person(anna.id)

        #expect(viewModel.shownPasswords.map(\.name) == ["Mail"])
        #expect(viewModel.shownPasskeys.isEmpty)

        // Her last password gone: back to everyone's.
        storage.delete(mail)
        storage.delete(viewModel.passwords[0])
        #expect(passkeys.delete(viewModel.passkeys[0]))
        viewModel.reloadPasskeys()
        #expect(viewModel.filter == .everyone)
    }

    @Test func searchFindsEverythingOfAPerson() {
        database.add(anna)
        database.save(Document(name: "Passport", personID: anna.id))
        database.save(Document(name: "Insurance"))
        let keychain = InMemoryKeychain()
        var mail = Password(name: "Mail", value: "a")
        mail.personID = anna.id
        PasswordsStorage(database: database, keychain: keychain, identityStore: nil).save(mail)
        let index = PhotoTextIndex(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID()).json"))
        let search = SearchViewModel(database: database, keychain: keychain, photoText: index,
                                     people: PeopleDirectory(database: self.database))
        search.start()

        search.query = "ann"

        #expect(search.documentResults.map(\.name) == ["Passport"])
        #expect(search.passwordResults.map(\.name) == ["Mail"])
    }
}

struct PersonSuggestionTests {

    private func document(holder: String, personID: Person.ID? = nil) -> Document {
        let field = Field(key: FieldKey.fullName.rawValue, title: "Full Name", value: holder, type: .string)
        return Document(name: "Passport", sections: [DocSection(name: "Owner", fields: [field])], personID: personID)
    }

    private let anna = Person(name: "Anna")
    private let max = Person(name: "Max")

    @Test func sameHolderAsAnotherOfTheirDocuments() {
        let scanned = document(holder: "LEE ANNA")
        let suggestion = PersonSuggestion.person(for: scanned, among: [document(holder: "Anna Lee", personID: max.id)],
                                                 people: [anna, max])
        // Her documents say she is Max's: the documents win over the names.
        #expect(suggestion == max.id)
    }

    @Test func aPersonsNameInTheHolders() {
        #expect(PersonSuggestion.person(for: document(holder: "ANNA MARIA LEE"), among: [], people: [anna, max]) == anna.id)
        #expect(PersonSuggestion.person(for: document(holder: "JOHN SMITH"), among: [], people: [anna, max]) == nil)
        #expect(PersonSuggestion.person(for: Document(name: "Passport"), among: [], people: [anna, max]) == nil)
    }

    @Test func nobodyWhenItIsNotClear() {
        let other = Person(name: "Anna Lee")
        #expect(PersonSuggestion.person(for: document(holder: "ANNA LEE"), among: [], people: [anna, other]) == nil)
        let documents = [document(holder: "ANNA LEE", personID: anna.id), document(holder: "LEE ANNA", personID: max.id)]
        #expect(PersonSuggestion.person(for: document(holder: "ANNA LEE"), among: documents, people: [anna, max]) == nil)
    }

    @Test func cyrillicNamesMatchTheirLatinSpelling() {
        let анна = Person(name: "Анна")
        #expect(PersonSuggestion.person(for: document(holder: "ANNA IVANOVA"), among: [], people: [анна]) == анна.id)
    }

    @MainActor
    @Test func suggestsFromStoredHolderNames() {
        let database = TestStack.makeDatabase()
        database.add(anna)
        database.add(max)
        database.save(document(holder: "Lee Anna", personID: max.id))
        // Nobody's: not read.
        database.save(document(holder: "Someone Else"))

        #expect(database.holderNames().map(\.personID) == [max.id])
        #expect(PersonSuggestion.person(for: document(holder: "ANNA LEE"), in: database) == max.id)
        #expect(PersonSuggestion.person(for: Document(name: "Passport"), in: database) == nil)

        let draft = ScanDraft(document: document(holder: "ANNA LEE"), confidence: [:], isEmpty: false)
        let editor = EditDocumentViewModel(type: .scanned(draft), database: database)
        editor.load()
        #expect(editor.document.personID == max.id)
        // The share extension while the app is locked: nothing stored shows.
        let locked = EditDocumentViewModel(type: .scanned(draft), database: database, showsPeople: false)
        locked.load()
        #expect(locked.document.personID == nil)
        #expect(!locked.isPersonSuggested)
    }

    @Test func somebodyWhoIsGoneIsNotSuggested() {
        let documents = [document(holder: "ANNA LEE", personID: UUID())]
        #expect(PersonSuggestion.person(for: document(holder: "ANNA LEE"), among: documents, people: [max]) == nil)
    }
}

struct PeopleReminderTests {

    @Test func remindersSayWhoseDocumentItIs() throws {
        let anna = Person(name: "Anna")
        let field = Field(key: FieldKey.expiryDate.rawValue, title: "Date Of Expiry", value: "2027-03-01", type: .date)
        let passport = Document(name: "Passport", sections: [DocSection(name: "Info", fields: [field])], personID: anna.id)
        let plan = ExpiryReminders.plan(for: [passport], schedule: .sevenDays, now: Date(timeIntervalSince1970: 1_790_000_000),
                                        personNames: [anna.id: "Anna"])
        let reminder = try #require(plan.first)
        #expect(reminder.personName == "Anna")
        let title = ExpiryReminders.request(for: reminder).content.title
        #expect(title.contains("Anna") && title.contains("Passport"))
        // Without a person, only the document.
        let alone = ExpiryReminders.plan(for: [passport], schedule: .sevenDays, now: Date(timeIntervalSince1970: 1_790_000_000))
        #expect(ExpiryReminders.request(for: try #require(alone.first)).content.title == "Passport")
    }
}

/// A store written by version 2.7 (model 3), or by a 2.8 build with model 4, opens with this model and
/// keeps its data.
@MainActor
struct ModelMigrationTests {

    @Test(arguments: ["DuckDepo 3", "DuckDepo 4"])
    func opensAnOlderStore(version: String) throws {
        let momd = try #require(Bundle(for: DDDocument.self).url(forResource: "DuckDepo", withExtension: "momd"))
        let v3 = try #require(NSManagedObjectModel(contentsOf: momd.appendingPathComponent("\(version).mom")))
        // Plain objects: this test mustn't make a second model claim the app's classes.
        let plain = v3.copy() as! NSManagedObjectModel
        for entity in plain.entities {
            entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        }
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("v3.sqlite")
        let documentID = UUID()
        let passwordID = UUID()

        do {
            let coordinator = NSPersistentStoreCoordinator(managedObjectModel: plain)
            _ = try coordinator.addPersistentStore(type: .sqlite, at: url)
            let context = NSManagedObjectContext(.mainQueue)
            context.persistentStoreCoordinator = coordinator
            let document = NSManagedObject(entity: try #require(plain.entitiesByName["DDDocument"]), insertInto: context)
            document.setValue(documentID, forKey: "identifier")
            document.setValue("Passport", forKey: "name")
            let password = NSManagedObject(entity: try #require(plain.entitiesByName["DDPassword"]), insertInto: context)
            password.setValue(passwordID, forKey: "id")
            password.setValue("Mail", forKey: "name")
            try context.save()
            for store in coordinator.persistentStores {
                try coordinator.remove(store)
            }
        }

        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: PersistenceController.model)
        _ = try coordinator.addPersistentStore(type: .sqlite, at: url, options: [
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true,
        ])
        let context = NSManagedObjectContext(.mainQueue)
        context.persistentStoreCoordinator = coordinator
        let document = try #require(DDDocument.fetchDocument(with: documentID, viewContext: context))
        #expect(document.name == "Passport")
        #expect(!document.isFavorite)
        #expect(document.folder == nil)
        let password = try #require(try context.fetch(DDPassword.fetchRequest()).first)
        #expect(password.id == passwordID)
        #expect(password.folder == nil)
        for store in coordinator.persistentStores {
            try coordinator.remove(store)
        }
    }
}
