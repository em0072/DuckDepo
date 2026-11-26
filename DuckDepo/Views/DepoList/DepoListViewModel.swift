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
    var searchText = ""
    var isAddingNewDocument = false

    @ObservationIgnored private var cancellables = Set<AnyCancellable>()
    @ObservationIgnored private var dataStorage: DocumentsStorage?
    @ObservationIgnored private let makeStorage: () -> DocumentsStorage
    @ObservationIgnored private let database: DataBase

    init(database: DataBase = .shared, makeStorage: (() -> DocumentsStorage)? = nil) {
        self.database = database
        self.makeStorage = makeStorage ?? { DocumentsStorage(database: database) }
    }

    /// Starts fetching documents. Safe to call more than once.
    func start() {
        guard dataStorage == nil else { return }
        let storage = makeStorage()
        dataStorage = storage
        storage.documents
            .sink { [weak self] documents in
                self?.documents = documents
            }
            .store(in: &cancellables)
    }

    /// The documents matching the search, by type.
    var groups: [DocumentGroup] {
        DocumentSearch.groups(for: documents, matching: searchText)
    }

    func document(with id: Document.ID?) -> Document? {
        guard let id else { return nil }
        return documents.first { $0.id == id }
    }

    var editDocumentViewModel: EditDocumentViewModel {
        EditDocumentViewModel(type: .new, database: database)
    }

    func addNewDocumentButtonPressed() {
        isAddingNewDocument = true
    }

    func delete(_ document: Document) {
        _ = database.delete(document)
    }
}
