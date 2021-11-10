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
    let name: String
    let fields: [FieldOption]
}

struct FieldOption: Codable {
    let name: String
}
