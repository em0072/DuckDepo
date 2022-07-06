//
//  NeuCircleToggleButton.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 05/07/2022.
//

import SwiftUI

struct NeuCircleToggleButtonStyle: ButtonStyle {
    
    let shape = Circle()
    
    var isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            configuration.label
                .foregroundColor(.neumorphicButtonText)
                .background(
                    Group {
                        if (!configuration.isPressed && !isSelected)  {
                            shape
                                .fill(Color.neumorphicBackground)
                                .shadow(color: configuration.isPressed ? .clear : .neumorphicTopShadow, radius: 2, x: -2, y: -2)
                                .shadow(color: configuration.isPressed ? .clear : .neumorphicBottomShadow, radius: 2, x: 2, y: 2)
                        }
                    }
                )
                .overlay(
                    Group {
                        if (configuration.isPressed && !isSelected) || isSelected {
                            Image("CircleButtonPressed")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .padding(-1)
                        }
                    }
                )
        }
    }
}


struct NeuCircleToggleButton_Previews: PreviewProvider {
    
    static var previews: some View {
        ZStack {
            Color.neumorphicBackground
                .ignoresSafeArea()
            
            Button{
                
            } label: {
                Image(systemName: "briefcase.circle.fill")
                    .resizable()
                    .symbolRenderingMode(SymbolRenderingMode.palette)
                    .foregroundStyle(.white, .red)
            }
            .frame(width: 50, height: 50)
            .buttonStyle(NeuCircleToggleButtonStyle(isSelected: false))
            
        }
        
        
    }
}
