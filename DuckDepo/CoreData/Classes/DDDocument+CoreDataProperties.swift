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
import CloudKit


extension DDDocument {
    
    static let entityName = "DDDocument"

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DDDocument> {
        return NSFetchRequest<DDDocument>(entityName: DDDocument.entityName)
    }

    @NSManaged public var identifier: UUID?
    @NSManaged public var order: Int16
    @NSManaged public var name: String?
    @NSManaged public var documentDescription: String?
    @NSManaged public var documentType: String?
    @NSManaged public var photoData: Data?
    @NSManaged public var sections: Set<DDSection>?
    @NSManaged public var documentTypeOrder: Int16
    

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
                if let data = img.jpegData(compressionQuality: 0.3) {
                    dataArray.add(data)
                }
            }
        do {
            self.photoData = try NSKeyedArchiver.archivedData(withRootObject: dataArray, requiringSecureCoding: false)
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }

    public func getPhotos() -> [UIImage]? {
        var retVal = [UIImage]()
        guard let object = photoData else { return nil }
        if let dataArray = try? NSKeyedUnarchiver.unarchivedArrayOfObjects(ofClass: NSData.self, from: object) {
            for data in dataArray {
                if let image = UIImage(data: data as Data) {
                    retVal.append(image)
                }
            }
        }
        return retVal
    }

    public func getPhotosAsync(completion: @escaping ([UIImage])->()) {
        var photos = [UIImage]()
        DispatchQueue.global(qos: .userInteractive).async {
            if let photoData = self.photoData {
                if let dataArray = try? NSKeyedUnarchiver.unarchivedArrayOfObjects(ofClass: NSData.self, from: photoData) {
                    for data in dataArray {
                        if let image = UIImage(data: data as Data) {
                            photos.append(image)
                        }
                    }
                }
            }
            DispatchQueue.main.async {
                completion(photos)
            }
        }
    }
    
    public func getSections() -> [DDSection] {
        return Array(sections ?? []).sorted()
    }
}

extension DDDocument {
    
    convenience init(viewContext: NSManagedObjectContext, object: Document, order: Int) {
        self.init(context: viewContext)
        self.identifier = object.id
        self.name = object.name
        self.documentDescription = object.description
        updateType(newType: object.documentType)
        self.order = Int16(order)
        self.addToPhotos(object.photos)
        for index in 0..<object.sections.count {
            let section = object.sections[index]
            self.addToSections(DDSection(viewContext: viewContext, object: section, order: index, document: self))
        }
    }

    
    
    func convert() -> Document {
        var sections = [DocSection]()
        let documentType = DocumentType(rawValue: self.documentType ?? "") ?? .other
        var document = Document(id: self.identifier ?? UUID(), name: self.name ?? "",
                                description: self.documentDescription ?? "", documentType: documentType,
                                photos: self.getPhotos() ?? [], sections: [])
        document.order = Int(self.order)
        for section in getSections() {
            sections.append(section.convert())
        }
        document.sections = sections
        return document
    }
    
    func updateType( newType: DocumentType) {
        self.documentType = newType.rawValue
        self.documentTypeOrder = Int16(newType.typeOrder)
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

extension DDDocument: Identifiable, CoreDataCountable {
}

