//
//  DataBase Documents.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/11/2021.
//

import Foundation
import CloudKit
import CoreData
import Combine

class DocumentsStorage: NSObject {
    
    var folders = CurrentValueSubject<[Folder], Never>([])
    var documents = CurrentValueSubject<[Document], Never>([])
    private var fetchedRequestController: NSFetchedResultsController<DDDocument>
//    private var fetchedFoldersRequestController: NSFetchedResultsController<DDFolder>

    override init() {

        let fetchRequest = DDDocument.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \DDDocument.documentTypeOrder, ascending: true),
                                        NSSortDescriptor(keyPath: \DDDocument.order, ascending: true)]
        fetchedRequestController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DataBase.shared.context, sectionNameKeyPath: nil, cacheName: nil)
        
//        let fetchRequestFolders = DDFolder.fetchRequest()
//        fetchRequestFolders.sortDescriptors = [NSSortDescriptor(keyPath: \DDFolder.name, ascending: true),
//                                        NSSortDescriptor(keyPath: \DDDocument.order, ascending: true)]
//        fetchedFoldersRequestController = NSFetchedResultsController(fetchRequest: fetchRequestFolders, managedObjectContext: DataBase.shared.context, sectionNameKeyPath: nil, cacheName: nil)

        super.init()
        
        fetchedRequestController.delegate = self
        do {
            try fetchedRequestController.performFetch()
            controllerDidChangeContent(fetchedRequestController as! NSFetchedResultsController<NSFetchRequestResult>)
            
        } catch {
            print("Oops, could not fetch documents")
        }
        
//        fetchedFoldersRequestController.delegate = self
//        do {
//            try fetchedFoldersRequestController.performFetch()
//            controllerDidChangeContent(fetchedFoldersRequestController as! NSFetchedResultsController<NSFetchRequestResult>)
//            
//        } catch {
//            print("Oops, could not fetch documents")
//        }
    }
}

extension DocumentsStorage: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        guard let documents = controller.fetchedObjects as? [DDDocument] else {
            return
        }
        self.documents.value = documents.map({ $0.convert() })
        
//        guard let folders = controller.fetchedObjects as? [DDFolder] else {
//            return
//        }
//        self.folders.value = folders.map({ $0.convert() })

    }
}


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
            fetchedDDDocument.updateType(newType: document.documentType)
            fetchedDDDocument.documentDescription = document.description
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
