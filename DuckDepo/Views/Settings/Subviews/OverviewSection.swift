//
//  OverviewSection.swift
//  DuckDepo
//

import SwiftUI

/// The top of Settings: what's in the Depo at a glance.
struct OverviewCard: View {

    let documentCount: Int
    let passwordCount: Int
    let renewalCount: Int
    /// Passwords Password Health says to fix; nil until it has read them.
    let toFixCount: Int?

    @ScaledMetric(relativeTo: .title3) private var duckSize: CGFloat = 52

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                DuckTile()
                    .frame(width: duckSize, height: duckSize)
                VStack(alignment: .leading, spacing: 2) {
                    Text("sv_overview_title")
                        .font(.title3.weight(.semibold))
                    Text("sv_overview_subtitle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .combine)
            // Four in a row while their labels fit; two by two at large text sizes and in longer languages.
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    documentsTile
                    passwordsTile
                    renewalTile
                    toFixTile
                }
                Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                    GridRow {
                        documentsTile
                        passwordsTile
                    }
                    GridRow {
                        renewalTile
                        toFixTile
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }

    private var documentsTile: some View {
        StatTile(value: documentCount, title: "sv_stat_documents", color: .primary)
    }

    private var passwordsTile: some View {
        StatTile(value: passwordCount, title: "sv_stat_passwords", color: .primary)
    }

    private var renewalTile: some View {
        StatTile(value: renewalCount, title: "sv_stat_renewal", color: renewalCount > 0 ? .orange : .primary)
    }

    private var toFixTile: some View {
        StatTile(value: toFixCount, title: "sv_stat_to_fix", color: (toFixCount ?? 0) > 0 ? .orange : .primary)
    }
}

/// The app's duck on its yellow, as on the icon.
private struct DuckTile: View {

    var body: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color(red: 0xFB / 255, green: 0xC5 / 255, blue: 0x31 / 255).gradient)
            .overlay {
                Image("LaunchDuck")
                    .resizable()
                    .scaledToFit()
                    .padding(7)
                    // The dark variant is drawn for a dark background, not for the yellow.
                    .environment(\.colorScheme, .light)
            }
            .accessibilityHidden(true)
    }
}

private struct StatTile: View {

    /// Nil while not known yet.
    let value: Int?
    let title: LocalizedStringKey
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Group {
                if let value {
                    Text(value, format: .number)
                        .foregroundStyle(color)
                } else {
                    Text(verbatim: "–")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.title2.weight(.semibold))
            .monospacedDigit()
            .contentTransition(.numericText())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(.tertiarySystemFill), in: .rect(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    List {
        Section {
            OverviewCard(documentCount: 12, passwordCount: 13, renewalCount: 2, toFixCount: 3)
        }
    }
}
