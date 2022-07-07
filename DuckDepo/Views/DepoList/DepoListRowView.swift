//
//  NeuDepoListRowView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 01/07/2022.
//

import SwiftUI

struct DepoListRowView: View {
    
    var document: Document
    @Binding var selectedDocument: Document?
    
//    var pressAction: ((Document)->())?
    
    var body: some View {
            Button {
                selectedDocument = document
            } label: {
                buttonView()
            }
            .buttonStyle(NeuRectButtonStyle())
        .padding(.horizontal, 16)
    }
    
    private func buttonView() -> some View {
        HStack {
            document.documentType.image
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, document.documentType.iconColor)
                .frame(width: 40, height: 40)
                .padding(.trailing, 5)
            VStack(alignment: .leading) {
                Text(document.name)
                if !document.description.isEmpty {
                    Text(document.description)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
            }
            .padding(.leading, 5)
            Spacer()
        }
        .padding(16)
    }
}

struct NeuDepoListRowView_Previews: PreviewProvider {
    
    static let testDocument = Document(name: "Document", description: "Bob Macron", documentType: .identification, folder: "what is folder?")

    static var previews: some View {
        ZStack {
            Color.neumorphicBackground
                .ignoresSafeArea()
            DepoListRowView(document: testDocument, selectedDocument: .constant(nil))
        }
            
            
    }
}
