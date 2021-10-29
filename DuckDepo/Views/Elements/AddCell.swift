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
                .aspectRatio(1.0, contentMode: .fit)
                .foregroundColor(Color.white)
            Label("Add Image", systemImage: "plus.circle")
                .labelStyle(VerticalLabelStyle())
        }
        .cornerRadius(15)
        .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.black, lineWidth: 0.5)
            )
    }
}

struct AddCell_Previews: PreviewProvider {
    static var previews: some View {
        AddCell()
    }
}
