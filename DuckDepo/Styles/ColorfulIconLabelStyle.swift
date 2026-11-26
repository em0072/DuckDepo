//
//  ColorfulIconLabelStyle.swift
//  DuckDepo
//

import SwiftUI

/// A label whose icon sits on a small colored tile, like the rows of the Settings app.
struct ColorfulIconLabelStyle: LabelStyle {

    var color: Color

    func makeBody(configuration: Configuration) -> some View {
        Label {
            configuration.title
        } icon: {
            IconTile(color: color) {
                configuration.icon
            }
        }
    }
}

extension LabelStyle where Self == ColorfulIconLabelStyle {
    /// An icon on a `color` tile.
    static func tile(_ color: Color) -> ColorfulIconLabelStyle {
        ColorfulIconLabelStyle(color: color)
    }
}

/// A white symbol on a rounded colored square that grows with the text size.
struct IconTile<Icon: View>: View {

    let color: Color
    let icon: Icon

    @ScaledMetric private var size: CGFloat

    /// `size` is the side at the default text size.
    init(color: Color, size: CGFloat = 29, @ViewBuilder icon: () -> Icon) {
        self.color = color
        self.icon = icon()
        _size = ScaledMetric(wrappedValue: size, relativeTo: .body)
    }

    var body: some View {
        icon
            .font(.system(size: size * 0.55, weight: .medium))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(color.gradient, in: .rect(cornerRadius: size * 0.24, style: .continuous))
            .accessibilityHidden(true)
    }
}

#Preview {
    List {
        Label("Face ID", systemImage: "faceid").labelStyle(.tile(.green))
        Label("iCloud", systemImage: "icloud.fill").labelStyle(.tile(.blue))
    }
}
