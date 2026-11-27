//
//  ImportSheet.swift
//  DuckDepo
//

import SwiftUI

/// What another app sent, before it's saved.
struct ImportSheet: View {

    let plan: ImportPlan
    var isImporting = false
    var progress = 0.0
    let onImport: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if isImporting {
                    Section {
                        ProgressView(value: progress) {
                            Text("import_in_progress")
                        }
                    }
                }
                if plan.isEmpty {
                    ContentUnavailableView("import_nothing_title", systemImage: "checkmark.circle",
                                           description: Text("import_nothing_body"))
                } else {
                    Section {
                        row("import_row_passwords", count: plan.passwords.count, systemImage: "key.fill", color: .indigo)
                        row("import_row_codes", count: plan.codeCount, systemImage: "lock.rotation", color: .teal)
                        row("import_row_passkeys", count: plan.passkeys.count, systemImage: "person.badge.key.fill", color: .purple)
                        row("import_row_documents", count: plan.documents.count, systemImage: "doc.text.fill", color: .orange)
                    } header: {
                        Text("import_from \(plan.source)")
                    }
                }
                if plan.alreadySavedCount + plan.unsupportedCount + plan.droppedNoteCount > 0 {
                    Section {
                        note("import_already_saved \(plan.alreadySavedCount)", count: plan.alreadySavedCount,
                             systemImage: "checkmark.circle")
                        note("import_unsupported \(plan.unsupportedCount)", count: plan.unsupportedCount,
                             systemImage: "nosign")
                        note("import_notes_dropped \(plan.droppedNoteCount)", count: plan.droppedNoteCount,
                             systemImage: "note.text")
                    }
                }
            }
            .navigationTitle("import_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if plan.isEmpty {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(role: .confirm) {
                            dismiss()
                        }
                    }
                } else {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(role: .close) {
                            dismiss()
                        }
                        .disabled(isImporting)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        if isImporting {
                            ProgressView()
                        } else {
                            Button("import_button", role: .confirm, action: onImport)
                        }
                    }
                }
            }
        }
        .tint(.duckYellow)
        // Saving can't be stopped halfway.
        .interactiveDismissDisabled(isImporting)
    }

    @ViewBuilder
    private func row(_ title: LocalizedStringKey, count: Int, systemImage: String, color: Color) -> some View {
        if count > 0 {
            LabeledContent {
                Text(count, format: .number)
                    .monospacedDigit()
            } label: {
                Label(title, systemImage: systemImage)
                    .labelStyle(.tile(color))
            }
        }
    }

    @ViewBuilder
    private func note(_ text: LocalizedStringKey, count: Int, systemImage: String) -> some View {
        if count > 0 {
            Label(text, systemImage: systemImage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    var plan = ImportPlan(CredentialImport(.init(accounts: [], formatVersion: .v1, exporterRelyingPartyIdentifier: "",
                                                 exporterDisplayName: "Passwords", timestamp: .now)),
                          savedPasswords: [], savedSecrets: { _ in ("", "") }, savedPasskeyIDs: [], savedDocuments: [])
    plan.passwords = [.test]
    plan.alreadySavedCount = 3
    plan.droppedNoteCount = 2
    return Text("")
        .sheet(isPresented: .constant(true)) {
            ImportSheet(plan: plan, onImport: {})
        }
}
