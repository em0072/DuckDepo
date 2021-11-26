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

}

extension DDPassword: Identifiable, CoreDataCountable {

}
