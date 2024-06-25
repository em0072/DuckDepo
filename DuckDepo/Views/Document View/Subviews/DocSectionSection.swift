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
                ForEach(0..<section.fields.count, id: \.self) { index in
                    let field = section.fields[index]
                        FloatingTextView(title: field.title, value: field.value)
            }
        } header: {
            Text(section.name)
        }
    }
}

struct DocSectionSection_Previews: PreviewProvider {
    static var previews: some View {
        List {
            DocSectionSection(section: Document.test.sections.first!)
        }
    }
}
