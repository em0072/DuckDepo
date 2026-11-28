//
//  DDFolder+CoreDataProperties.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/06/2024.
//
//

import CoreData
import Foundation

/// A person (see `Person`). The entity keeps its old name: CloudKit record types can't be renamed.
extension DDFolder {

    static let entityName = "DDFolder"

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DDFolder> {
        NSFetchRequest<DDFolder>(entityName: DDFolder.entityName)
    }

    /// Optional in the model, like every attribute CloudKit syncs. `LegacyDataMigration` gives one to a
    /// folder made before version 2.8.
    @NSManaged public var identifier: UUID?
    /// The person's name, encrypted in iCloud (model 5). Read and written through `personName`.
    @NSManaged public var encryptedName: String?
    /// Not encrypted in iCloud, and that can't change for a field that's already there, so it stays
    /// empty. A folder made before 2.8 may have a name here, which `LegacyDataMigration` moves.
    @NSManaged public var name: String?
    @NSManaged public var order: Int64
    /// A `PersonColor` raw value.
    @NSManaged public var color: String?
    /// Unused: from the folders version 1 planned.
    @NSManaged public var icon: Data?
    @NSManaged public var documents: Set<DDDocument>?
    @NSManaged public var passwords: Set<DDPassword>?

    /// Kept only in the encrypted field.
    var personName: String {
        get {
            encryptedName ?? name ?? ""
        }
        set {
            if encryptedName != newValue {
                encryptedName = newValue
            }
            if name != nil {
                name = nil
            }
        }
    }

    /// Nil for a folder without an ID yet.
    func convert() -> Person? {
        guard let identifier else { return nil }
        return Person(id: identifier,
                      name: personName,
                      color: color.flatMap(PersonColor.init(rawValue:)) ?? .fallback(for: identifier),
                      order: Int(clamping: order))
    }

    var counts: PersonCounts {
        PersonCounts(documents: documents?.count ?? 0, passwords: passwords?.count ?? 0)
    }

    static func fetch(with id: UUID, in context: NSManagedObjectContext) -> DDFolder? {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "identifier = %@", id as CVarArg)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }
}

extension DDFolder: Identifiable, CoreDataCountable {
}
