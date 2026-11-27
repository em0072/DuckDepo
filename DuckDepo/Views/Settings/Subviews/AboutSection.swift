//
//  AboutSection.swift
//  DuckDepo
//

import SwiftUI

/// Privacy and the app's version.
struct AboutSection: View {

    let version: String

    var body: some View {
        Section("sv_about") {
            NavigationLink {
                PrivacyView()
            } label: {
                Label("sv_privacy", systemImage: "hand.raised.fill")
                    .labelStyle(.tile(.teal))
            }
            LabeledContent {
                Text(version)
                    .textSelection(.enabled)
            } label: {
                Label("sv_version", systemImage: "info.circle")
                    .labelStyle(.tile(.gray))
            }
        }
    }
}

/// Where the user's data lives and what never leaves the device.
struct PrivacyView: View {

    private struct Point: Identifiable {
        let title: LocalizedStringKey
        let body: LocalizedStringKey
        let systemImage: String
        let color: Color
        var id: String { systemImage }
    }

    private let points = [
        Point(title: "privacy_device_title", body: "privacy_device_body", systemImage: "iphone", color: .gray),
        Point(title: "privacy_icloud_title", body: "privacy_icloud_body", systemImage: "icloud.fill", color: .blue),
        Point(title: "privacy_passwords_title", body: "privacy_passwords_body", systemImage: "key.fill", color: .indigo),
        Point(title: "privacy_scan_title", body: "privacy_scan_body", systemImage: "text.viewfinder", color: .orange),
        Point(title: "privacy_leaks_title", body: "privacy_leaks_body", systemImage: "network.badge.shield.half.filled", color: .red),
        Point(title: "privacy_clipboard_title", body: "privacy_clipboard_body", systemImage: "doc.on.clipboard.fill", color: .teal),
        Point(title: "privacy_tracking_title", body: "privacy_tracking_body", systemImage: "eye.slash.fill", color: .green),
    ]

    var body: some View {
        List(points) { point in
            HStack(alignment: .top, spacing: 14) {
                IconTile(color: point.color) {
                    Image(systemName: point.systemImage)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(point.title)
                        .font(.headline)
                    Text(point.body)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
            .accessibilityElement(children: .combine)
        }
        .navigationTitle("sv_privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        List {
            AboutSection(version: "2.7 (42)")
        }
    }
}
