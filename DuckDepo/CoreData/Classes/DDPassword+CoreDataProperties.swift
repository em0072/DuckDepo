//
//  DDPassword+CoreDataProperties.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/11/2021.
//
//

import CoreData
import Foundation

extension DDPassword {

    static let entityName = "DDPassword"

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DDPassword> {
        NSFetchRequest<DDPassword>(entityName: DDPassword.entityName)
    }

    /// Optional in the model: version 1 records had no ID until `LegacyDataMigration` assigns one.
    @NSManaged public var id: UUID?
    @NSManaged public var name: String
    @NSManaged public var login: String
    /// Only used by version 1. Values now live in the keychain; `LegacyDataMigration` clears this.
    @NSManaged public var value: String
    @NSManaged public var website: String
    /// The person it belongs to (2.8+).
    @NSManaged public var folder: DDFolder?

    /// `nil` for a record that has no ID yet.
    func convert() -> Password? {
        guard let id else { return nil }
        var password = Password(id: id, name: name, login: login, website: website)
        password.personID = folder?.identifier
        return password
    }

    /// Belongs to the person with this ID, or to no one when there's no such person (any more).
    func setPerson(_ personID: Person.ID?) {
        let person = personID.flatMap { id in managedObjectContext.flatMap { DDFolder.fetch(with: id, in: $0) } }
        if folder != person {
            folder = person
        }
    }

    func update(name: String? = nil, login: String? = nil, website: String? = nil) {
        if let name {
            self.name = name
        }
        if let login {
            self.login = login
        }
        if let website {
            self.website = website
        }
    }

    static func predicate(for id: UUID) -> NSPredicate {
        NSPredicate(format: "id = %@", id as CVarArg)
    }
}

extension DDPassword: Identifiable, CoreDataCountable {
}
