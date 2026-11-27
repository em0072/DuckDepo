//
//  PhotoGallery.swift
//  DuckDepo
//

import SwiftUI

/// The document's photos in a row, each at its own shape, the next one peeking in at the edge. A single
/// photo gets the whole width. Tapping a photo opens the viewer, which zooms out of it.
struct PhotoGallery: View {

    let photos: [DocumentPhoto]
    /// The photo the viewer opens on. The viewer moves it too, so the row scrolls to keep it in view and
    /// closing the viewer zooms back into the right photo.
    @Binding var selection: DocumentPhoto.ID?
    let namespace: Namespace.ID
    let onOpen: () -> Void

    @ScaledMetric(relativeTo: .body) private var rowHeight: CGFloat = 200
    @ScaledMetric(relativeTo: .body) private var singleMaxHeight: CGFloat = 300

    private static let cornerRadius: CGFloat = 16

    var body: some View {
        if photos.count == 1, let photo = photos.first {
            tile(for: photo, index: 0, size: nil)
                .frame(maxWidth: .infinity, maxHeight: min(singleMaxHeight, 460))
        } else {
            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 10) {
                        ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                            tile(for: photo, index: index, size: CGSize(width: width(of: photo), height: height))
                                .id(photo.id)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollIndicators(.hidden)
                // Photos run to the screen's edge, past the list's margins.
                .scrollClipDisabled()
                .frame(height: height)
                .onChange(of: selection) { _, selection in
                    // The viewer paged to another photo: bring it into view behind the viewer.
                    if let selection {
                        proxy.scrollTo(selection, anchor: .leading)
                    }
                }
            }
        }
    }

    private var height: CGFloat {
        min(rowHeight, 320)
    }

    /// The photo's own shape at the row's height, kept from getting too narrow or too wide.
    private func width(of photo: DocumentPhoto) -> CGFloat {
        let size = photo.size
        guard size.height > 0 else { return height }
        return min(max(height * size.width / size.height, height * 0.6), height * 1.8)
    }

    /// A photo at `size`, filling it, or at its own shape when there's no size.
    private func tile(for photo: DocumentPhoto, index: Int, size: CGSize?) -> some View {
        Button {
            selection = photo.id
            onOpen()
        } label: {
            GalleryImage(photo: photo, maxPixelSize: max(height, singleMaxHeight) * 3,
                         contentMode: size == nil ? .fit : .fill)
                .frame(width: size?.width, height: size?.height)
                .clipShape(.rect(cornerRadius: Self.cornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
                        .strokeBorder(.separator, lineWidth: 0.5)
                }
                .matchedTransitionSource(id: photo.id, in: namespace)
        }
        .buttonStyle(.plain)
        .contextMenu {
            ContextMenuView(type: .image(value: photo.image))
        }
        .accessibilityLabel(Text("photo_n_of_m \(index + 1) \(photos.count)"))
        .accessibilityHint(Text("photo_open_hint"))
    }
}

/// The photo scaled down to what's needed on screen, decoded off the main thread: decoding full-size
/// photos while the screen opens would hold up its first frame.
private struct GalleryImage: View {

    let photo: DocumentPhoto
    let maxPixelSize: CGFloat
    let contentMode: ContentMode

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
            } else {
                Rectangle()
                    .fill(.quaternary)
            }
        }
        .aspectRatio(photo.size, contentMode: contentMode)
        .task(id: photo.id) {
            let photo = photo
            let maxPixelSize = maxPixelSize
            let decoded = await Task.detached(priority: .userInitiated) {
                photo.downsampled(toMaxPixelSize: maxPixelSize)
            }.value ?? photo.image
            withAnimation(.easeOut(duration: 0.2)) {
                image = decoded
            }
        }
    }
}

#Preview {
    @Previewable @State var selection: DocumentPhoto.ID?
    @Previewable @Namespace var namespace
    List {
        Section {
            PhotoGallery(photos: Document.test.photos, selection: $selection, namespace: namespace) {}
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
        }
    }
}
