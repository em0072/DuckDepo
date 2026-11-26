//
//  NewDepoListViewModel.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 17/06/2022.
//

import Combine
import Foundation

/// Cheap to create: SwiftUI may build and discard several instances; only the one on screen starts fetching.
@Observable
final class DepoListViewModel {

    var documents: [Document] = []
    var isAddingNewDocument = false

    @ObservationIgnored private var cancellables = Set<AnyCancellable>()
    @ObservationIgnored private var dataStorage: DocumentsStorage?
    @ObservationIgnored private let makeStorage: () -> DocumentsStorage

    init(makeStorage: @escaping () -> DocumentsStorage = { DocumentsStorage() }) {
        self.makeStorage = makeStorage
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

    var editDocumentViewModel: EditDocumentViewModel {
        EditDocumentViewModel(type: .new)
    }

    func addNewDocumentButtonPressed() {
        isAddingNewDocument = true
    }
}
