//
//  NeumorphicButtonStyle.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 01/07/2022.
//

import SwiftUI


struct NeuRowButtonStyle: ButtonStyle {
    
    let shape = RoundedRectangle(cornerRadius: 10)
        
    func makeBody(configuration: Configuration) -> some View {
        ZStack(alignment: .leading) {
            configuration.label
                .background(
                    Group {
                        if !configuration.isPressed {
                            shape
                                .fill(Color.neumorphicBackground)
                                .shadow(color: configuration.isPressed ? .clear : .neumorphicTopShadow, radius: 2, x: -2, y: -2)
                                .shadow(color: configuration.isPressed ? .clear : .neumorphicBottomShadow, radius: 2, x: 2, y: 2)
                        }
                    }
                )
                .overlay(
                    Group {
                        if configuration.isPressed {
                            Image("RectButtonPressed")
                                .layoutPriority(-1)
                        }
                    }
                )
        }
        .animation(nil, value: configuration.isPressed)
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
                    Text("Hey1")
                    Text("Line 2")
                }
                .padding(30)
            }
            .buttonStyle(NeuRowButtonStyle())
//            DepoListRowView(document: testDocument, selectedDocument: .constant(nil))
        }
        
        
    }
}
