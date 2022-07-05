//
//  NeumorphicButtonStyle.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 01/07/2022.
//

import SwiftUI


struct NeuRowButtonStyle: ButtonStyle {
        
    func makeBody(configuration: Configuration) -> some View {
        ZStack(alignment: .leading) {
            if !configuration.isPressed {
                Image("DocumentListRow")
                    .layoutPriority(-1)
//                    .resizable()
            }
            configuration.label
                .padding(28)
            if configuration.isPressed {
                Image("DocumentListRowPressed")
                    .layoutPriority(-1)
//                    .resizable()
            }
        }
    }
    
}



struct NeuRowButton_Preview: PreviewProvider {
    
    static let testDocument = Document(name: "Document", description: "Bob Macron", documentType: .identification, folder: "what is folder?")
    
    static var previews: some View {
        ZStack {
            Color.neumorphicBackground
                .ignoresSafeArea()
            Button {
                
            } label: {
                VStack(alignment: .leading) {
                    Text("Hey")
                    Text("Line 2")
                }
            }
            .buttonStyle(NeuRowButtonStyle())
//            DepoListRowView(document: testDocument, selectedDocument: .constant(nil))
        }
        
        
    }
}
