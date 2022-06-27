//
//  DDPassword+CoreDataProperties.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/11/2021.
//
//

import Foundation
import CoreData


extension DDPassword {

    static let entityName = "DDPassword"

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DDPassword> {
        return NSFetchRequest<DDPassword>(entityName: DDPassword.entityName)
    }
    
    

    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var login: String
    @NSManaged public var value: String
    @NSManaged public var website: String
    
    var websiteURL: URL? {
        if website.starts(with: "http") {
            return URL(string: website)
        } else {
            return URL(string: "http://\(website)")
        }
    }

    func convert() -> Password {
        let password = Password(id: self.id, name: self.name, login: self.login, website: self.website)
        return password
    }
    
    func update(name: String? = nil , login: String? = nil, website: String? = nil) {
        if let name = name {
            self.name = name
        }
        if let login = login {
            self.login = login
        }
        if let website = website {
            self.website = website
        }
    }

    static func predicate(for id: UUID) -> NSPredicate {
        return NSPredicate(format: "id = %@", id as CVarArg)
    }

    
}

extension DDPassword: Identifiable, CoreDataCountable {

}
