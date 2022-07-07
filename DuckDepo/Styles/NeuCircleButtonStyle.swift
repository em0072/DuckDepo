//
//  NeumorphicButtonStyle.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 01/07/2022.
//

import SwiftUI


struct NeuCircleButtonStyle: ButtonStyle {
    
    let shape: Circle = Circle()
        
    func makeBody(configuration: Configuration) -> some View {
        ZStack(alignment: .leading) {
            configuration.label
                .foregroundColor(.neumorphicButtonText)
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
                            Image("CircleButtonPressed")
                                .resizable()
                                .layoutPriority(-1)
                        }
                    }
                )
        }
        .animation(nil, value: configuration.isPressed)
        
        
        
//        configuration.label
//            .foregroundColor(.neumorphicButtonText)
//            .contentShape(shape)
//            .background(
//                Group {
//                    if configuration.isPressed {
//                        shape
//                            .fill(Color.neumorphicBackground)
//                            .overlay(
//                                shape
//                                    .stroke(Color.neumorphicTopInnerShadow, lineWidth: 3)
//                                    .blur(radius:1)
//                                    .offset(x: 1, y: 1)
//                                    .mask(shape.fill(LinearGradient(.black, .clear)))
//                            )
//                            .overlay(
//                                shape
//                                    .stroke(Color.neumorphicBottomInnerShadow, lineWidth: 3)
//                                    .blur(radius: 1)
//                                    .offset(x: -1, y: -1)
//                                    .mask(shape.fill(LinearGradient(.clear, .black)))
//                            )
//
//                    } else {
//                        shape
//                            .fill(Color.neumorphicBackground)
//                            .shadow(color: configuration.isPressed ? .clear : .neumorphicTopShadow, radius: 2, x: -2, y: -2)
//                            .shadow(color: configuration.isPressed ? .clear : .neumorphicBottomShadow, radius: 2, x: 2, y: 2)
//                    }
//                }
//            )
//            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}


struct NeumorphicNavigationButtonStyle_Previews: PreviewProvider {
    
    static var previews: some View {
        ZStack {
            Color.neumorphicBackground
                .ignoresSafeArea()
            Button{
                
            } label: {
                Text("!!!")
                    .padding()
            }
            
            .buttonStyle(NeuCircleButtonStyle())
        }
            
            
    }
}
