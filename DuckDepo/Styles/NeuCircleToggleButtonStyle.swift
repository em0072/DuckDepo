//
//  NeuCircleToggleButton.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 05/07/2022.
//

import SwiftUI

struct NeuCircleToggleButtonStyle: ButtonStyle {
    
    var isSelected: Bool
    
    
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            GeometryReader { proxy in
            if (!configuration.isPressed && !isSelected)  {
                Image("CircleButton")
//                    .resizable()
//                    .aspectRatio(contentMode: .fit)
//                    .layoutPriority(-1)
            }
            configuration.label
                .foregroundColor(.neumorphicButtonText)
                .padding(.horizontal, proxy.size.width * 0.135)
                .padding(.vertical, proxy.size.height * 0.135)

            if (configuration.isPressed && !isSelected) || isSelected {
                Image("CircleButtonPressed")
//                    .resizable()
//                    .aspectRatio(contentMode: .fit)
//                    .layoutPriority(-1)
                    .allowsTightening(false)
            }
        }
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
            .frame(width: 200, height: 200)
            .buttonStyle(NeuCircleToggleButtonStyle(isSelected: false))

        }
        
        
    }
}
