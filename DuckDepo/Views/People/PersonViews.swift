//
//  PersonViews.swift
//  DuckDepo
//

import SwiftUI

extension PersonColor {

    /// Deep shades, the same in light and dark mode, so white names and initials on them stay readable
    /// (at least 4.5:1). The system colors are too light for that.
    var color: Color {
        switch self {
        case .blue: Self.rgb(0x0A5CD6)
        case .green: Self.rgb(0x208238)
        case .orange: Self.rgb(0xB05A00)
        case .pink: Self.rgb(0xC2185B)
        case .purple: Self.rgb(0x8944AB)
        case .red: Self.rgb(0xD70015)
        case .teal: Self.rgb(0x007C91)
        case .indigo: Self.rgb(0x4B45C2)
        case .brown: Self.rgb(0x7F6545)
        case .gray: Self.rgb(0x6C6C70)
        }
    }

    /// For filled shapes with white on them: darker toward the bottom, never lighter than `color`.
    var fill: LinearGradient {
        LinearGradient(colors: [color, color.mix(with: .black, by: 0.18)], startPoint: .top, endPoint: .bottom)
    }

    private static func rgb(_ value: Int) -> Color {
        Color(red: Double((value >> 16) & 0xFF) / 255, green: Double((value >> 8) & 0xFF) / 255, blue: Double(value & 0xFF) / 255)
    }

    /// For VoiceOver, in the color picker.
    var localizedName: LocalizedStringKey {
        switch self {
        case .blue: "person_color_blue"
        case .green: "person_color_green"
        case .orange: "person_color_orange"
        case .pink: "person_color_pink"
        case .purple: "person_color_purple"
        case .red: "person_color_red"
        case .teal: "person_color_teal"
        case .indigo: "person_color_indigo"
        case .brown: "person_color_brown"
        case .gray: "person_color_gray"
        }
    }
}

/// A person's initials on their color, in a circle.
struct PersonAvatar: View {

    let person: Person

    var body: some View {
        GeometryReader { proxy in
            Circle()
                .fill(person.color.fill)
                .overlay {
                    let initials = person.initials
                    if initials.isEmpty {
                        Image(systemName: "person.fill")
                            .font(.system(size: proxy.size.width * 0.5, weight: .medium))
                            .foregroundStyle(.white)
                    } else {
                        Text(verbatim: initials)
                            .font(.system(size: proxy.size.width * (initials.count > 1 ? 0.4 : 0.48),
                                          weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                            .padding(proxy.size.width * 0.08)
                    }
                }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

/// Whose a document or password is: a small avatar and the name. In list rows, only the first name.
struct PersonTag: View {

    let person: Person
    var font: Font = .caption
    var isShort = false

    @ScaledMetric(relativeTo: .caption) private var avatarSize: CGFloat = 18

    var body: some View {
        HStack(spacing: 5) {
            PersonAvatar(person: person)
                .frame(width: avatarSize, height: avatarSize)
            Text(isShort ? person.shortName : person.name)
                .font(font)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("person_belongs_to_value \(person.name)"))
    }
}

#Preview {
    List {
        HStack {
            PersonAvatar(person: Person(name: "Anna Lee", color: .pink))
                .frame(width: 44)
            PersonAvatar(person: Person(name: "Макс", color: .teal))
                .frame(width: 44)
            PersonAvatar(person: Person(name: "", color: .gray))
                .frame(width: 44)
        }
        PersonTag(person: Person(name: "Anna", color: .pink))
    }
}
