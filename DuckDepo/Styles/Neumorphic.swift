//
//  Neumorphic.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 01/07/2022.
//

import SwiftUI

extension View {
    
    func neumorphicOuter() -> some View {
        self
            .shadow(color:.neumorphicTopShadow, radius: 2, x: -2, y: -2)
            .shadow(color:.neumorphicBottomShadow, radius: 2, x: 2, y: 2)
    }
    
    func neumorphicRoundedInner(cornerRadius: CGFloat) -> some View {
        self
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .stroke(Color.neumorphicTopInnerShadow, lineWidth: 2)
                                .blur(radius:1)
                                .offset(x: 1, y: 1)
                                .mask(
                                    RoundedRectangle(cornerRadius: cornerRadius)
                                        .fill(Color.black)
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .stroke(Color.neumorphicBottomInnerShadow, lineWidth: 2)
                                .blur(radius: 1)
                                .offset(x: -1, y: -1)
                                .mask(
                                    RoundedRectangle(cornerRadius: cornerRadius)
                                        .fill(Color.black)

                                )
                        )
    }
}
