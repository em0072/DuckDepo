//
//  Field.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 01/11/2021.
//

import SwiftUI

struct Field: Identifiable, Equatable {
    
    enum FieldType: String {
        case string
        case date
    }

    var id = UUID()
    var title: String
    var value: String = ""
//    var order: Int
    var type: Field.FieldType = .string
}
