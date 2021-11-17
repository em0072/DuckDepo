//
//  OverviewSection.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 16/11/2021.
//

import SwiftUI

struct OverviewSection: View {
    
    @Binding var documentCount: Int
    
//    var documentsCount: Int {
//        db.fetchDocumentCount()
//    }

    var body: some View {
        Section {
            Text(documentCountText)
        } header: {
            Text("Storage")
        }
    }
    
    
    var documentCountText: String {
        var string = "\(documentCount) "
        if documentCount == 1 {
            string += "document"
        } else {
            string += "documents"
        }
        return string
    }
}

struct OverviewSection_Previews: PreviewProvider {
    static var previews: some View {
        OverviewSection(documentCount: .constant(0))
    }
}
