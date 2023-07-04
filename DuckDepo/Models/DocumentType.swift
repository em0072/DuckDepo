//
//  DocumentType.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 12/07/2022.
//

import SwiftUI


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
    
    var image: Image {
        return Image(systemName: self.iconName)
            .resizable()
    }
}
