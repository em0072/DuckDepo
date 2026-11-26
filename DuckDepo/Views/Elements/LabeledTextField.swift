//
//  LabeledTextField.swift
//  DuckDepo
//

import SwiftUI

/// A text field with its title above it, so the title stays visible once the field is filled in.
/// An accessory, if any, follows the title.
struct LabeledTextField<Accessory: View>: View {

    /// Input traits. Credentials must never be auto-capitalized or auto-corrected.
    enum Kind {
        case text
        case multiline
        case name
        case login
        case password
        case url

        var keyboardType: UIKeyboardType {
            switch self {
            case .url: .URL
            case .login: .emailAddress
            case .text, .multiline, .name, .password: .default
            }
        }

        var capitalization: TextInputAutocapitalization {
            switch self {
            case .text, .multiline: .sentences
            case .name: .words
            case .login, .password, .url: .never
            }
        }

        var disablesAutocorrection: Bool {
            switch self {
            case .text, .multiline, .name: false
            case .login, .password, .url: true
            }
        }
    }

    let title: String
    @Binding var value: String
    var kind: Kind = .text
    @ViewBuilder var accessory: Accessory

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                accessory
                    .font(.footnote)
            }
            textField
                .focused($isFocused)
                .accessibilityLabel(title)
                .keyboardType(kind.keyboardType)
                .textInputAutocapitalization(kind.capitalization)
                .autocorrectionDisabled(kind.disablesAutocorrection)
                .fontDesign(kind == .password ? .monospaced : .default)
        }
        .padding(.vertical, 2)
        // Tapping the title focuses the field too.
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused = true
        }
    }

    @ViewBuilder
    private var textField: some View {
        if kind == .multiline {
            TextField("", text: $value, axis: .vertical)
                .lineLimit(1...8)
        } else {
            TextField("", text: $value)
        }
    }
}

extension LabeledTextField where Accessory == EmptyView {
    init(title: String, value: Binding<String>, kind: Kind = .text) {
        self.init(title: title, value: value, kind: kind) {
            EmptyView()
        }
    }
}

#Preview {
    @Previewable @State var name = "Passport"
    @Previewable @State var notes = ""
    Form {
        LabeledTextField(title: "Name", value: $name, kind: .name)
        LabeledTextField(title: "Notes", value: $notes, kind: .multiline)
        LabeledTextField(title: "Password", value: .constant("s3cr3t"), kind: .password)
    }
}
