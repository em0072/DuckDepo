//
//  File.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 01/11/2021.
//

import Foundation
import UIKit


struct Document: Identifiable, Hashable {
    
    public var id: UUID
    public var name: String
    public var description: String
    public var documentType: DocumentType
    public var photos: [UIImage]
    public var sections: [DocSection]
    public var folder: String?
    public var order: Int?


    
    init(id: UUID = UUID(), name: String = "", description: String = "",
         documentType: DocumentType = .identification, photos: [UIImage] = [],
         sections: [DocSection] = [], folder: String? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.documentType = documentType
        self.photos = photos
        self.sections = sections
        self.folder = folder
    }

    
}
