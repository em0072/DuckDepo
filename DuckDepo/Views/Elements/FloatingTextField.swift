//
//  FloatingTextField.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 29/10/2021.
//

import SwiftUI

/// A text field whose title floats above the text once something is typed.
/// It edits the binding directly, so rows can be added, removed and reordered safely.
struct FloatingTextField: View {

    /// Input traits. Credentials must never be auto-capitalized or auto-corrected.
    enum Kind {
        case text
        case name
        case login
        case password
        case url

        var keyboardType: UIKeyboardType {
            switch self {
            case .url: return .URL
            case .login: return .emailAddress
            case .text, .name, .password: return .default
            }
        }

        var capitalization: TextInputAutocapitalization {
            switch self {
            case .text: return .sentences
            case .name: return .words
            case .login, .password, .url: return .never
            }
        }

        var disablesAutocorrection: Bool {
            switch self {
            case .text, .name: return false
            case .login, .password, .url: return true
            }
        }
    }

    let title: String
    @Binding var value: String
    var kind: Kind = .text

    var body: some View {
        ZStack(alignment: .leading) {
            Text(title)
                .foregroundStyle(.secondary)
                .offset(y: value.isEmpty ? -5 : -25)
                .scaleEffect(value.isEmpty ? 1 : 0.8, anchor: .leading)
                .accessibilityHidden(true)
            TextField("", text: $value)
                .accessibilityLabel(title)
                .offset(y: value.isEmpty ? -5 : 0)
                .keyboardType(kind.keyboardType)
                .textInputAutocapitalization(kind.capitalization)
                .autocorrectionDisabled(kind.disablesAutocorrection)
                .fontDesign(kind == .password ? .monospaced : .default)
        }
        .padding(.top, 15)
        .padding(.bottom, 5)
        .animation(.easeInOut(duration: 0.2), value: value.isEmpty)
    }
}

#Preview {
    @Previewable @State var value = ""
    List {
        FloatingTextField(title: "Title", value: $value)
        FloatingTextField(title: "Password", value: .constant("s3cr3t"), kind: .password)
    }
}
