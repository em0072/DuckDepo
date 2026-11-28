//
//  PeopleDirectory.swift
//  DuckDepo
//

import Combine
import Foundation
import SwiftUI

/// The people, for every screen: the filter rows, the pickers, and names next to documents and passwords.
/// Changes made here animate.
@Observable
final class PeopleDirectory {

    static let shared = PeopleDirectory(isShared: true)

    private(set) var people: [Person] = []
    private(set) var counts: [Person.ID: PersonCounts] = [:]

    @ObservationIgnored private let makeDatabase: () -> DataBase
    @ObservationIgnored private var database: DataBase?
    @ObservationIgnored private var storage: PeopleStorage?
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()
    /// Tests have no shared store: the view models they make use this one unless given their own, and it
    /// stays empty there.
    @ObservationIgnored private let isShared: Bool

    init(database: @escaping @autoclosure () -> DataBase) {
        makeDatabase = database
        isShared = false
    }

    private init(isShared: Bool) {
        makeDatabase = { .shared }
        self.isShared = isShared
    }

    private static let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil

    /// Starts fetching. Safe to call more than once; the list screens call it on appear.
    func start() {
        guard storage == nil, !(isShared && Self.isRunningTests) else { return }
        let database = makeDatabase()
        self.database = database
        let storage = PeopleStorage(database: database)
        self.storage = storage
        storage.people
            .sink { [weak self] people in
                self?.people = people
            }
            .store(in: &cancellables)
        storage.counts
            .sink { [weak self] counts in
                self?.counts = counts
            }
            .store(in: &cancellables)
    }

    /// Reads the people again. The extensions call it after `DataBase.readLatestStoredData()`: their
    /// context doesn't merge the app's changes, so the list would otherwise stay as it was at first.
    func refresh() {
        if let storage {
            storage.refetch()
        } else {
            start()
        }
    }

    func person(with id: Person.ID?) -> Person? {
        guard let id else { return nil }
        return people.first { $0.id == id }
    }

    /// For a new person.
    var unusedColor: PersonColor {
        PersonColor.unused(among: people.map(\.color))
    }

    // MARK: - Changes

    private var db: DataBase? {
        start()
        return database
    }

    @discardableResult
    func add(_ person: Person) -> Bool {
        withAnimation {
            db?.add(person) ?? false
        }
    }

    @discardableResult
    func update(_ person: Person) -> Bool {
        withAnimation {
            db?.update(person) ?? false
        }
    }

    @discardableResult
    func delete(_ person: Person) -> Bool {
        withAnimation {
            db?.deletePerson(with: person.id) ?? false
        }
    }

    /// For a list's `onMove`.
    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        var ids = people.map(\.id)
        ids.move(fromOffsets: source, toOffset: destination)
        // Shown in the new order at once, as the row lands; the store follows.
        people = ids.compactMap { id in people.first { $0.id == id } }
        db?.reorderPeople(ids)
    }
}
