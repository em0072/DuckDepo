//
//  NeumorphicButtonStyle.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 01/07/2022.
//

import SwiftUI


struct NeumorphicRoundedButtonStyle: ButtonStyle {
    
    let shape: RoundedRectangle
    
    init(cornerRadius: CGFloat) {
        self.shape = RoundedRectangle(cornerRadius: cornerRadius)
    }
    
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            if configuration.isPressed {
                configuration.label
                    .contentShape(shape)
                    .background(
                        shape
                            .fill(Color.neumorphicBackground)
                    )
                    .overlay(
                        shape
                            .stroke(Color.neumorphicTopInnerShadow, lineWidth: 3)
                            .blur(radius:1)
                            .offset(x: 1, y: 1)
                            .mask(shape.fill(LinearGradient(.black, .clear)))
                    )
                    .overlay(
                        shape
                            .stroke(Color.neumorphicBottomInnerShadow, lineWidth: 3)
                            .blur(radius: 1)
                            .offset(x: -1, y: -1)
                            .mask(shape.fill(LinearGradient(.clear, .black)))
                    )
            } else {
                configuration.label
                    .contentShape(shape)
                    .background(
                        shape
                            .fill(Color.neumorphicBackground)
                    )
                    .shadow(color: configuration.isPressed ? .clear : .neumorphicTopShadow, radius: 2, x: -2, y: -2)
                    .shadow(color: configuration.isPressed ? .clear : .neumorphicBottomShadow, radius: 2, x: 2, y: 2)
                
            }
        }
        .animation(nil, value: configuration.isPressed)
    }
}


struct NeumorphicRoundedButtonStyle_Previews: PreviewProvider {
    
    static let testDocument = Document(name: "Document", description: "Bob Macron", documentType: .identification, folder: "what is folder?")
    
    static var previews: some View {
        ZStack {
            Color.neumorphicBackground
                .ignoresSafeArea()
            DepoListRowView(icon: Self.testDocument.documentType.image,
                            iconColor: Self.testDocument.documentType.iconColor,
                            name: Self.testDocument.name,
                            description: Self.testDocument.description)
        }
        
        
    }
}
