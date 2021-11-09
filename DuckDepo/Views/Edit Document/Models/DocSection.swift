//
//  Section.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 01/11/2021.
//

import Foundation

struct DocSection: Identifiable, Equatable {
    
    static func == (lhs: DocSection, rhs: DocSection) -> Bool {
        lhs.id == rhs.id
    }

    public var id = UUID()
    public var name: String
//    public var order: Int
    public var fields: [Field]
//    public var document: Document?
    
    init(name: String = "", fields: [Field] = []) {
        self.name = name
//        self.order = order
        self.fields = fields
//        self.document = documnet
    }

}
