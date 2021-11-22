//
//  DataBase.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 04/11/2021.
//

import Foundation
import CoreData
import CloudKit

protocol DataBaseDelegate {
    func updateView()
}

class DataBase: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
    
    static let shared = DataBase()
    
    private let persistenceController: PersistenceController = PersistenceController.shared
    private let cloudContainer: CKContainer = CKContainer.default()
    private var context: NSManagedObjectContext {
        persistenceController.context
    }
    private var delegates: [DataBaseDelegate?] = []
        
    private override init() {
        super.init()
        PersistenceController.shared.delegate = self
    }
    
    public func subscribe(_ subscriber: DataBaseDelegate) {
        delegates.append(subscriber)
    }
    
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


//    public func fetchFolder() -> [DDFolder] {
//        var folders: [DDFolder] = []
//        let folderController = NSFetchedResultsController(fetchRequest: DDFolder.fetchRequest(), managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
//        folderController.delegate = self
//        do {
//            try folderController.performFetch()
//            folders = folderController.fetchedObjects ?? []
//        } catch {
//            print("failed to fetch items!")
//        }
//        return folders
//    }
    
//    //To Be Deleted
//    public func save(_ document: Document, in folder: DDFolder) {
//        _ = DDDocument(viewContext: context, object: document, order: folder.fetchDocumentsCount(), folder: folder)
//        PersistenceController.shared.saveContext()
//    }
    public func save() {
        persistenceController.saveContext()
    }
    
    public func save(_ document: Document) {
        _ = DDDocument(viewContext: context, object: document, order: fetchDocumentCount())
        PersistenceController.shared.saveContext()
    }
    
//    //To Be Deleted
//    public func update(_ document: Document, in folder: DDFolder)  {
//        if let fetchedDDDocument = DDDocument.fetchDocument(with: document.id, viewContext: context) {
//            fetchedDDDocument.update(with: document, and: folder, viewContext: context)
//            PersistenceController.shared.saveContext()
//        }
//    }
    
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
            PersistenceController.shared.saveContext()
        }
    }
    
    public func fetchDocumentCount() -> Int {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: DDDocument.entityName)
            return (try? context.count(for: fetchRequest)) ?? 0
    }
    
    public func delete(_ document: Document) {
        if let fetchedDDDocument = DDDocument.fetchDocument(with: document.id, viewContext: context) {
            deleteShareIfNeeded(for: fetchedDDDocument)
            context.delete(fetchedDDDocument)
            PersistenceController.shared.saveContext()
        }
    }
    
    public func deleteEverything() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: DDDocument.entityName)
        do {
        let objects = try context.fetch(fetchRequest)
        for object in objects {
            guard let objectData = object as? NSManagedObject else {continue}
            context.delete(objectData)
            persistenceController.saveContext()
        }
        } catch let error {
            print("Error Deleteing everything - \(error)")
        }
    }
    
    private func deleteShareIfNeeded(for document: DDDocument) {
        persistenceController.fetchRemoteShare(for: document) { share in
            guard let share = share else { return }
            let deleteOperation = CKModifyRecordsOperation(recordIDsToDelete: [share.recordID])
            self.cloudContainer.privateCloudDatabase.add(deleteOperation)
        }
    }
//    override init() {
//        folderController = NSFetchedResultsController(fetchRequest: DDFolder.fetchRequest(), managedObjectContext: viewContext, sectionNameKeyPath: nil, cacheName: nil)
//        super.init()
//        folderController.delegate = self
//        fetchFolders()
//
//    }
//
//    func fetchFolders() {
//        do {
//            try folderController.performFetch()
//            folders = folderController.fetchedObjects ?? []
//        } catch {
//            print("failed to fetch items!")
//        }
//    }

}


extension DataBase: PersistenceControllerDelegate {
    
    func receivedRemoteChanges() {
        for delegate in delegates {
            delegate?.updateView()
        }
    }
    
    func didSave() {
        for delegate in delegates {
            delegate?.updateView()
        }
    }
}
