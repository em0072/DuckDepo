//
//  NeuSectionTitle.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 06/07/2022.
//

import SwiftUI

struct NeuSectionTitle: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title.localized())
                .font(.footnote)
                .foregroundColor(.neumorphicText)
                .textCase(.uppercase)
            Spacer()
        }
        .padding(.horizontal, 16)
    }
}

struct NeuSectionTitle_Previews: PreviewProvider {
    static var previews: some View {
        NeuSectionTitle(title: "title")
    }
}
