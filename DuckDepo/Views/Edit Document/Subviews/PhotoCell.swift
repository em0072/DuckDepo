//
//  PhotoCell.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 20/06/2022.
//

import SwiftUI

/// A square photo thumbnail that fills the frame it's given.
struct PhotoCell: View {

    var image: UIImage
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Color.clear
                .overlay {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                }
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(.separator, lineWidth: 0.5)
                }
        }
        .buttonStyle(.plain)
        .contextMenu {
            ContextMenuView(type: .image(value: image))
        }
    }
}

/// The "add photo" tile next to the photos.
struct AddCell: View {

    var action: () -> Void

    var body: some View {
        Button(action: action) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.quaternary)
                .overlay {
                    Image(systemName: "plus")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.tint)
                }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack {
        AddCell {}
            .frame(width: 84, height: 84)
        PhotoCell(image: UIImage(named: "duck")!) {}
            .frame(width: 84, height: 84)
    }
}
