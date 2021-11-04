//
//  DataBase.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 04/11/2021.
//

import Foundation
import CoreData

class DataBase: NSObject, NSFetchedResultsControllerDelegate {
    
    static let shared = DataBase()
    
    private let context: NSManagedObjectContext = PersistenceController.shared.context
        
    private override init() {}
    
    public func fetchFolder() -> [DDFolder] {
        var folders: [DDFolder] = []
        let folderController = NSFetchedResultsController(fetchRequest: DDFolder.fetchRequest(), managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        folderController.delegate = self
        do {
            try folderController.performFetch()
            folders = folderController.fetchedObjects ?? []
        } catch {
            print("failed to fetch items!")
        }
        return folders
    }
    
    public func save(_ document: Document, in folder: DDFolder) {
        _ = DDDocument(viewContext: context, object: document, order: folder.fetchDocumentsCount(), folder: folder)
        PersistenceController.shared.saveContext()
    }
    
    public func update(_ document: Document, in folder: DDFolder)  {
        if let fetchedDDDocument = DDDocument.fetchDocument(with: document.id, viewContext: context) {
            fetchedDDDocument.update(with: document, and: folder, viewContext: context)
            PersistenceController.shared.saveContext()
        }
    }
    
    public func delete(_ document: Document) {
        if let fetchedDDDocument = DDDocument.fetchDocument(with: document.id, viewContext: context) {
            context.delete(fetchedDDDocument)
            PersistenceController.shared.saveContext()
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
