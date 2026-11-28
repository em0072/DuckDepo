//
//  DepoListViewModel.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 01/07/2022.
//

import Combine
import Foundation

@Observable
final class DepoListViewModel {

    var documents: [Document] = []
    var isAddingNewDocument = false
    /// Whose documents the list shows.
    var filter: PersonFilter = .everyone

    @ObservationIgnored let people: PeopleDirectory
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()
    @ObservationIgnored private var dataStorage: DocumentsStorage?
    @ObservationIgnored private let makeStorage: () -> DocumentsStorage
    @ObservationIgnored private let database: DataBase

    init(database: DataBase = .shared, people: PeopleDirectory = .shared, makeStorage: (() -> DocumentsStorage)? = nil) {
        self.database = database
        self.people = people
        self.makeStorage = makeStorage ?? { DocumentsStorage(database: database) }
    }

    /// Starts fetching documents. Safe to call more than once.
    func start() {
        people.start()
        guard dataStorage == nil else { return }
        let storage = makeStorage()
        dataStorage = storage
        storage.documents
            .sink { [weak self] documents in
                self?.documents = documents
                // The empty list has no filter row: a filter left on would quietly give new documents
                // to that person, and hide the ones that aren't theirs once there are some.
                if documents.isEmpty {
                    self?.filter = .everyone
                }
            }
            .store(in: &cancellables)
    }

    /// The person the list shows, while they exist (they may be deleted, here or on another device).
    var selectedPersonID: Person.ID? {
        filter.personID.flatMap { people.person(with: $0)?.id }
    }

    var shownDocuments: [Document] {
        guard let selectedPersonID else { return documents }
        return documents.filter { $0.personID == selectedPersonID }
    }

    /// At the top, in their usual order.
    var favorites: [Document] {
        shownDocuments.filter(\.isFavorite)
    }

    /// The other documents, by type. Searching happens in the search tab.
    var groups: [DocumentGroup] {
        DocumentSearch.groups(for: shownDocuments.filter { !$0.isFavorite }, matching: "")
    }

    /// The person a row shows: only while the list shows everyone's documents.
    func person(for document: Document) -> Person? {
        guard selectedPersonID == nil else { return nil }
        return people.person(with: document.personID)
    }

    func document(with id: Document.ID?) -> Document? {
        guard let id else { return nil }
        return documents.first { $0.id == id }
    }

    var editDocumentViewModel: EditDocumentViewModel {
        EditDocumentViewModel(type: .new, database: database, personID: selectedPersonID)
    }

    func scannedDocumentViewModel(for draft: ScanDraft) -> EditDocumentViewModel {
        EditDocumentViewModel(type: .scanned(draft), database: database, personID: selectedPersonID)
    }

    func addNewDocumentButtonPressed() {
        isAddingNewDocument = true
    }

    func delete(_ document: Document) {
        _ = database.delete(document)
    }

    func setPerson(_ personID: Person.ID?, for document: Document) {
        _ = database.setPerson(personID, forDocumentWith: document.id)
    }

    func toggleFavorite(_ document: Document) {
        _ = database.setFavorite(!document.isFavorite, forDocumentWith: document.id)
    }
}
