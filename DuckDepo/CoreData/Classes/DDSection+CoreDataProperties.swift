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
    /// A `SectionKey` raw value for predefined sections (2.7+).
    @NSManaged public var key: String?
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

extension DDSection: Comparable {
    public static func < (lhs: DDSection, rhs: DDSection) -> Bool {
        lhs.order < rhs.order
    }
}



extension DDSection {
    public func getAllFields() -> [DDField] {
        return Array(fields ?? []).sorted()
    }
    
    public func fieldCount() -> Int {
        return getAllFields().count
    }
}

extension DDSection {
    
    convenience init(viewContext: NSManagedObjectContext, object: DocSection, order: Int, document: DDDocument?) {
        self.init(context: viewContext)
        key = object.key
        name = object.name
        self.order = Int32(order)
        self.document = document
        // Empty fields are kept: the user added them on purpose and may fill them in later.
        for (index, field) in object.fields.enumerated() {
            addToFields(DDField(viewContext: viewContext, object: field, order: index, section: self))
        }
    }

    func convert() -> DocSection {
        DocSection(key: key, name: name ?? "", fields: getAllFields().map { $0.convert() })
    }

}


extension DDSection : Identifiable {

}
