//
//  DDSection+CoreDataProperties.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 29/10/2021.
//
//

import Foundation
import CoreData


extension DDSection {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DDSection> {
        return NSFetchRequest<DDSection>(entityName: "DDSection")
    }

    @NSManaged public var name: String?
    @NSManaged public var order: Int32
    @NSManaged public var fields: Set<DDField>?
    @NSManaged public var document: DDDocument?

}

// MARK: Generated accessors for fields
extension DDSection {

    @objc(addFieldsObject:)
    @NSManaged public func addToFields(_ value: DDField)

    @objc(removeFieldsObject:)
    @NSManaged public func removeFromFields(_ value: DDField)

    @objc(addFields:)
    @NSManaged public func addToFields(_ values: NSSet)

    @objc(removeFields:)
    @NSManaged public func removeFromFields(_ values: NSSet)

}

extension DDSection {
    public func getAllFields() -> [DDField] {
        return Array(fields ?? []).sorted()
    }
}

extension DDSection : Identifiable {

}
