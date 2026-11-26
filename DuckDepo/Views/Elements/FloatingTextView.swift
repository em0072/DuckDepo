//
//  FloatingTextView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 02/11/2021.
//

import SwiftUI

/// A read-only value with a small title. Double-tap or long-press to copy.
struct FloatingTextView: View {

    let title: String
    let value: String
    var url: URL?
    /// Monospaced value (passwords), so similar characters like 0/O and l/I are easy to tell apart.
    var isMonospaced = false
    @Binding var isVisible: Bool

    init(title: String, value: String, url: URL? = nil, isMonospaced: Bool = false, isVisible: Binding<Bool>? = nil) {
        self.title = title
        self.value = value
        self.url = url
        self.isMonospaced = isMonospaced
        self._isVisible = isVisible ?? .constant(true)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 5)
            HStack {
                Group {
                    if let url {
                        Link(processedValue, destination: url)
                    } else {
                        Text(processedValue)
                    }
                }
                .fontDesign(isMonospaced ? .monospaced : .default)
                .padding(.bottom, 5)
                .contextMenu {
                    if let url {
                        ContextMenuView(type: .link(value: url))
                    } else {
                        ContextMenuView(type: .string(value: value))
                    }
                }
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture(count: 2) {
                ClipboardController.shared.copy(string: value)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAction(named: Text("dv_copy_to_clipboard")) {
            ClipboardController.shared.copy(string: value)
        }
    }

    private var processedValue: String {
        isVisible ? value : String(repeating: "•", count: max(value.count, 8))
    }
}

#Preview {
    List {
        FloatingTextView(title: "Title", value: "Value")
    }
}
