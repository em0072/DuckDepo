//
//  DepoListRowView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 17/06/2022.
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
            .buttonStyle(ListCellButtonStyle())
        .padding(.horizontal)
        .padding(.vertical, 5)
    }
    
    private func buttonView() -> some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 15)
//                .frame(height: 100)
                .foregroundColor(Color(UIColor.secondarySystemGroupedBackground))
            
            HStack {
                document.documentType.image
                    .frame(width: 40, height: 40)
                VStack(alignment: .leading) {
                    Text(document.name)
                    if !document.description.isEmpty {
                        Text(document.description)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                    }
//                    Text("\(document.order ?? 0)")
                }
            }
            .padding()
        }
    }
}

struct DepoListRowView_Previews: PreviewProvider {
    
    static let testDocument = Document(name: "Document", description: "Bob Macron", documentType: .identification, folder: "what is folder?")
    
    static var previews: some View {
        DepoListRowView(document: DepoListRowView_Previews.testDocument, selectedDocument: .constant(nil))
    }
}
