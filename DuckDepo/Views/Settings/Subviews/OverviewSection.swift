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
            HStack(spacing: 8) {
                StatTile(value: documentCount, title: "sv_stat_documents", color: .primary)
                StatTile(value: passwordCount, title: "sv_stat_passwords", color: .primary)
                StatTile(value: renewalCount, title: "sv_stat_renewal", color: renewalCount > 0 ? .orange : .primary)
            }
        }
        .padding(.vertical, 6)
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

    let value: Int
    let title: LocalizedStringKey
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value, format: .number)
                .font(.title2.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(color)
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
            OverviewCard(documentCount: 12, passwordCount: 13, renewalCount: 2)
        }
    }
}
