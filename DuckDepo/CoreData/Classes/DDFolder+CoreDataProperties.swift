//
//  DDFolder+CoreDataProperties.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/06/2024.
//
//

import Foundation
import CoreData
import UIKit

extension DDFolder {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DDFolder> {
        return NSFetchRequest<DDFolder>(entityName: "DDFolder")
    }

    @NSManaged public var name: String?
    @NSManaged public var order: Int64
    @NSManaged public var documents: Set<DDDocument>?
    @NSManaged public var icon: Data?

}

// MARK: Generated accessors for documents
extension DDFolder {

    @objc(addDocumentsObject:)
    @NSManaged public func addToDocuments(_ value: DDDocument)

    @objc(removeDocumentsObject:)
    @NSManaged public func removeFromDocuments(_ value: DDDocument)

    @objc(addDocuments:)
    @NSManaged public func addToDocuments(_ values: NSSet)

    @objc(removeDocuments:)
    @NSManaged public func removeFromDocuments(_ values: NSSet)
    
    func convert() -> Folder {
        let folder = Folder(icon: getPhoto(),
                            name: self.name ?? "",
                            order:Int(self.order),
                            documnets: getDocument())
        
        return folder
    }

    public func getPhoto() -> UIImage? {
        guard let object = icon else { return nil }
        if let dataArray = try? NSKeyedUnarchiver.unarchivedArrayOfObjects(ofClass: NSData.self, from: object) {
            for data in dataArray {
                if let image = UIImage(data: data as Data) {
                    return image
                }
            }
        }
        return nil
    }
    
    public func getDocument() -> [DDDocument] {
        return Array(documents ?? []).sorted()
    }

}

extension DDFolder : Identifiable {

}
