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


class PersistenceController {
        
    static let shared = PersistenceController()
    
    //MARK: - Public Properties
    public var context: NSManagedObjectContext {
        return container.viewContext
    }
    
    public let container: NSPersistentCloudKitContainer
    
    var privatePersistentStore: NSPersistentStore {
        return _privatePersistentStore!
    }
    
    var sharedPersistentStore: NSPersistentStore {
        return _sharedPersistentStore!
    }

    public var delegate: PersistenceControllerDelegate?

    //MARK: - Private Properties
    private var _privatePersistentStore: NSPersistentStore?
    
    private var _sharedPersistentStore: NSPersistentStore?

    /**
     An operation queue for handling history processing tasks: watching changes, deduplicating tags, and triggering UI updates if needed.
     */
    private lazy var historyQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

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


    init(inMemory: Bool = false) {
        // Prepare container
        container = NSPersistentCloudKitContainer(name: "DuckDepo")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        let privateStoreDescription = container.persistentStoreDescriptions.first!
        let storesURL = privateStoreDescription.url!.deletingLastPathComponent()

        privateStoreDescription.url = storesURL.appendingPathComponent("private.sqlite")
//        privateStoreDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        privateStoreDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        //Add Shared Database
        let sharedStoreURL = storesURL.appendingPathComponent("shared.sqlite")
        guard let sharedStoreDescription = privateStoreDescription.copy() as? NSPersistentStoreDescription else {
            fatalError("Copying the private store description returned an unexpected value.")
        }
        sharedStoreDescription.url = sharedStoreURL
        
        if AppDelegate.shared.allowCloudKitSync {
            let containerIdentifier = privateStoreDescription.cloudKitContainerOptions!.containerIdentifier
            let sharedStoreOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: containerIdentifier)
            sharedStoreOptions.databaseScope = .shared
            sharedStoreDescription.cloudKitContainerOptions = sharedStoreOptions
        } else {
            privateStoreDescription.cloudKitContainerOptions = nil
            sharedStoreDescription.cloudKitContainerOptions = nil
        }

        container.persistentStoreDescriptions.append(sharedStoreDescription)
        container.loadPersistentStores(completionHandler: { (loadedStoreDescription, error) in
            if let loadError = error as NSError? {
                fatalError("###\(#function): Failed to load persistent stores:\(loadError)")
            } else if let cloudKitContainerOptions = loadedStoreDescription.cloudKitContainerOptions {
                if .private == cloudKitContainerOptions.databaseScope {
                    self._privatePersistentStore = self.container.persistentStoreCoordinator.persistentStore(for: loadedStoreDescription.url!)
                } else if .shared == cloudKitContainerOptions.databaseScope {
                    self._sharedPersistentStore = self.container.persistentStoreCoordinator.persistentStore(for: loadedStoreDescription.url!)
                }
            }
        })
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
        // Pin the viewContext to the current generation token and set it to keep itself up to date with local changes.
        container.viewContext.automaticallyMergesChangesFromParent = true
        do {
            try container.viewContext.setQueryGenerationFrom(.current)
        } catch {
            fatalError("###\(#function): Failed to pin viewContext to the current generation:\(error)")
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


// Mark - Sharing
extension PersistenceController {
    func isShared(object: NSManagedObject) -> Bool {
        return isShared(objectID: object.objectID)
    }

    func isShared(objectID: NSManagedObjectID) -> Bool {
        var isShared = false
        if let persistentStore = objectID.persistentStore {
            if persistentStore == sharedPersistentStore {
                isShared = true
            } else {
                do {
                    let shares = try container.fetchShares(matching: [objectID])
                    if shares[objectID] != nil {
                            isShared = true
                    }
                } catch let error {
                    print("Failed to fetch share for \(objectID): \(error)")
                }
            }
        }
        return isShared
    }

    
    
//    func participants(for object: NSManagedObject) -> [RenderableShareParticipant] {
//        var participants = [CKShare.Participant]()
//        do {
//            let container = persistentContainer
//            let shares = try container.fetchShares(matching: [object.objectID])
//            if let share = shares[object.objectID] {
//                participants = share.participants
//            }
//        } catch let error {
//            print("Failed to fetch share for \(object): \(error)")
//        }
//        return participants
//    }
    
    func fetchRemoteShare(for object: NSManagedObject, completion: @escaping (CKShare?) -> Void) {
        guard let shareURL = fetchShare(for: object)?.url else {
            completion(nil)
            return
        }
        
        let operation = CKFetchShareMetadataOperation(shareURLs: [shareURL])
        operation.perShareMetadataResultBlock = { _, result in
            switch result {
            case .failure(let error):
                print("CKFetchShareMetadataOperation - \(error)")
                completion(nil)
            case .success(let shareMeta):
                completion(shareMeta.share)
            }
        }
        CKContainer.default().add(operation)
        
    }
    
    func fetchShare(for object: NSManagedObject) -> CKShare? {
        let shares = try? shares(matching: [object.objectID])
        return shares?[object.objectID]
    }
    
    func shares(matching objectIDs: [NSManagedObjectID]) throws -> [NSManagedObjectID: CKShare] {
        return try container.fetchShares(matching: objectIDs)
    }
    
    func canEdit(object: NSManagedObject) -> Bool {
        return container.canUpdateRecord(forManagedObjectWith: object.objectID)
    }
        
    func canDelete(object: NSManagedObject) -> Bool {
        return container.canDeleteRecord(forManagedObjectWith: object.objectID)
    }
}
