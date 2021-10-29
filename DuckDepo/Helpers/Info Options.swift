//
//  Section Options.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 29/10/2021.
//

import Foundation

struct Field {
    var title: String
    var value: String?
    var type: SectionOptions.FieldType
}

enum SectionOptions {
    
    enum FieldType {
        case string
        case date
    }
    
    static let allOptions = [
        "Additional Info",
        "Vehical Info",
        "Document Info",
        "Document Owner"
    ]
        
}

enum FieldOptions {
    
    static let allOptions = [
        Field(title: "Date Of Expiry", type: .date),
        Field(title: "Issue Date", type: .date),
        Field(title: "Issued By", type: .string),
        Field(title: "Nationality", type: .string),
        Field(title: "Sex", type: .string),
        Field(title: "Place Of Birth", type: .string),
        Field(title: "Date Of Birth", type: .date),
        Field(title: "Full Name", type: .string),
        Field(title: "Number", type: .string)
    ]
    
    
}

