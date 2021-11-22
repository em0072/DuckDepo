//
//  DepoListViewModel.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 08/11/2021.
//

import Foundation
import SwiftUI

extension DepoListView {
    class ViewModel: ObservableObject {
        
        @ObservedObject private var db: DataBase = DataBase.shared
        
        var folderNameToAddDoc: String?
        @Published var isReordering: Bool = false

        
        func isShared(_ document: DDDocument) -> Bool {
            PersistenceController.shared.isShared(object: document)
        }
        
        
        func move(from index: IndexSet, to destination: Int, in list: [DDDocument]) {
            var listToOperate = list
            listToOperate.move(fromOffsets: index, toOffset: destination)
            _ = listToOperate.enumerated().map { (i, document) in
                document.order = Int16(i)
            }
            db.save()
        }
        
//        func fetchSharedDocuments(competion: @escaping ([DDDocument]) -> Void) {
//            CloudController.shared.fetchSharedObjects { result in
//                switch result {
//                case .failure(let error):
//                    DispatchQueue.main.async {
//                        print(error)
//                    }
//                case .success(let documents):
//                    DispatchQueue.main.async {
//                        self.sharedDocuments = documents
//                        self.saveSharedDocuments()
//                    }
//                }
//            }
//        }
//        
//        private func saveSharedDocuments() {
//            let sharedFolder = getSharedFolder()
//            if let fetchedSharedDocuments = sharedFolder?.fetchDocuments() {
//                //Check Which local copies to delete
//                for localCopy in fetchedSharedDocuments {
//                    if consists(sharedDocument: localCopy, in: sharedDocuments) == nil {
//                        PersistenceController.shared.context.delete(localCopy)
//                    }
//                }
//                //Update or add shared documents
//                    for sharedDoc in sharedDocuments {
//                        if let existingDoc = consists(sharedDocument: sharedDoc, in: fetchedSharedDocuments) {
//                            existingDoc.updateWithShared(sharedDoc)
//                            PersistenceController.shared.context.delete(sharedDoc)
//                        } else {
//                            sharedFolder?.addToDocumnets(sharedDoc)
//                        }
//                    }
//            } else {
//                let nsSet = NSSet(array: sharedDocuments)
//                sharedFolder?.addToDocumnets(nsSet)
//            }
//            PersistenceController.shared.saveContext()
//        }
//        
//        private func consists(sharedDocument: DDDocument, in array: [DDDocument]) -> DDDocument? {
//            for item in array {
//                if item.shareRecordName == sharedDocument.shareRecordName {
//                    return item
//                }
//            }
//            return nil
//        }
//        
//        
//        
//        private func getSharedFolder() -> DDFolder? {
//            let sharedFolderName = "Shared With You"
//            var sharedFolder = DDFolder.fetchFolder(with: sharedFolderName, viewContext: PersistenceController.shared.context)
//            if sharedFolder == nil {
//                let newSharedFolder = DDFolder(context: PersistenceController.shared.context)
//                newSharedFolder.name = sharedFolderName
//                sharedFolder = newSharedFolder
//            }
//            sharedFolder?.order = Int32(DDFolder.fetchCount())
//                return sharedFolder
//        }
        
    }
}
