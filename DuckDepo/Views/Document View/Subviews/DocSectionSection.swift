//
//  DocSectionSection.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 06/07/2022.
//

import SwiftUI

struct DocSectionSection: View {
    
    let section: DocSection
    
    var body: some View {
        Section {
            ZStack {
                VStack {
                    ForEach(section.fields) { field in
                        if let fieldTitle = field.title, let fieldValue = field.value {
                            VStack {
                                FloatingTextView(title: fieldTitle, value: fieldValue)
                                Divider()
                            }
//                            .padding(.horizontal, 16)
//                            .padding(.vertical, 12)

                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                NeuSectionBackground()
            }
        } header: {
            NeuSectionTitle(title: section.name)
        }
    }
}

struct DocSectionSection_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            DocSectionSection(section: Document.test.sections.first!)
        }
    }
}
