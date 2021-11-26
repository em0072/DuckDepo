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
        var string = "\(documentCount) "
        if documentCount == 1 {
            string += "document"
        } else {
            string += "documents"
        }
        return string
    }
    
    var passwordCountText: String {
        var string = "\(passwordCount) "
        if passwordCount == 1 {
            string += "password"
        } else {
            string += "passwords"
        }
        return string
    }

}

struct OverviewSection_Previews: PreviewProvider {
    static var previews: some View {
        OverviewSection(documentCount: .constant(5), passwordCount: .constant(10))
    }
}
