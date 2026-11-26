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
            ForEach(section.fields) { field in
                FloatingTextView(title: field.title, value: field.value)
            }
        } header: {
            Text(section.name)
        }
    }
}

#Preview {
    List {
        DocSectionSection(section: Document.test.sections.first!)
    }
}
