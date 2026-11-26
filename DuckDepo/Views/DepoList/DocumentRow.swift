//
//  DocumentRow.swift
//  DuckDepo
//

import SwiftUI

struct DocumentRow: View {

    let document: Document

    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 44

    var body: some View {
        HStack(spacing: 12) {
            DocumentIcon(document: document)
                .frame(width: iconSize, height: iconSize)
            VStack(alignment: .leading, spacing: 2) {
                Text(document.name)
                    .foregroundStyle(.primary)
                if !document.description.isEmpty {
                    Text(document.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let status = document.expiryStatus {
                    ExpiryBadge(status: status)
                        .padding(.top, 2)
                }
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}

/// The first photo's thumbnail, or the document type's symbol on a colored tile.
struct DocumentIcon: View {

    let document: Document

    var body: some View {
        GeometryReader { proxy in
            let shape = RoundedRectangle(cornerRadius: proxy.size.width * 0.22, style: .continuous)
            if let thumbnail = document.thumbnail, let image = ThumbnailCache.image(for: thumbnail) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipShape(shape)
                    .overlay(shape.strokeBorder(.separator, lineWidth: 0.5))
            } else {
                shape
                    .fill(document.documentType.iconColor.gradient)
                    .overlay {
                        Image(systemName: document.documentType.symbolName)
                            .font(.system(size: proxy.size.width * 0.45, weight: .medium))
                            .foregroundStyle(.white)
                    }
            }
        }
        .accessibilityHidden(true)
    }
}

/// Flags a document that has expired or expires soon. Shows nothing otherwise.
struct ExpiryBadge: View {

    let status: ExpiryStatus

    var body: some View {
        if let text = status.badgeText {
            // Not `Label`: its icon spacing is too wide for a badge.
            HStack(spacing: 4) {
                Image(systemName: status.systemImage)
                    .accessibilityHidden(true)
                Text(text)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(status.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(status.color.opacity(0.15), in: .capsule)
        }
    }
}

/// Decoded list thumbnails, so scrolling doesn't decode the same JPEG again.
enum ThumbnailCache {

    private static let cache: NSCache<NSUUID, UIImage> = {
        let cache = NSCache<NSUUID, UIImage>()
        cache.countLimit = 300
        return cache
    }()

    static func image(for thumbnail: Document.Thumbnail) -> UIImage? {
        let key = thumbnail.id as NSUUID
        if let image = cache.object(forKey: key) {
            return image
        }
        guard let image = UIImage(data: thumbnail.data)?.preparingForDisplay() else { return nil }
        cache.setObject(image, forKey: key)
        return image
    }
}

#Preview {
    List {
        DocumentRow(document: Document(name: "Passport", description: "Jane Doe", documentType: .identification))
        DocumentRow(document: Document(name: "Car", description: "Ford", documentType: .transport))
    }
}
