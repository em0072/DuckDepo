//
//  NeuRectButtonStyle.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 05/07/2022.
//

import SwiftUI


struct NeuRectButtonStyle: ButtonStyle {
    
    @Environment(\.isEnabled) private var isEnabled: Bool
    
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
                        if configuration.isPressed || !isEnabled {
                            Image("RectButtonPressed")
                                .layoutPriority(-1)
                        }
                    }
                )
        }
        .animation(nil, value: configuration.isPressed)
    }
}



struct NeuRectButtonStyle_Preview: PreviewProvider {
        
    static var previews: some View {
        ZStack {
            Color.neumorphicBackground
                .ignoresSafeArea()
            Button {
                
            } label: {
                VStack {
                Text("++++====")
                    .font(.title)
                    Text("++++===")
                        .font(.title)
                    Text("++++===")
                        .font(.title)

                }
            }
//            .frame(width: 150, height: 150)
            .buttonStyle(NeuRectButtonStyle())
            .disabled(true)
        }
        
        
    }
}
