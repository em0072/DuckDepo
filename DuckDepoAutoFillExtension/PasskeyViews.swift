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

/// Shown while Face ID confirms a passkey is made or used. Replacing the screen that was tapped also
/// stops a second tap from starting it again.
struct PasskeyWorkingView: View {

    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            ProgressView()
                .controlSize(.large)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(role: .close, action: onCancel)
                    }
                }
        }
        .tint(.duckYellow)
    }
}
