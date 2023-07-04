//
//  NeuDepoListRowView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 01/07/2022.
//

import SwiftUI

struct DepoListRowView: View {
    
    let image: Image
    let iconColor: Color
    let name: String
    let description: String
    
    let onTap: () -> ()
        
    var body: some View {
            Button {
                onTap()
            } label: {
                buttonView
            }
            .buttonStyle(NeuRectButtonStyle())
        .padding(.horizontal, 16)
    }
}

extension DepoListRowView {
    
    private var buttonView: some View {
        HStack {
            image
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, iconColor)
                .frame(width: 40, height: 40)
                .padding(.trailing, 5)
            VStack(alignment: .leading) {
                Text(name)
                if !description.isEmpty {
                    Text(description)
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
            DepoListRowView(image: testDocument.documentType.image,
                            iconColor: testDocument.documentType.iconColor,
                            name: testDocument.name,
                            description: testDocument.description,
                            onTap: {})
        }
            
            
    }
}
