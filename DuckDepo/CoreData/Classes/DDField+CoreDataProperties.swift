//
//  DDField+CoreDataProperties.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 29/10/2021.
//
//

import Foundation
import CoreData


extension DDField {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DDField> {
        return NSFetchRequest<DDField>(entityName: "DDField")
    }

    @NSManaged public var title: String?
    @NSManaged public var value: String?
    @NSManaged public var order: Int32
    @NSManaged public var type: String?
    /// A `FieldKey` raw value for predefined fields (2.7+).
    @NSManaged public var key: String?
    @NSManaged public var section: DDSection?

}

extension DDField: Comparable {
    public static func < (lhs: DDField, rhs: DDField) -> Bool {
        lhs.order < rhs.order
    }
}

extension DDField {
    
    convenience init(viewContext: NSManagedObjectContext, object: Field, order: Int, section: DDSection?) {
        self.init(context: viewContext)
        key = object.key
        title = object.title
        value = object.value
        type = object.type.rawValue
        self.order = Int32(order)
        self.section = section
    }

    func convert() -> Field {
        Field(key: key, title: title ?? "", value: value ?? "", type: Field.FieldType(rawValue: type ?? "") ?? .string)
    }
}


extension DDField : Identifiable {

}
