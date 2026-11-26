//
//  PasswordRow.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 07/05/2022.
//

import SwiftUI

struct PasswordRow: View {

    let name: String
    let login: String

    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 36

    var body: some View {
        HStack(spacing: 12) {
            Monogram(text: name)
                .frame(width: iconSize, height: iconSize)
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .foregroundStyle(.primary)
                if !login.isEmpty {
                    Text(login)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}

/// The first letter of a name on a colored tile. The color comes from the name, so it stays the same.
struct Monogram: View {

    let text: String

    /// Hues far enough apart to tell neighbouring rows apart.
    private static let palette: [Color] = [.blue, .green, .orange, .pink, .purple, .red, .brown, .teal]

    var body: some View {
        GeometryReader { proxy in
            RoundedRectangle(cornerRadius: proxy.size.width * 0.25, style: .continuous)
                .fill(color.gradient)
                .overlay {
                    if let letter {
                        Text(verbatim: letter)
                            .font(.system(size: proxy.size.width * 0.48, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                    } else {
                        Image(systemName: "key.fill")
                            .font(.system(size: proxy.size.width * 0.42, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
        }
        .accessibilityHidden(true)
    }

    private var letter: String? {
        text.trimmingCharacters(in: .whitespacesAndNewlines).first.map { String($0).uppercased() }
    }

    private var color: Color {
        // Not `hashValue`: that changes on every launch.
        let sum = text.lowercased().unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) & 0xFFFF }
        return Self.palette[sum % Self.palette.count]
    }
}

#Preview {
    List {
        PasswordRow(name: "Github", login: "jane@example.com")
        PasswordRow(name: "Gmail", login: "")
        PasswordRow(name: "", login: "duck")
    }
}
