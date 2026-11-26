//
//  LegacyDataMigration.swift
//  DuckDepo
//
//  Replaces ManualMigrationV1toV2 (27/06/2022).
//

import CoreData
import os

/// Repairs data written by older versions. Safe to run on every launch.
///
/// Version 1 stored password values in Core Data (and so in CloudKit). Version 2 moved them to the
/// keychain but never cleared the old copy, and it ran again whenever CloudKit delivered those rows to a
/// new install: it gave every password a new ID and wrote the old value back, undoing later edits.
///
/// This migration keeps existing IDs, never overwrites a keychain value, and clears the old copy once
/// the keychain holds the value, so it has nothing left to do afterwards.
enum LegacyDataMigration {

    struct Result: Equatable {
        var movedPasswordValues = 0
        var assignedPasswordIDs = 0
        var assignedDocumentIDs = 0

        var didChange: Bool {
            movedPasswordValues + assignedPasswordIDs + assignedDocumentIDs > 0
        }
    }

    private static let logger = Logger(subsystem: "DuckDepo", category: "Migration")

    @discardableResult
    static func run(in context: NSManagedObjectContext, keychain: KeychainStoring) -> Result {
        var result = Result()
        context.performAndWait {
            migratePasswords(in: context, keychain: keychain, result: &result)
            assignDocumentIDs(in: context, result: &result)
            guard context.hasChanges else { return }
            do {
                try context.save()
            } catch {
                logger.error("Saving migrated data failed: \(String(describing: error), privacy: .public)")
                context.rollback()
                result = Result()
            }
        }
        if result.didChange {
            logger.notice("Migrated \(result.movedPasswordValues) password values, \(result.assignedPasswordIDs) password IDs, \(result.assignedDocumentIDs) document IDs")
        }
        return result
    }

    private static func migratePasswords(in context: NSManagedObjectContext, keychain: KeychainStoring, result: inout Result) {
        let request = DDPassword.fetchRequest()
        request.predicate = NSPredicate(format: "id == nil OR value != %@", "")
        guard let passwords = try? context.fetch(request) else { return }

        for password in passwords {
            if password.id == nil {
                password.id = UUID()
                result.assignedPasswordIDs += 1
            }
            guard let id = password.id, !password.value.isEmpty else { continue }
            let key = id.uuidString
            if keychain.string(forKey: key) == nil {
                // Keep the old copy until the keychain really has the value.
                guard keychain.set(password.value, forKey: key), keychain.string(forKey: key) == password.value else {
                    continue
                }
            }
            password.value = ""
            result.movedPasswordValues += 1
        }
    }

    private static func assignDocumentIDs(in context: NSManagedObjectContext, result: inout Result) {
        let request = DDDocument.fetchRequest()
        request.predicate = NSPredicate(format: "identifier == nil")
        guard let documents = try? context.fetch(request) else { return }
        for document in documents {
            document.identifier = UUID()
            result.assignedDocumentIDs += 1
        }
    }
}
