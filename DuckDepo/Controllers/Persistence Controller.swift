//
//  Persistence.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/10/2021.
//

import CoreData
import CloudKit

protocol PersistenceControllerDelegate {
    func receivedRemoteChanges()
    func didSave()
}

class PersistenceController: ObservableObject {
    static let shared = PersistenceController()
    
    //MARK: - Public Properties
    public var context: NSManagedObjectContext {
        return container.viewContext
    }
    
    public var delegate: PersistenceControllerDelegate?

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

    public let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        // Prepare container
        container = NSPersistentCloudKitContainer(name: "DuckDepo")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
//        for description in container.persistentStoreDescriptions {
//            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
//        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        //Subscribe to change notification from the backgroundContext
//        NotificationCenter.default.addObserver(self, selector: #selector(didSave(_:)), name: .NSManagedObjectContextDidSave, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(coordinatorReceivedRemoteChanges(_:)), name: .NSPersistentStoreRemoteChange, object: nil)
    }
    
//    @objc private func didSave(_ notification: Notification) {
//        if let notificationContext = notification.object as? NSManagedObjectContext {
//            guard notificationContext !== context else {
//                return
//            }
//            context.perform {
//                self.context.mergeChanges(fromContextDidSave: notification)
//            }
//        }
//        delegate?.didSave()
//    }
    
//    @objc func coordinatorReceivedRemoteChanges(_ notification: Notification) {
//        DispatchQueue.main.async {
//            self.delegate?.receivedRemoteChanges()
//        }
//    }
    
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
