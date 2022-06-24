//
//  NoDocumentSelectedView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 17/11/2021.
//

import SwiftUI

struct NoSelectionViewView: View {
    
    enum ViewType {
        case document
        case password
        
        var title: LocalizedStringKey {
            switch self {
            case .document:
                return "no_doc_view_body_docs"
            case .password:
                return "no_doc_view_body_passwords"
            }
            
        }
    }
    
    var type: ViewType
    
    var body: some View {
        VStack {
            Image(systemName: "arrow.turn.up.left")
                .font(.largeTitle)
            Text("no_doc_view_title")
                .font(.title)
                .padding()
            Text(type.title)
                .font(.body)
        }
    }
}

struct NoDocumentSelectedView_Previews: PreviewProvider {
    static var previews: some View {
        NoSelectionViewView(type: .password)
    }
}
