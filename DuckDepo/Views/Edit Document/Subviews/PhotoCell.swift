//
//  PhotoCell.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 20/06/2022.
//

import SwiftUI

/// A photo in the editor's strip, cropped to the cell, which has about the photo's own shape. It draws a
/// copy the size of the cell: a strip of full-size pages takes more memory than the share extension has.
struct PhotoCell: View {

    var photo: DocumentPhoto
    /// The cell's size, in points.
    var size: CGSize
    var action: () -> Void

    @Environment(\.displayScale) private var displayScale

    var body: some View {
        Button(action: action) {
            Color.clear
                .overlay {
                    Image(uiImage: PhotoThumbnails.image(for: photo, filling: size, scale: displayScale))
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
            ContextMenuView(type: .image(value: photo.image))
        }
    }
}

/// Smaller copies of photos, made once per photo and size (a photo's ID changes with its content).
enum PhotoThumbnails {

    private static let cache = NSCache<NSString, UIImage>()
    /// Sizes are rounded up to this many pixels, so cells of about the same size share a copy.
    private static let step: CGFloat = 128

    /// A copy large enough to fill `size` points at `scale` without being stretched. A zero width or
    /// height fits the other one.
    static func image(for photo: DocumentPhoto, filling size: CGSize, scale: CGFloat) -> UIImage {
        let pixels = pixelSize(of: photo, filling: size, scale: scale)
        let key = "\(photo.id.uuidString)-\(Int(pixels))" as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }
        let image = photo.downsampled(toMaxPixelSize: pixels) ?? photo.image
        cache.setObject(image, forKey: key)
        return image
    }

    /// The longest side, in pixels, of a copy that fills `size` points at `scale`.
    static func pixelSize(of photo: DocumentPhoto, filling size: CGSize, scale: CGFloat) -> CGFloat {
        let photoSize = photo.size
        let longest = max(photoSize.width, photoSize.height)
        guard photoSize.width > 0, photoSize.height > 0 else { return DocumentPhoto.thumbnailPixelSize }
        let fill = max(size.width / photoSize.width, size.height / photoSize.height)
        let needed = max(1, longest * fill * scale)
        return min((needed / step).rounded(.up) * step, longest)
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
        PhotoCell(photo: DocumentPhoto(image: UIImage(named: "duck")!)!, size: CGSize(width: 84, height: 84)) {}
            .frame(width: 84, height: 84)
    }
}
