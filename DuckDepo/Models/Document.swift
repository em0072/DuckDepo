//
//  File.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 01/11/2021.
//

import Foundation
import UIKit


struct Document: Identifiable {
    
    public var id: UUID
    public var name: String
    public var photos: [UIImage]
    public var sections: [DocSection]
    public var folder: String?

    
    init(id: UUID = UUID(), name: String = "", photos: [UIImage] = [], sections: [DocSection] = [], folder: String? = nil) {
        self.id = id
        self.name = name
        self.photos = photos
        self.sections = sections
        self.folder = folder
    }

    
}
