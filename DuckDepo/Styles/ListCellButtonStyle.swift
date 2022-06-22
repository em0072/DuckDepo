//
//  ListCellButtonStyle.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 19/06/2022.
//

import SwiftUI


struct ListCellButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .opacity(configuration.isPressed ? 0.6 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
