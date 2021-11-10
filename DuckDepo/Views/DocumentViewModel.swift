//
//  DocumentViewModel.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 08/11/2021.
//

import Foundation
import CloudKit


extension DocumentView {
    class ViewModel: ObservableObject {
        
        @Published var isCloudSharing: Bool = false
        @Published var activeShare: CKShare?
        @Published var activeContainer: CKContainer?

        var itemsToShare: [Any]?
        
        func hasShare(for document: DDDocument) -> Bool {
            PersistenceController.shared.container.record(for: document.objectID)?.share != nil
        }
        
        func share(document: DDDocument, completion: @escaping (CKShare?, CKContainer?, Error?) -> Void) {
            PersistenceController.shared.container.share([document], to: nil) { objectIDs, share, container, error in
                if let actualShare = share {
                    document.managedObjectContext?.performAndWait {
                        actualShare[CKShare.SystemFieldKey.title] = document.name
                    }
                }
                completion(share, container, error)
            }
        }
    }
}
    
    // MARK: - Error

    enum ViewModelError: Error {
        case invalidRemoteShare
    }



