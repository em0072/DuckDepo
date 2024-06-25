//
//  Folder.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 01/11/2021.
//

import Foundation
import UIKit

struct Folder {
    public var icon: UIImage?
    public var name: String
    public var order: Int
    public var documnets: [DDDocument]
    
}

extension Folder {
    
    static var empty: Folder {
        Folder(icon: nil, name: "", order: 0, documnets: [])
    }
}
