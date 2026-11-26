//
//  DocSectionSection.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 19/06/2022.
//

import SwiftUI

struct DocSectionSection: View {

    let section: DocSection

    var body: some View {
        Section {
            ForEach(section.fields) { field in
                FieldValueRow(title: field.displayTitle, value: field.displayValue, isSecret: field.isSensitive)
            }
        } header: {
            Text(section.displayName)
        }
    }
}

#Preview {
    List {
        DocSectionSection(section: Document.test.sections.first!)
    }
}
