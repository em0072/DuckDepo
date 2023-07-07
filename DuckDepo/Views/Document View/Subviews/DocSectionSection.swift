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
                    ForEach(0..<section.fields.count, id: \.self) { index in
                        let field = section.fields[index]
                            VStack {
                                FloatingTextView(title: field.title, value: field.value)
                                if index != section.fields.count - 1 {
                                    Divider()
                                }
                        }
                    }
                }
            }
        } header: {
            Text(section.name)
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
