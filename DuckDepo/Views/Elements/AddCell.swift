//
//  AddPhotoCell.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 28/10/2021.
//

import SwiftUI

struct AddCell: View {
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(Color.transparent)
            Image(systemName: "plus.circle")
        }
        .cornerRadius(15)
        .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.duckOutline, lineWidth: 0.5)
            )
        .aspectRatio(1.0, contentMode: .fit)

    }
}

struct AddCell_Previews: PreviewProvider {
    static var previews: some View {
        AddCell()
            .frame(height: 50)
    }
}
