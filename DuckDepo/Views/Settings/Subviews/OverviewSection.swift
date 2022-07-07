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
    

    var body: some View {
        Section {
            ZStack {
                HStack {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(documentCountText)
                        Divider()
                        Text(passwordCountText)
                    }
                    Spacer()
                }
                .padding()
                
                NeuSectionBackground()
            }
        } header: {
            NeuSectionTitle(title: "sv_storage".localized())
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
        ScrollView {
            VStack {
                OverviewSection(documentCount: .constant(5), passwordCount: .constant(0))
            }
        }
    }
}
