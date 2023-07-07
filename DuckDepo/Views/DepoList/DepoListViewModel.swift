//
//  NewDepoListViewModel.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 17/06/2022.
//

import Foundation
import Combine

class DepoListViewModel: ObservableObject {
    
    @Published var documents: [Document] = []
    
    @Published var isAddingNewDocument: Bool = false
    @Published var selectedDocument: Document?

    private var cancellable = Set<AnyCancellable>()
    private var dataStorage = DocumentsStorage()
    
    
    init() {
        dataStorage.documents.sink { documents in
            self.documents = documents
        }.store(in: &cancellable)
    }
    
    var editDocumentViewModel: EditDocumentViewModel {
        return EditDocumentViewModel(type: .new)
    }
    
    func addNewDocumentButtonPressed() {
        isAddingNewDocument = true
    }
    
}
