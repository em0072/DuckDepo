//
//  PasskeyRow.swift
//  DuckDepo
//

import SwiftUI

/// A passkey in a list: the account, then the site. Sized like `PasswordRow`.
struct PasskeyRow: View {

    let passkey: PasskeySummary

    var body: some View {
        HStack(spacing: 12) {
            IconTile(color: .indigo, size: 36) {
                Image(systemName: "person.badge.key.fill")
            }
            VStack(alignment: .leading, spacing: 2) {
                if passkey.userName.isEmpty {
                    Text(verbatim: passkey.relyingParty)
                        .foregroundStyle(.primary)
                } else {
                    Text(verbatim: passkey.userName)
                        .foregroundStyle(.primary)
                    Text(verbatim: passkey.relyingParty)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text("passkey_row_hint"))
    }
}
