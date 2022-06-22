//
//  Section Options.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 29/10/2021.
//

import Foundation
import SwiftUI

struct SectionOption: Codable {
    let name: String
    let fields: [FieldOption]
}

struct FieldOption: Codable {
    let name: String
}

struct InputOption: Codable {
    let sections: [SectionOption]
    
    init() {
        var sections = [SectionOption]()
        if let url = Bundle.main.url(forResource: "Predefiened Field Options", withExtension: "json"),
           let data = try? Data(contentsOf: url, options: .dataReadingMapped) {
            do {
                let object = try JSONDecoder().decode(InputOption.self, from: data)
                for section in object.sections {
                    var fields = [FieldOption]()
                    for field in section.fields {
                        fields.append(FieldOption(name: field.name.localized()))
                    }
                    sections.append(SectionOption(name: section.name.localized(), fields: fields))
                }
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


enum DocumentType: String, Codable, Identifiable, CaseIterable, Hashable {
    
    var id: DocumentType { self }

    case identification
    case transport
    case government
    case work
    case medicine
    case education
    case leisure
    case other
    
    var iconName: String {
        switch self {
        case .identification:
            return "person.circle.fill"
        case .transport:
            return "car.circle.fill"
        case .government:
            return "building.columns.circle.fill"
        case .work:
            return "briefcase.circle.fill"
        case .medicine:
            return "stethoscope.circle.fill"
        case .education:
            return "graduationcap.circle.fill"
        case .leisure:
            return "film.circle.fill"
        case .other:
            return "tray.circle.fill"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .identification:
            return .red
        case .transport:
            return .blue
        case .government:
            return .purple
        case .work:
            return .brown
        case .medicine:
            return .green
        case .education:
            return .yellow
        case .leisure:
            return .orange
        case .other:
            return .gray
        }
    }
    
    var typeOrder: Int {
        switch self {
        case .identification:
            return 1
        case .transport:
            return 2
        case .government:
            return 3
        case .work:
            return 4
        case .medicine:
            return 5
        case .education:
            return 6
        case .leisure:
            return 7
        case .other:
            return 8
        }
    }
    
    var image: some View {
        return Image(systemName: self.iconName)
            .resizable()
            .symbolRenderingMode(SymbolRenderingMode.palette)
            .foregroundStyle(.white, self.iconColor)
    }
}
