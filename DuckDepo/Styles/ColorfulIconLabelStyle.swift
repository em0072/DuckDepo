//
//  ColorfulIconLabelStyle.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 12/11/2021.
//

import SwiftUI

struct ColorfulIconLabelStyle: LabelStyle {
    var color: Color
    var size: CGFloat
    
    func makeBody(configuration: Configuration) -> some View {
        Label {
            configuration.title
        } icon: {
            configuration.icon
                .imageScale(.large)
                .foregroundColor(.white)
                .background(RoundedRectangle(cornerRadius: 7 * size).frame(width: 30 * size, height: 30 * size).foregroundColor(color))
        }
    }
}
