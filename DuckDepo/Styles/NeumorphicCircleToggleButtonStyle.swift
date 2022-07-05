////
////  NeumorphicCircleToggleButtonStyle.swift
////  DuckDepo
////
////  Created by Evgeny Mitko on 03/07/2022.
////
//
//import SwiftUI
//
//struct NeumorphicCircleToggleButtonStyle: ButtonStyle {
//    
//    let shape: Circle = Circle()
//    var isSelected: Bool
//    
//    
//    func makeBody(configuration: Configuration) -> some View {
//        ZStack {
//        if (configuration.isPressed && !isSelected) || (!configuration.isPressed && isSelected) {
//            configuration.label
//                .foregroundColor(.neumorphicButtonText)
//                .contentShape(shape)
//                .overlay(
//                    shape
//                        .stroke(Color.neumorphicTopInnerShadow, lineWidth: 3)
//                        .blur(radius:1)
//                        .offset(x: 1, y: 1)
//                        .mask(shape.fill(LinearGradient(.black, .clear)))
//                )
//                .overlay(
//                    shape
//                        .stroke(Color.neumorphicBottomInnerShadow, lineWidth: 3)
//                        .blur(radius: 1)
//                        .offset(x: -1, y: -1)
//                        .mask(shape.fill(LinearGradient(.clear, .black)))
//                )
//        } else if (!configuration.isPressed && !isSelected) || (configuration.isPressed && isSelected) {
//            configuration.label
//                .foregroundColor(.neumorphicButtonText)
//                .contentShape(shape)
//                .shadow(color: .neumorphicTopShadow, radius: 2, x: -2, y: -2)
//                .shadow(color: .neumorphicBottomShadow, radius: 2, x: 2, y: 2)
//        }
//        }
//        .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
//
////        configuration.label
////            .foregroundColor(.neumorphicButtonText)
////            .contentShape(shape)
////            .background(
////                Group {
////                    if (configuration.isPressed && !isSelected) || (!configuration.isPressed && isSelected) {
////                        innerShadow()
////                    } else if (!configuration.isPressed && !isSelected) || (configuration.isPressed && isSelected) {
////                        outerShadow()
////                    }
////                }
////            )
////            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
//    }
//    
//    private func innerShadow() -> some View {
//        shape
//            .fill(Color.neumorphicBackground)
//            .overlay(
//                shape
//                    .stroke(Color.neumorphicTopInnerShadow, lineWidth: 3)
//                    .blur(radius:1)
//                    .offset(x: 1, y: 1)
//                    .mask(shape.fill(LinearGradient(.black, .clear)))
//            )
//            .overlay(
//                shape
//                    .stroke(Color.neumorphicBottomInnerShadow, lineWidth: 3)
//                    .blur(radius: 1)
//                    .offset(x: -1, y: -1)
//                    .mask(shape.fill(LinearGradient(.clear, .black)))
//            )
//    }
//    
//    private func outerShadow() -> some View {
//        shape
//            .fill(Color.neumorphicBackground)
//            .shadow(color: .neumorphicTopShadow, radius: 2, x: -2, y: -2)
//            .shadow(color: .neumorphicBottomShadow, radius: 2, x: 2, y: 2)
//    }
//}
//
//
//struct NeumorphicCircleToggleButtonStyle_Previews: PreviewProvider {
//    
//    static var previews: some View {
//        ZStack {
//            Color.neumorphicBackground
//                .ignoresSafeArea()
//            Button{
//                
//            } label: {
//                Text("!!!")
//                    .padding()
//            }
//            
//            .buttonStyle(NeumorphicCircleToggleButtonStyle(isSelected: false))
//        }
//            
//            
//    }
//}
