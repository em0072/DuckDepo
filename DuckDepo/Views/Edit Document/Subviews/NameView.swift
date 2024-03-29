//
//  NameView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 10/11/2021.
//

import SwiftUI

struct NameView: View, FloatingTextFieldDelegate {
    
    @Binding var name: String
    @Binding var documentType: DocumentType
    
    var body: some View {
        Section {
            VStack {
                FloatingTextField(title: "nv_doc_name".localized(), value: name, delegate: self)
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
    
    func valueChangedForField(with id: UUID, newValue: String) {
        self.name = newValue
    }

}

struct NameView_Previews: PreviewProvider {
    static var previews: some View {
        NameView(name: .constant("nv_doc_name"), documentType: .constant(.education))
    }
}
