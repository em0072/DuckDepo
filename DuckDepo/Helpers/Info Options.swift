//
//  Section Options.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 29/10/2021.
//

import Foundation

struct InputOption: Codable {
    let sections: [SectionOption]
    
    init() {
        var sections = [SectionOption]()
        if let url = Bundle.main.url(forResource: "Predefiened Field Options", withExtension: "json"),
           let data = try? Data(contentsOf: url, options: .dataReadingMapped) {
            do {
                let object = try JSONDecoder().decode(InputOption.self, from: data)
                print(object)
                sections = object.sections
            } catch {
                print(error)
            }
        }
        self.sections = sections
    }
    
    func listOfSectionNames() -> [String] {
        sections.map { $0.name }
    }
}

struct SectionOption: Codable {
//    var id: UUID = UUID()
    let name: String
    let fields: [FieldOption]
}

struct FieldOption: Codable {
//    var id: UUID = UUID()
    let name: String
}

enum SectionOptions {
        
    static let allOptions = [
        "Additional Info",
        "Vehical Info",
        "Document Info",
        "Document Owner"
    ]
        
}

enum FieldOptions {
//
//    static let allOptions = [
//        Field(title: "Date Of Expiry", order: 1, type: .date),
//        Field(title: "Issue Date", order: 2, type: .date),
//        Field(title: "Issued By", order: 3, type: .string),
//        Field(title: "Nationality", order: 4, type: .string),
//        Field(title: "Sex", order: 5, type: .string),
//        Field(title: "Place Of Birth", order: 6, type: .string),
//        Field(title: "Date Of Birth", order: 7, type: .date),
//        Field(title: "Full Name", order: 8, type: .string),
//        Field(title: "Number", order: 9, type: .string)
//    ]
    
    static let allOptions = [
        "Date Of Expiry",
        "Issue Date",
       "Issued By",
        "Nationality",
        "Sex",
        "Place Of Birth",
        "Date Of Birth",
        "Full Name",
        "Number"
    ]

    
    
}

