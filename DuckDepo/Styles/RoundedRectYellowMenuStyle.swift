//
//  RoundedRectYellowMenuStyle.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 07/07/2023.
//

import SwiftUI

struct RoundedRectYellowMenuStyle: MenuStyle {
    
    @Environment(\.isEnabled) private var isEnabled: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        Menu(configuration)
            .foregroundColor(color)
            .bold()
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(color, lineWidth: 2)
            }
            .contentShape(Rectangle())
    }
    
}

extension RoundedRectYellowMenuStyle {
    private var color: Color {
        var opacity: CGFloat = 1
        if !isEnabled {
            opacity = 0.4
        }
        return Color.duckYellow.opacity(opacity)
        
    }
}


struct RoundedRectYellowMenuStyle_Preview: PreviewProvider {
        
    static var previews: some View {
        VStack {
            Menu("Choose") {
                Text("1")
                Text("2")
                Text("3")
                
            }
            .menuStyle(RoundedRectYellowMenuStyle())
//            .disabled(true)

            Button("Choose") {
                
            }
            .buttonStyle(RoundedRectYellowButtonStyle())
            
        }
    }
}
