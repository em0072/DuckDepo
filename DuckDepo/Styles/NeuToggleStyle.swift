//
//  NeuToggleStyle.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 07/07/2022.
//

import SwiftUI

struct NeuToggleStyle: ToggleStyle {
    var onColor = Color.duckYellow
    var offColor = Color.neumorphicBackground
    var thumbOnColor = Color.neumorphicToggleOn
    var thumbOffColor = Color.neumorphicToggleOff
    
    
    @State var dragInitialState: Bool = false
    @State private var isReadyToSwipe: Bool = false
    @State var dragStarted: Bool = false
    
    
    func makeBody(configuration: Self.Configuration) -> some View {           
            RoundedRectangle(cornerRadius: 18, style: .circular)
                .fill(configuration.isOn ? onColor : offColor)
                .frame(width: 60, height: 36)
                .overlay(
//                    ZStack {
                        RoundedRectangle(cornerRadius: 26)
                            .fill(configuration.isOn ? thumbOnColor : thumbOffColor)
                            .neumorphicOuter()
//                            .shadow(radius: 1, x: 0, y: 1)
                            .offset(x: offset(for: configuration))
                            .frame(width: isReadyToSwipe ? 32 : 26, height: 26)
//                    }
                )
                .neumorphicRoundedInner(cornerRadius: 18)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isReadyToSwipe = true
                            dragStarted = abs(value.translation.width) > 1
                            if dragInitialState {
                                if value.translation.width < -20 {
                                    configuration.isOn = !dragInitialState
                                } else {
                                    configuration.isOn = dragInitialState
                                }
                            } else {
                                if value.translation.width > 20 {
                                    configuration.isOn = !dragInitialState
                                } else {
                                    configuration.isOn = dragInitialState
                                }
                            }
                        }
                        .onEnded({ value in
                            if !dragStarted {
                                configuration.isOn.toggle()
                            }
                            isReadyToSwipe = false
                            dragStarted = false
                            dragInitialState = configuration.isOn
                        })
                )
                .onAppear {
                    dragInitialState = configuration.isOn
                }
                .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
                .animation(.easeOut(duration: 0.2), value: isReadyToSwipe)
    }
    
    private func offset(for configutration: Configuration) -> CGFloat {
        if configutration.isOn {
            return isReadyToSwipe ? 7 : 12
        } else {
            return isReadyToSwipe ? -7 : -12
            
        }
    }
}


struct NeuToggleStyle_Previews: PreviewProvider {
    
    static var previews: some View {
        Toggle("Hey", isOn: .constant(true))
            .padding()
            .toggleStyle(NeuToggleStyle())
            .preferredColorScheme(.dark)
    }
}
