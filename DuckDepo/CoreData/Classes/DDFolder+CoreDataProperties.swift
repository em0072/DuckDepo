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
    
    static func fetchCount() -> Int {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: CDEntity.DDFolder)
        let count = try? PersistenceController.shared.context.count(for: fetchRequest)
        return count ?? 0
    }
    
    public func fetchDocumentsCount() -> Int {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: CDEntity.DDDOcumnet)
        fetchRequest.predicate = NSPredicate(format: "folder == %@", self)
        let count = try? PersistenceController.shared.context.count(for: fetchRequest)
        return count ?? 0
//        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \.folder, ascending: true)]
    }
    
    public func fetchDocuments() -> [DDDocument] {
        return Array(documnets ?? []).sorted()
    }
    
    static func fetchFolder(with name: String, viewContext: NSManagedObjectContext) -> DDFolder? {
        var fetchedDocument: DDFolder?
        viewContext.performAndWait {
            let fetchRequest = DDFolder.fetchRequest()
            fetchRequest.predicate = DDFolder.predicate(for: name)
            fetchRequest.fetchLimit = 1
            fetchedDocument = (try? fetchRequest.execute())?.first
        }
        return fetchedDocument
    }
    
    static func predicate(for name: String) -> NSPredicate {
        return NSPredicate(format: "name = %@", name as CVarArg)
    }

    
}

extension DDFolder : Identifiable {

}

