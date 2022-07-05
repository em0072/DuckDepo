//
//  Neumorphic.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 01/07/2022.
//

import SwiftUI

extension View {
    
    func neumorphicOuter(_ enabled: Bool = true) -> some View {
        self
            .shadow(color:enabled ? .neumorphicTopShadow : .clear, radius: 2, x: -2, y: -2)
            .shadow(color:enabled ?  .neumorphicBottomShadow : .clear, radius: 2, x: 2, y: 2)
    }
    
    func neumorphicRoundedInner(cornerRadius: CGFloat) -> some View {
        self
//            .background(
//                Group {
//                    if enabled {
//                    RoundedRectangle(cornerRadius: cornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .stroke(Color.neumorphicTopInnerShadow, lineWidth: 3)
                                .blur(radius:1)
                                .offset(x: 1, y: 1)
                                .mask(
                                    RoundedRectangle(cornerRadius: cornerRadius)
                                        .fill(LinearGradient(.black, .clear))
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .stroke(Color.neumorphicBottomInnerShadow, lineWidth: 3)
                                .blur(radius: 1)
                                .offset(x: -1, y: -1)
                                .mask(
                                    RoundedRectangle(cornerRadius: cornerRadius)
                                        .fill(LinearGradient(.clear, .black))
                                )
                        )
//                    }
//                }
//            )
    }
    
    func neumorphicCircleInner() -> some View {
        self
//            .background(
//                Group {
//                    if enabled {
//                    Circle()
                            .overlay(
                                Circle()
                                .stroke(Color.neumorphicTopInnerShadow, lineWidth: 3)
                                .blur(radius:1)
                                .offset(x: 1, y: 1)
                                .mask(
                                    Circle()
                                        .fill(LinearGradient(.black, .clear))
                                )
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.neumorphicBottomInnerShadow, lineWidth: 3)
                                .blur(radius: 1)
                                .offset(x: -1, y: -1)
                                .mask(
                                    Circle()
                                        .fill(LinearGradient(.clear, .black))
                                )
                        )
//                    }
//                }
//            )
    }

    
}

extension Shape {
    
    func neumorphicInner(_ fillColor: Color? = nil) -> some View {
        self
            .fill(fillColor ?? .neumorphicBackground)
            .overlay(
                self
                    .stroke(Color.neumorphicTopInnerShadow, lineWidth: 3)
                    .blur(radius:1)
                    .offset(x: 1, y: 1)
                    .mask(self.fill(LinearGradient(.black, .clear)))
            )
            .overlay(
                self
                    .stroke(Color.neumorphicBottomInnerShadow, lineWidth: 3)
                    .blur(radius: 1)
                    .offset(x: -1, y: -1)
                    .mask(self.fill(LinearGradient(.clear, .black)))
            )
    }
    
}
