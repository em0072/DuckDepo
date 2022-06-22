//
//  NameView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 10/11/2021.
//

import SwiftUI

struct TitleView: View {
    
    
    @Binding var name: String
    @Binding var description: String
    @Binding var documentType: DocumentType
    
    
    
    var body: some View {
        Section {
            VStack {
                FloatingTextField(title: "nv_doc_name".localized(), value: $name)
                Divider()
                FloatingTextField(title: "nv_doc_description".localized(), value: $description)
                Divider()
                HStack {
                Text("nv_doc_categoory".localized())
                        .foregroundColor(Color(white: 0.3))
                        .scaleEffect(0.8, anchor: .leading)
                    Spacer()
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(DocumentType.allCases) { type in
                            Button {
                                documentType = type
                            } label: {
                                type.image
                                    .opacity(documentType == type ? 1 : 0.5)
                            }
                            .frame(width: 40, height: 40)
                        }
                    }
                }
                Text(documentType.rawValue.capitalized)
                    .font(.caption)
            }
        } header: {
            Text("nv_main_info")
        }
    }
    
//    func valueChangedForField(with id: UUID, newValue: String) {
//        if FieldIds.name.id == id {
//            self.name = newValue
//        } else if FieldIds.description.id == id {
//            self.description = newValue
//        }
//    }

}

struct NameView_Previews: PreviewProvider {
    static var previews: some View {
        TitleView(name: .constant("nv_doc_name"), description: .constant("Description"), documentType: .constant(.education))
    }
}
