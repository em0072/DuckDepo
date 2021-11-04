//
//  CoreDataConverter.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 01/11/2021.
//

import Foundation

//class CoreDataConverter {
//    
//    static let shared = CoreDataConverter()
//    private let viewContext = PersistenceController.shared.container.viewContext
//    
//    func convertToDDField(_ field: Field) -> DDField {
//        
//    }
//    
//    func convertToField(_ ddfield: DDField) -> Field {
//        let title = ddfield.title
//        let value = ddfield.value
//        let order = ddfield.order
//        var type = Field.FieldType.string
//        if let typeString = ddfield.type, let convertedType = Field.FieldType.init(rawValue: typeString)) {
//            type = convertedType
//        }
//        return Field(title: title, value: value, order: order type: type)
//    }
//}
