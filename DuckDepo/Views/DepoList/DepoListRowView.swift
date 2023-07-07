//
//  NeuDepoListRowView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 01/07/2022.
//

import SwiftUI

struct DepoListRowView: View {
    
    var icon: Image
    var iconColor: Color
    var name: String
    var description: String
    
    var body: some View {
        HStack {
            icon
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, iconColor)
                .frame(width: 40, height: 40)
                .padding(.trailing, 5)
            VStack(alignment: .leading) {
                Text(name)
                    .foregroundColor(.primary)
                if !description.isEmpty {
                    Text(description)
                        .foregroundColor(Color.secondary)
                }
            }
            .padding(.leading, 5)
            Spacer()
        }
        .padding(.vertical, 2)
    }
    
}

struct NeuDepoListRowView_Previews: PreviewProvider {
    
    static let testDocument = Document(name: "Document", description: "Bob Macron", documentType: .identification, folder: "what is folder?")

    static var previews: some View {
        List {
            DepoListRowView(icon: Self.testDocument.documentType.image,
                            iconColor: Self.testDocument.documentType.iconColor,
                            name: Self.testDocument.name,
                            description: Self.testDocument.description)
        }
    }
}
