//
//  TransferSection.swift
//  DuckDepo
//

import SwiftUI

/// Moving everything to or from another password manager, through iOS.
struct TransferSection: View {

    let exporter: CredentialExporter

    var body: some View {
        Section {
            Button {
                Task {
                    await exporter.export()
                }
            } label: {
                LabeledContent {
                    if exporter.isExporting {
                        ProgressView()
                            .transition(.opacity)
                    }
                } label: {
                    Label("sv_export", systemImage: "square.and.arrow.up")
                        .labelStyle(.tile(.blue))
                }
                .animation(.default, value: exporter.isExporting)
            }
            .foregroundStyle(.primary)
            .disabled(exporter.isExporting)
            NavigationLink {
                ImportGuideView()
            } label: {
                Label("sv_import", systemImage: "square.and.arrow.down")
                    .labelStyle(.tile(.green))
            }
        } header: {
            Text("sv_transfer")
        } footer: {
            Text("sv_transfer_footer")
        }
    }
}

/// Imports start in the other app, so this says where to look.
struct ImportGuideView: View {

    private struct Step: Identifiable {
        let title: LocalizedStringKey
        let body: LocalizedStringKey
        let systemImage: String
        let color: Color
        var id: String { systemImage }
    }

    private let steps = [
        Step(title: "import_step_open_title", body: "import_step_open_body", systemImage: "app.badge", color: .gray),
        Step(title: "import_step_export_title", body: "import_step_export_body", systemImage: "square.and.arrow.up", color: .blue),
        Step(title: "import_step_review_title", body: "import_step_review_body", systemImage: "checkmark", color: .green),
    ]

    var body: some View {
        List {
            Section {
                ForEach(steps) { step in
                    HStack(alignment: .top, spacing: 14) {
                        IconTile(color: step.color) {
                            Image(systemName: step.systemImage)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(step.title)
                                .font(.headline)
                            Text(step.body)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    .accessibilityElement(children: .combine)
                }
            } footer: {
                Text("import_guide_footer")
            }
        }
        .navigationTitle("sv_import")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        List {
            TransferSection(exporter: CredentialExporter())
        }
    }
}
