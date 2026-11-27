//
//  FieldValueRow.swift
//  DuckDepo
//

import SwiftUI

/// A value with its title, a copy button and, for secrets, a show/hide button.
struct FieldValueRow: View {

    let title: String
    let value: String
    var url: URL?
    /// Hidden until the user taps the eye button.
    var isSecret = false
    /// For passwords, so similar characters like 0/O and l/I are easy to tell apart.
    var isMonospaced = false

    @State private var isRevealed = false

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                valueView
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            if isSecret {
                Button {
                    withAnimation {
                        isRevealed.toggle()
                    }
                } label: {
                    Image(systemName: isRevealed ? "eye.slash" : "eye")
                        .contentTransition(.symbolEffect(.replace))
                }
                .accessibilityLabel(Text(isRevealed ? "hide_value \(title)" : "show_value \(title)"))
            }
            Button(action: copy) {
                Image(systemName: "doc.on.doc")
            }
            .accessibilityLabel(Text("copy_value \(title)"))
        }
        .buttonStyle(.borderless)
        .contextMenu {
            if let url {
                ContextMenuView(type: .link(value: url))
            } else {
                ContextMenuView(type: .string(value: value))
            }
        }
    }

    @ViewBuilder
    private var valueView: some View {
        if isSecret && !isRevealed {
            // A fixed length, so the dots don't give the value's length away.
            Text(verbatim: String(repeating: "•", count: 10))
                .accessibilityLabel(Text("value_hidden"))
        } else if let url {
            Link(value, destination: url)
        } else {
            Text(value)
                .fontDesign(isMonospaced ? .monospaced : .default)
        }
    }

    private func copy() {
        ClipboardController.shared.copy(string: value)
    }
}

#Preview {
    List {
        FieldValueRow(title: "Number", value: "AB 1234567", isSecret: true)
        FieldValueRow(title: "Full Name", value: "Jane Doe")
        FieldValueRow(title: "Website", value: "duckdepo.com", url: URL(string: "https://duckdepo.com"))
    }
}
