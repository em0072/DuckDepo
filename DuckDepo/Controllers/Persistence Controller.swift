//
//  Persistence.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/10/2021.
//

import CoreData
import CloudKit

class PersistenceController {
    static let shared = PersistenceController()
    
    //MARK: - Public Properties
    public var context: NSManagedObjectContext {
        return container.viewContext
    }
    
    

    //MARK: - Private Properties


//    static var preview: PersistenceController = {
//        let result = PersistenceController(inMemory: true)
//        let viewContext = result.container.viewContext
//        for i in 0..<10 {
//            let newItem = DDFolder(context: viewContext)
//            newItem.name = "Category \(i)"
//            newItem.order = Int32(i)
//        }
//        do {
//            try viewContext.save()
//        } catch {
//            // Replace this implementation with code to handle the error appropriately.
//            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//            let nsError = error as NSError
//            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
//        }
//        return result
//    }()

    private let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        // Prepare container
        container = NSPersistentCloudKitContainer(name: "DuckDepo")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        //Subscribe to change notification from the backgroundContext
        NotificationCenter.default.addObserver(self, selector: #selector(backgroundContextDidSave(notification:)), name: .NSManagedObjectContextDidSave, object: nil)
    }
    
    @objc private func backgroundContextDidSave(notification: Notification) {
        guard let notificationContext = notification.object as? NSManagedObjectContext else { return }

        guard notificationContext !== context else {
            return
        }
        context.perform {
            self.context.mergeChanges(fromContextDidSave: notification)
        }
    }
    
    public func performBackgroundTask(block: @escaping (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask(block)
    }

    public func saveContext() {
        do {
            if context.hasChanges {
                try context.save()
            }
        } catch {
            print(error.localizedDescription)
        }
    }

}
