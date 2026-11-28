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

    /// Saves, or when that fails undoes the unsaved changes, so the next save doesn't commit them too.
    func saveOrRollBack() -> Bool {
        guard save() else {
            context.rollback()
            return false
        }
        return true
    }

    /// Reads what's stored now from here on. The extensions don't merge other processes' changes, so their
    /// context would otherwise keep reading the store as it was when they started.
    func readLatestStoredData() {
        // `/dev/null` stores (tests) don't support query generations.
        if persistenceController.role != .inMemory {
            do {
                try context.setQueryGenerationFrom(.current)
            } catch {
                logger.error("Moving to the current generation failed: \(String(describing: error), privacy: .public)")
            }
        }
        context.refreshAllObjects()
    }

    /// Deletes all documents, folders and passwords on this device and, through iCloud, on the user's other devices.
    func deleteEverything(keychain: KeychainStoring = Keychain.shared) {
        let entityNames = [DDDocument.entityName, DDPassword.entityName, DDFolder.entityName]
        do {
            for name in entityNames {
                let request = NSFetchRequest<NSManagedObject>(entityName: name)
                for object in try context.fetch(request) {
                    context.delete(object)
                }
            }
            save()
            keychain.clear()
            // Passkeys were in the keychain too.
            NotificationCenter.default.post(name: PasskeyStorage.didChange, object: keychain)
            CredentialIdentityStoreController.shared.removeAll()
        } catch {
            logger.error("Deleting everything failed: \(String(describing: error), privacy: .public)")
        }
    }

    func fetchCount(for object: CoreDataCountable.Type) -> Int {
        (try? context.count(for: object.fetchRequest())) ?? 0
    }
}
