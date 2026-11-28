//
//  TitleView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 04/07/2022.
//

import SwiftUI

/// The document's name, description, category and whose it is.
struct TitleView: View {

    @Binding var name: String
    @Binding var description: String
    @Binding var documentType: DocumentType
    @Binding var personID: Person.ID?
    /// Off where the stored people mustn't show (the share extension while the app is locked).
    var showsPeople = true
    var isPersonSuggested = false

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
            if showsPeople {
                PersonPicker(personID: $personID, isSuggested: isPersonSuggested)
            }
        }
    }
}

#Preview {
    Form {
        TitleView(name: .constant("Title"), description: .constant("Description"), documentType: .constant(.education),
                  personID: .constant(nil))
    }
}
