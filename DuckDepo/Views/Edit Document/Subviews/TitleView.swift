//
//  TitleView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 04/07/2022.
//

import SwiftUI

/// The document's name, description and category.
struct TitleView: View {

    @Binding var name: String
    @Binding var description: String
    @Binding var documentType: DocumentType

    var body: some View {
        Section {
            LabeledTextField(title: "nv_doc_name".localized(), value: $name, kind: .name)
            LabeledTextField(title: "nv_doc_description".localized(), value: $description, kind: .name)
            Picker("nv_doc_categoory", selection: $documentType) {
                ForEach(DocumentType.allCases) { type in
                    Label(type.localizedName, systemImage: type.symbolName)
                        .tag(type)
                }
            }
        }
    }
}

#Preview {
    Form {
        TitleView(name: .constant("Title"), description: .constant("Description"), documentType: .constant(.education))
    }
}
