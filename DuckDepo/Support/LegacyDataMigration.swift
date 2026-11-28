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
///
/// Version 2.7 adds keys to predefined sections and fields, real date fields, an expiry date per document,
/// and a record per photo. Every step gives the same result on every device, so two devices migrating
/// the same synced data agree. Version 2.6 keeps writing sections, fields and `photoData` without these,
/// so each step runs again for whatever it changed.
///
/// Version 2.8 shows folders as people; the model always had them, but without an ID.
enum LegacyDataMigration {

    struct Result: Equatable {
        var movedPasswordValues = 0
        var assignedPasswordIDs = 0
        var assignedDocumentIDs = 0
        var assignedFolderIDs = 0
        var encryptedFolderNames = 0
        var assignedSectionKeys = 0
        var assignedFieldKeys = 0
        var convertedDates = 0
        var updatedExpiryDates = 0
        var convertedPhotoDocuments = 0
        var removedDuplicatePhotos = 0

        var didChange: Bool {
            movedPasswordValues + assignedPasswordIDs + assignedDocumentIDs + assignedFolderIDs + encryptedFolderNames + assignedSectionKeys + assignedFieldKeys
                + convertedDates + updatedExpiryDates + convertedPhotoDocuments + removedDuplicatePhotos > 0
        }
    }

    private static let logger = Logger(subsystem: "DuckDepo", category: "Migration")

    @discardableResult
    /// - Parameter convertPhotos: Reads every document's photo data, so the app does it once per launch.
    static func run(in context: NSManagedObjectContext, keychain: KeychainStoring, convertPhotos: Bool = true) -> Result {
        var result = Result()
        context.performAndWait {
            migratePasswords(in: context, keychain: keychain, result: &result)
            assignDocumentIDs(in: context, result: &result)
            assignFolderIDs(in: context, result: &result)
            assignSectionKeys(in: context, result: &result)
            assignFieldKeysAndConvertDates(in: context, result: &result)
            updateDocuments(in: context, convertPhotos: convertPhotos, result: &result)
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
            logger.notice("Migrated \(result.movedPasswordValues) password values, \(result.assignedPasswordIDs) password IDs, \(result.assignedDocumentIDs) document IDs, \(result.assignedFolderIDs) folder IDs, \(result.encryptedFolderNames) folder names, \(result.assignedSectionKeys) section keys, \(result.assignedFieldKeys) field keys, \(result.convertedDates) dates, \(result.updatedExpiryDates) expiry dates, \(result.convertedPhotoDocuments) photo sets; removed \(result.removedDuplicatePhotos) duplicate photos")
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

    /// Two devices may give the same folder different IDs; the last one saved wins on both. Documents
    /// and passwords point at the folder itself, not its ID, so they stay with it either way. A name in
    /// the old field (not encrypted in iCloud) moves to the encrypted one.
    private static func assignFolderIDs(in context: NSManagedObjectContext, result: inout Result) {
        let request = DDFolder.fetchRequest()
        request.predicate = NSPredicate(format: "identifier == nil OR name != nil")
        guard let folders = try? context.fetch(request) else { return }
        for folder in folders {
            if folder.identifier == nil {
                folder.identifier = UUID()
                result.assignedFolderIDs += 1
            }
            if let name = folder.name {
                // One already in the encrypted field is newer.
                let encrypted = folder.encryptedName ?? ""
                folder.personName = encrypted.isEmpty ? name : encrypted
                result.encryptedFolderNames += 1
            }
        }
    }

    private static func assignSectionKeys(in context: NSManagedObjectContext, result: inout Result) {
        let request = DDSection.fetchRequest()
        request.predicate = NSPredicate(format: "key == nil")
        guard let sections = try? context.fetch(request) else { return }
        for section in sections {
            guard let key = FieldCatalog.sectionKey(forStoredName: section.name ?? "") else { continue }
            section.key = key.rawValue
            result.assignedSectionKeys += 1
        }
    }

    /// Keys fields by their stored title, then turns predefined date fields whose text reads as exactly
    /// one day into real dates. Text that could mean two days (01/02/2032) is left as typed.
    private static func assignFieldKeysAndConvertDates(in context: NSManagedObjectContext, result: inout Result) {
        let request = DDField.fetchRequest()
        request.predicate = NSPredicate(format: "key == nil OR type == nil OR type != %@", Field.FieldType.date.rawValue)
        guard let fields = try? context.fetch(request) else { return }
        for field in fields {
            if field.key == nil, let key = FieldCatalog.fieldKey(forStoredTitle: field.title ?? "") {
                field.key = key.rawValue
                result.assignedFieldKeys += 1
            }
            guard let key = field.key.flatMap(FieldKey.init(rawValue:)), key.type == .date,
                  field.type != Field.FieldType.date.rawValue else { continue }
            let text = field.value ?? ""
            if text.isEmpty {
                field.type = Field.FieldType.date.rawValue
            } else if let day = FieldDate.parseLegacy(text) {
                field.value = day
                field.type = Field.FieldType.date.rawValue
                result.convertedDates += 1
            }
        }
    }

    /// Converts photos to records, removes duplicate records and fills in expiry dates.
    private static func updateDocuments(in context: NSManagedObjectContext, convertPhotos: Bool, result: inout Result) {
        let request = DDDocument.fetchRequest()
        request.relationshipKeyPathsForPrefetching = ["sections", "sections.fields", "photoRecords"]
        guard let documents = try? context.fetch(request) else { return }
        for document in documents {
            if convertPhotos {
                if document.convertLegacyPhotosIfNeeded() {
                    result.convertedPhotoDocuments += 1
                }
                result.removedDuplicatePhotos += document.removeDuplicatePhotoRecords()
            }
            if document.refreshExpiryDate() {
                result.updatedExpiryDates += 1
            }
        }
    }
}
