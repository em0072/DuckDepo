//
//  NewDepoListViewModel.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 17/06/2022.
//

import Combine
import Foundation

final class DepoListViewModel: ObservableObject {

    @Published var documents: [Document] = []
    @Published var isAddingNewDocument = false

    private var cancellables = Set<AnyCancellable>()
    private let dataStorage: DocumentsStorage

    init(dataStorage: DocumentsStorage = DocumentsStorage()) {
        self.dataStorage = dataStorage
        dataStorage.documents
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
