//
//  PasskeyView.swift
//  DuckDepo
//

import SwiftUI

/// A passkey's page: the site and account it signs in to, and a way to delete it.
struct PasskeyView: View {

    let passkey: Passkey
    let onDelete: () -> Void

    var body: some View {
        List {
            Section {
                VStack(spacing: 10) {
                    IconTile(color: .indigo, size: 56) {
                        Image(systemName: "person.badge.key.fill")
                    }
                    Text("passkey_summary")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            Section {
                FieldValueRow(title: String(localized: "passkey_site"), value: passkey.relyingParty)
                if !passkey.userName.isEmpty {
                    FieldValueRow(title: String(localized: "passkey_user"), value: passkey.userName)
                }
                LabeledContent("passkey_created") {
                    Text(passkey.createdAt, format: .dateTime.day().month().year())
                }
            }
            Section {
                Button("passkey_delete", role: .destructive, action: onDelete)
                    .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(passkey.relyingParty)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PasskeyView(passkey: Passkey.make(relyingParty: "github.com", userName: "jane", userHandle: Data([1]))) {}
    }
}
