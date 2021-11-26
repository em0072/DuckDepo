//
//  DataBase Documents.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/11/2021.
//

import Foundation
import CloudKit
import CoreData

extension DataBase {
    
//    static var shared: DocumentsDataBase = DocumentsDataBase()
    
    public func isShared(_ document: DDDocument) -> Bool {
        PersistenceController.shared.isShared(object: document)
    }
    
    public func isShared(_ document: Document) -> Bool {
        if let fetchedDoc = fetchFromDB(document) {
            return PersistenceController.shared.isShared(object: fetchedDoc)
        } else {
            return false
        }
    }
    
    public func share(document: DDDocument, completion: @escaping (CKShare?, CKContainer?, Error?) -> Void) {
        let share = persistenceController.fetchShare(for: document)
        persistenceController.container.share([document], to: share) { objectIDs, share, container, error in
            if let actualShare = share {
                document.managedObjectContext?.performAndWait {
                    actualShare[CKShare.SystemFieldKey.title] = document.name
                }
            }
            completion(share, container, error)
        }
    }
    
    public func canEdit(_ document: DDDocument) -> Bool {
        persistenceController.canEdit(object: document)
    }
        
    public func canDelete(_ document: DDDocument) -> Bool {
        persistenceController.canDelete(object: document)
    }

    public func save(_ document: Document) {
        _ = DDDocument(viewContext: context, object: document, order: fetchDocumentCount())
        save()
    }

    public func fetchFromDB(_ document: Document) -> DDDocument? {
        DDDocument.fetchDocument(with: document.id, viewContext: context)
    }
    
    public func update(_ document: Document)  {
        if let fetchedDDDocument = DDDocument.fetchDocument(with: document.id, viewContext: context) {
            for section in fetchedDDDocument.getSections() {
                for field in section.getAllFields() {
                    context.delete(field)
                }
                context.delete(section)
            }
            fetchedDDDocument.name = document.name
            fetchedDDDocument.addToPhotos(document.photos)
            for index in 0..<document.sections.count {
                let section = document.sections[index]
                let newDDSection = DDSection(viewContext: context, object: section, order: index, document: fetchedDDDocument)
                fetchedDDDocument.addToSections(newDDSection)
            }
            save()
        }
    }
    
    public func fetchDocumentCount() -> Int {
        return fetchCount(for: DDDocument.self)
    }
    
    public func delete(_ document: Document) {
        if let fetchedDDDocument = DDDocument.fetchDocument(with: document.id, viewContext: context) {
//            deleteShareIfNeeded(for: fetchedDDDocument)
            context.delete(fetchedDDDocument)
            save()
        }
    }
    
}
