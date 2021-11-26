//
//  NoDocumentSelectedView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 17/11/2021.
//

import SwiftUI

struct NoSelectionViewView: View {
    
    enum ViewType: String {
        case document
        case password
    }
    
    var type: ViewType
    
    var body: some View {
        Text("Welcome to DuckDepo!")
            .font(.title)
            .padding()
        Text("Currently, no \(type.rawValue) selected. Please select a \(type.rawValue) on the left panel.")
            .font(.body)
    }
}

struct NoDocumentSelectedView_Previews: PreviewProvider {
    static var previews: some View {
        NoSelectionViewView(type: .password)
    }
}
