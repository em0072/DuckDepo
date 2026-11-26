//
//  PasskeyViews.swift
//  DuckDepoAutoFillExtension
//

import SwiftUI

/// Asks before a site's new passkey is saved in DuckDepo.
struct PasskeyRegistrationView: View {

    let relyingParty: String
    let userName: String
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Spacer()
                IconTile(color: .indigo, size: 64) {
                    Image(systemName: "person.badge.key.fill")
                }
                Text("passkey_save_title")
                    .font(.title2.weight(.semibold))
                VStack(spacing: 4) {
                    Text(verbatim: userName.isEmpty ? relyingParty : userName)
                        .font(.headline)
                    if !userName.isEmpty {
                        Text(verbatim: relyingParty)
                            .foregroundStyle(.secondary)
                    }
                }
                Text("passkey_save_body")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Spacer()
                Button(action: onSave) {
                    Text("passkey_save_button")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .foregroundStyle(.onDuckYellow)
                .padding(.horizontal)
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close, action: onCancel)
                }
            }
        }
        .tint(.duckYellow)
    }
}

/// The site's passkeys in DuckDepo, to sign in with one.
struct PasskeyChoiceView: View {

    let relyingParty: String
    let passkeys: [Passkey]
    let onCancel: () -> Void
    let onSelect: (Passkey) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if passkeys.isEmpty {
                    ContentUnavailableView {
                        Label("passkey_none_title", systemImage: "person.badge.key")
                    } description: {
                        Text("passkey_none_body \(relyingParty)")
                    }
                } else {
                    List(passkeys) { passkey in
                        Button {
                            onSelect(passkey)
                        } label: {
                            PasskeyRow(passkey: passkey)
                        }
                    }
                }
            }
            .navigationTitle("passkey_sign_in_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close, action: onCancel)
                }
            }
        }
        .tint(.duckYellow)
    }
}

/// Shown while Face ID confirms a passkey sign-in picked from the keyboard.
struct PasskeyWorkingView: View {

    var body: some View {
        ProgressView()
            .controlSize(.large)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
