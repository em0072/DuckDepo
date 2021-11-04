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
        name = object.name
        self.order = Int32(order)
        for index in 0..<object.fields.count {
            let field = object.fields[index]
            if !field.value.isEmpty {
                self.addToFields(DDField(viewContext: viewContext, object: field, order: index, section: self))
            }
        }
    }
    
    func convert() -> DocSection {
        var fields = [Field]()
        for field in getAllFields() {
            fields.append(field.convert())
        }
        return DocSection(name: self.name ?? "", fields: fields)
    }

}


extension DDSection : Identifiable {

}
