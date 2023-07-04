//
//  SectionBackground.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 05/07/2022.
//

import SwiftUI

struct NeuSectionBackground: View {
    var body: some View {
        Image("SectionBG2")
            .allowsHitTesting(false)
            .layoutPriority(-1)

    }
}

struct SectionBackground_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Text("Hello, friend")
                .padding()
            NeuSectionBackground()
        }
        
    }
}
