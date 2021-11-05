//
//  DepoListViewModel.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 05/11/2021.
//

import SwiftUI

extension DepoListView {
    
    class ViewModel: ObservableObject, DataBaseDelegate {
        
        enum InitialInstructionType {
            case noFolders
            case noDocuments
        }
        
        private let db: DataBase = DataBase.shared
//        @Environment(\.managedObjectContext) private var viewContext

//        @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \DDFolder.order, ascending: true)], predicate: nil, animation: .default)
//        var folders: FetchedResults<DDFolder>
        @Published var folders: [DDFolder] = []
        var view: DepoListView?

        init() {
            updateView()
        }
        
//        func prepare() {
//            updateView()
//            db.subscribe(self)
//        }
        
        func updateView() {
            withAnimation {
                folders = db.fetchFolder()
            }
        }
        
//        public func checkIf(_ instructionType: InitialInstructionType) -> Bool {
//            switch instructionType {
//            case .noFolders:
//                return folders.count == 0
//            case .noDocuments:
//                return folders.first?.fetchDocumentsCount() ?? 0 == 0
//            }
//        }
        
    }
}

