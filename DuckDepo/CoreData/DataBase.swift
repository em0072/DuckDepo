//
//  DataBase.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 04/11/2021.
//

import Foundation
import CoreData

class DataBase: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
    
    static let shared = DataBase()
    
    let persistenceController: PersistenceController = PersistenceController.shared
    var context: NSManagedObjectContext {
        persistenceController.context
    }
    
    public func save() {
        persistenceController.saveContext()
    }
    
    public func deleteEverything() {
        var requests = [NSFetchRequest<NSFetchRequestResult>]()
        let docFetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: DDDocument.entityName)
        requests.append(docFetchRequest)
        let passFetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: DDPassword.entityName)
        requests.append(passFetchRequest)
        do {
            for request in requests {
                let objects = try context.fetch(request)
                for object in objects {
                    guard let objectData = object as? NSManagedObject else {continue}
                    context.delete(objectData)
                }
            }
            persistenceController.saveContext()
            Keychain.shared.clear()
            CredentialIdentityStoreController.shared.removeAll()
        } catch let error {
            print("Error Deleteing everything - \(error)")
        }
    }
    
    func fetchCount(for object: CoreDataCountable.Type) -> Int {
        return (try? context.count(for: object.fetchRequest())) ?? 0
    }

}

