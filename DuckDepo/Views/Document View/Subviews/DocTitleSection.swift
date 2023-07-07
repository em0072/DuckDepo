//
//  DocTitleSection.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 06/07/2022.
//

import SwiftUI

struct DocTitleSection: View {
    
    let typeImage: Image
    let typeColor: Color
    let docName: String
    let docDescription: String
    
    init(document: Document) {
        self.typeImage = document.documentType.image
        self.typeColor = document.documentType.iconColor
        self.docName = document.name
        self.docDescription = document.description
    }
    
    var body: some View {
        Section {
            ZStack {
                HStack {
                    typeImage
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, typeColor)
                        .frame(width: 35, height: 35)
                    
                    VStack(alignment: .leading) {
                        Text(docName)
                        let description = docDescription
                        if !description.isEmpty {
                            Text(description)
                                .foregroundColor(Color(UIColor.secondaryLabel))
                        }
                    }
                    Spacer()
                }
            }
        }
    }
}

struct DocTitleSection_Previews: PreviewProvider {
    static var previews: some View {
        DocTitleSection(document: Document.test)
    }
}
