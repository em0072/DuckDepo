//
//  RoundedRectYellowButtonStyle.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 07/07/2023.
//

import SwiftUI

struct RoundedRectYellowButtonStyle: ButtonStyle {
    
    @Environment(\.isEnabled) private var isEnabled: Bool
            
    func makeBody(configuration: Configuration) -> some View {
        ZStack(alignment: .leading) {
            configuration.label
                .foregroundColor(color(isPressed: configuration.isPressed))
                .bold()
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(color(isPressed: configuration.isPressed), lineWidth: 2)
                }
                .contentShape(Rectangle())
        }
    }
}

extension RoundedRectYellowButtonStyle {
    private func color(isPressed: Bool) -> Color {
        var opacity: CGFloat = isPressed ? 0.6 : 1
        if !isEnabled {
            opacity = 0.4
        }
        return Color.duckYellow.opacity(opacity)
        
    }
}

struct RoundedRectYellowButtonStyle_Preview: PreviewProvider {
        
    static var previews: some View {
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
            .buttonStyle(RoundedRectYellowButtonStyle())
//            .disabled(true)
    }
}
