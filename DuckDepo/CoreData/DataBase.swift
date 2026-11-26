//
//  DataBase.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 04/11/2021.
//

import CoreData
import os

final class DataBase {

    static let shared = DataBase(persistenceController: .shared)

    let persistenceController: PersistenceController

    var context: NSManagedObjectContext {
        persistenceController.context
    }

    let logger = Logger(subsystem: "DuckDepo", category: "DataBase")

    init(persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
    }

    @discardableResult
    func save() -> Bool {
        persistenceController.saveContext()
    }

    /// Deletes all documents, folders and passwords on this device and, through iCloud, on the user's other devices.
    func deleteEverything(keychain: KeychainStoring = Keychain.shared) {
        let entityNames = [DDDocument.entityName, DDPassword.entityName, "DDFolder"]
        do {
            for name in entityNames {
                let request = NSFetchRequest<NSManagedObject>(entityName: name)
                for object in try context.fetch(request) {
                    context.delete(object)
                }
            }
            save()
            keychain.clear()
            CredentialIdentityStoreController.shared.removeAll()
        } catch {
            logger.error("Deleting everything failed: \(String(describing: error), privacy: .public)")
        }
    }

    func fetchCount(for object: CoreDataCountable.Type) -> Int {
        (try? context.count(for: object.fetchRequest())) ?? 0
    }
}
