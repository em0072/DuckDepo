//
//  DDFolder+CoreDataProperties.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 26/10/2021.
//
//

import Foundation
import CoreData


extension DDFolder {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DDFolder> {
        let request = NSFetchRequest<DDFolder>(entityName: "DDFolder")
        let sort = [NSSortDescriptor(keyPath: \DDFolder.order, ascending: true)]
        request.sortDescriptors = sort
        return request
    }

    @NSManaged public var name: String?
    @NSManaged public var order: Int32
    @NSManaged public var documnets: Set<DDDocument>?

}

// MARK: Generated accessors for documnets
extension DDFolder {

    @objc(addDocumnetsObject:)
    @NSManaged public func addToDocumnets(_ value: DDDocument)

    @objc(removeDocumnetsObject:)
    @NSManaged public func removeFromDocumnets(_ value: DDDocument)

    @objc(addDocumnets:)
    @NSManaged public func addToDocumnets(_ values: NSSet)

    @objc(removeDocumnets:)
    @NSManaged public func removeFromDocumnets(_ values: NSSet)

}

extension DDFolder {
    
    static func getRecordsCount() -> Int? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: CDEntity.DDFolder)
        return try? PersistenceController.shared.container.viewContext.count(for: fetchRequest)
    }
    
    public func getDocuments() -> [DDDocument] {
        return Array(documnets ?? []).sorted()
    }

    
}

extension DDFolder : Identifiable {

}

