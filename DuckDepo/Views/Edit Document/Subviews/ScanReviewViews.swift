//
//  ScanReviewViews.swift
//  DuckDepo
//

import SwiftUI

/// Shows next to a field's title how its value got there from a scan.
struct ScanMarker: View {

    let confidence: ScanConfidence

    var body: some View {
        Image(systemName: systemImage)
            .foregroundStyle(color)
            .accessibilityLabel(Text(label))
    }

    private var systemImage: String {
        switch confidence {
        case .verified: "checkmark.seal.fill"
        case .read: "text.viewfinder"
        case .suggested: "sparkles"
        }
    }

    private var color: Color {
        switch confidence {
        case .verified: .green
        case .read: .secondary
        case .suggested: .orange
        }
    }

    private var label: LocalizedStringKey {
        switch confidence {
        case .verified: "scan_marker_verified"
        case .read: "scan_marker_read"
        case .suggested: "scan_marker_suggested"
        }
    }
}

/// Tells the user a new document was filled in from a scan and needs a look before saving.
struct ScanBanner: View {

    let foundNothing: Bool

    var body: some View {
        Section {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(foundNothing ? "scan_banner_nothing_title" : "scan_banner_title")
                        .font(.headline)
                    Text(foundNothing ? "scan_banner_nothing_body" : "scan_banner_body")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: foundNothing ? "doc.questionmark" : "text.viewfinder")
                    .foregroundStyle(.tint)
            }
            .accessibilityElement(children: .combine)
        }
    }
}

#Preview {
    Form {
        ScanBanner(foundNothing: false)
        ScanBanner(foundNothing: true)
        HStack {
            ScanMarker(confidence: .verified)
            ScanMarker(confidence: .read)
            ScanMarker(confidence: .suggested)
        }
    }
}
