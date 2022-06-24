//
//  DocumentViewModel.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 08/11/2021.
//

import Foundation
import CloudKit
import SwiftUI


extension OldDocumentView {
    class ViewModel: NSObject, ObservableObject {
        
        let db = DataBase.shared
        @Published var document: DDDocument?
        @Published var isCloudSharing: Bool = false
        @Published var activeShare: CKShare?
        @Published var activeContainer: CKContainer?
//        @Published var isShared: Bool = false
//        @Published var canEdit: Bool = true


        var itemsToShare: [Any]?
        
//        func update(with document: DDDocument) {
//            self.document = document
//            fetchShareInfo()
//        }
//        
//        func fetchShareInfo() {
//            if let doc = document {
//                self.isShared = db.isShared(doc)
//                self.canEdit = db.canEdit(doc)
//
//            }
//        }
//        
        func isShared(_ document: DDDocument) -> Bool {
            db.isShared(document)
        }
        
        func canEdit(_ document: DDDocument) -> Bool {
            db.canEdit(document)
        }

        
        func share(_ document: DDDocument, completion: @escaping (CKShare?, CKContainer?, Error?) -> Void) {
            db.share(document: document, completion: completion)
        }
        
    }
}


