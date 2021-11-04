//
//  DDDocument+CoreDataProperties.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 26/10/2021.
//
//

import Foundation
import CoreData
import UIKit


extension DDDocument {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DDDocument> {
        return NSFetchRequest<DDDocument>(entityName: "DDDocument")
    }

    @NSManaged public var identifier: UUID?
    @NSManaged public var info: String?
    @NSManaged public var order: Int32
    @NSManaged public var name: String?
    @NSManaged public var number: String?
    @NSManaged public var photos: Data?
    @NSManaged public var folder: DDFolder?
    @NSManaged public var sections: Set<DDSection>?

}

// MARK: Generated accessors for sections
extension DDDocument {

    @objc(addSectionsObject:)
    @NSManaged public func addToSections(_ value: DDSection)

    @objc(removeSectionsObject:)
    @NSManaged public func removeFromSections(_ value: DDSection)

    @objc(addSections:)
    @NSManaged public func addToSections(_ values: NSSet)

    @objc(removeSections:)
    @NSManaged public func removeFromSections(_ values: NSSet)

}

extension DDDocument: Comparable {
    public static func < (lhs: DDDocument, rhs: DDDocument) -> Bool {
        lhs.order < rhs.order
    }
}

extension DDDocument {
    
    public func addToPhotos(_ images: [UIImage]) {
        let dataArray = NSMutableArray()
            for img in images {
                if let data = img.jpegData(compressionQuality: 0.5) {
                    dataArray.add(data)
                }
            }
        do {
            self.photos = try NSKeyedArchiver.archivedData(withRootObject: dataArray, requiringSecureCoding: false)
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }

    public func getPhotos() -> [UIImage]? {
        var retVal = [UIImage]()
            guard let object = photos else { return nil }
        if let dataArray = try? NSKeyedUnarchiver.unarchivedArrayOfObjects(ofClass: NSData.self, from: object) { //NSKeyedUnarchiver.unarchivedObject(ofClass: NSArray.self, from: object) {
                for data in dataArray {
                    if let image = UIImage(data: data as Data) {
                        retVal.append(image)
                    }
                }
            }
            return retVal
    }
    
    public func getSections() -> [DDSection] {
        return Array(sections ?? []).sorted()
    }
}

extension DDDocument {
    convenience init(viewContext: NSManagedObjectContext, object: Document, order: Int, folder: DDFolder) {
        self.init(context: viewContext)
        self.identifier = object.id
        self.name = object.name
        self.order = Int32(order)
        self.addToPhotos(object.photos)
        for index in 0..<object.sections.count {
            let section = object.sections[index]
            self.addToSections(DDSection(viewContext: viewContext, object: section, order: index, document: self))
        }
        self.folder = folder
    }
    
    func update(with object: Document, and folder: DDFolder, viewContext: NSManagedObjectContext) {
        self.name = object.name
        self.photos = nil
        addToPhotos(object.photos)
        self.sections = nil
        for index in 0..<object.sections.count {
            let section = object.sections[index]
            self.addToSections(DDSection(viewContext: viewContext, object: section, order: index, document: self))
        }
        self.folder = folder
    }
    
    func convert() -> Document {
        var sections = [DocSection]()
        var document = Document(id: self.identifier ?? UUID(), name: self.name ?? "", photos: getPhotos() ?? [], sections: [], folder: self.folder?.name ?? "")
        for section in getSections() {
            sections.append(section.convert())
        }
        document.sections = sections
        return document
    }
    
    static func fetchDocument(with id: UUID, viewContext: NSManagedObjectContext) -> DDDocument? {
        var fetchedDocument: DDDocument?
        viewContext.performAndWait {
            let fetchRequest = DDDocument.fetchRequest()
            fetchRequest.predicate = DDDocument.predicate(for: id)
            fetchRequest.fetchLimit = 1
            fetchedDocument = (try? fetchRequest.execute())?.first
        }
        return fetchedDocument
    }
    
    static func predicate(for id: UUID) -> NSPredicate {
        return NSPredicate(format: "identifier = %@", id as CVarArg)
    }
}

extension DDDocument : Identifiable {
    
}
