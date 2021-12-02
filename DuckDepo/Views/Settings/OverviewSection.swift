//
//  OverviewSection.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 16/11/2021.
//

import SwiftUI

struct OverviewSection: View {
    
    @Binding var documentCount: Int
    @Binding var passwordCount: Int
    
//    var documentsCount: Int {
//        db.fetchDocumentCount()
//    }

    var body: some View {
        Section {
            Text(documentCountText)
            Text(passwordCountText)
        } header: {
            Text("Storage")
        }
    }
    
    
    var documentCountText: String {
        return "sv_document_count".localizedPlurual(documentCount)
    }
    
    var passwordCountText: String {
        return "sv_password_count".localizedPlurual(passwordCount)
    }

}

struct OverviewSection_Previews: PreviewProvider {
    static var previews: some View {
        OverviewSection(documentCount: .constant(5), passwordCount: .constant(10))
    }
}
