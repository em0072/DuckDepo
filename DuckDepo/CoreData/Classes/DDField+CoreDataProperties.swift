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
    @NSManaged public var section: DDSection?

}

extension DDField: Comparable {
    public static func < (lhs: DDField, rhs: DDField) -> Bool {
        lhs.order < rhs.order
    }
    
    
}

extension DDField : Identifiable {

}
