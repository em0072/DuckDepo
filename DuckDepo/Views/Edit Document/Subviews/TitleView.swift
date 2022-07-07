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
            ZStack {
                VStack(spacing: 0) {
                    VStack {
                        FloatingTextField(title: "nv_doc_name".localized(), value: $name)
                        Divider()
                        FloatingTextField(title: "nv_doc_description".localized(), value: $description)
                            .padding(.top, 4)
                        Divider()
                        categoryTextField()
                            .padding(.top, 4)
                    }
                    .padding(.top, 12)
                    .padding(.horizontal, 16)
                    categoryPickerView()
                }
                NeuSectionBackground()
            }
        }
    }
    
    func categoryTextField() -> some View {
        HStack {
            Text("nv_doc_categoory".localized())
                .foregroundColor(.neumorphicText)
                .font(.footnote)
            Spacer()
            Text(documentType.rawValue.capitalized)
                .font(.footnote)
        }
    }
    
    func categoryPickerView() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(DocumentType.allCases) { type in
                    buttonForCategory(type)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
    }
    
    private func buttonForCategory(_ type: DocumentType) -> some View {
        Button {
            documentType = type
        } label: {
            imageForCategory(type, selcted: documentType == type)
        }
        .buttonStyle(NeuCircleToggleButtonStyle(isSelected: documentType == type))
        .frame(width: 35, height: 35)
    }
    
    private func imageForCategory(_ type: DocumentType, selcted: Bool) -> some View {
        if selcted {
            return type.image
                .symbolRenderingMode(SymbolRenderingMode.palette)
                .foregroundStyle(.white, type.iconColor)
        } else {
            return type.image
                .symbolRenderingMode(SymbolRenderingMode.palette)
                .foregroundStyle(type.iconColor, Color.neumorphicBackground)

        }
    }
}

struct NameView_Previews: PreviewProvider {
    static var previews: some View {
        TitleView(name: .constant("Title"), description: .constant("Description"), documentType: .constant(.education))
    }
}
