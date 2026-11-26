//
//  PhotoCarousel.swift
//  DuckDepo
//

import SwiftUI

/// The document's photos, one page each. Tapping a photo opens the viewer, which zooms out of it.
struct PhotoCarousel: View {

    let photos: [DocumentPhoto]
    /// The photo on screen. The viewer moves it too, so closing the viewer zooms back into the right photo.
    @Binding var selection: DocumentPhoto.ID?
    let namespace: Namespace.ID
    let onOpen: () -> Void

    @ScaledMetric(relativeTo: .body) private var height: CGFloat = 260

    var body: some View {
        TabView(selection: $selection) {
            ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                Button(action: onOpen) {
                    CarouselImage(photo: photo)
                        .matchedTransitionSource(id: photo.id, in: namespace)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.bottom, photos.count > 1 ? 28 : 0)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    ContextMenuView(type: .image(value: photo.image))
                }
                .accessibilityLabel(Text("photo_n_of_m \(index + 1) \(photos.count)"))
                .accessibilityHint(Text("photo_open_hint"))
                .tag(Optional(photo.id))
            }
        }
        .tabViewStyle(.page(indexDisplayMode: photos.count > 1 ? .always : .never))
        // A backdrop behind the dots, or they vanish against the white card.
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .frame(height: min(height, 420))
        .onAppear {
            if selection == nil || !photos.contains(where: { $0.id == selection }) {
                selection = photos.first?.id
            }
        }
        .onChange(of: photos) {
            if !photos.contains(where: { $0.id == selection }) {
                selection = photos.first?.id
            }
        }
    }
}

/// The photo scaled down to screen size, decoded off the main thread: decoding full-size photos while
/// the screen opens would hold up its first frame.
private struct CarouselImage: View {

    let photo: DocumentPhoto

    @State private var image: UIImage?

    private static let maxPixelSize: CGFloat = 1400

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Color.clear
            }
        }
        .task(id: photo.id) {
            let source = photo.image
            let pixels = CGSize(width: source.size.width * source.scale, height: source.size.height * source.scale)
            let scale = min(1, Self.maxPixelSize / max(pixels.width, pixels.height, 1))
            let size = CGSize(width: pixels.width * scale, height: pixels.height * scale)
            image = await source.byPreparingThumbnail(ofSize: size) ?? source
        }
    }
}

#Preview {
    @Previewable @State var selection: DocumentPhoto.ID?
    @Previewable @Namespace var namespace
    List {
        PhotoCarousel(photos: Document.test.photos, selection: $selection, namespace: namespace) {}
            .listRowInsets(EdgeInsets())
    }
}
