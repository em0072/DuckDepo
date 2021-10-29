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

    @NSManaged public var info: String?
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
}

extension DDDocument : Identifiable {
    
}
