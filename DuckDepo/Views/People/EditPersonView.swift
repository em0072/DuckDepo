//
//  EditPersonView.swift
//  DuckDepo
//

import SwiftUI

/// Adds a person, or changes a person's name and color.
struct EditPersonView: View {

    enum Mode: Identifiable {
        case new
        case existing(Person)

        var id: String {
            switch self {
            case .new: "new"
            case .existing(let person): person.id.uuidString
            }
        }
    }

    let mode: Mode
    /// After saving, with the saved person.
    var onSave: ((Person) -> Void)?

    @Environment(\.dismiss) private var dismiss
    private var directory = PeopleDirectory.shared
    @State private var name: String
    @State private var color: PersonColor
    @State private var original: Person?
    /// A new person's ID, made once: saving twice (Return, then ✓) must not add two people.
    @State private var newID = UUID()
    @State private var isSaved = false
    @State private var isShowingDiscardDialog = false
    @State private var isConfirmingDelete = false
    @State private var saveFailed = false
    @FocusState private var isNameFocused: Bool

    init(mode: Mode, onSave: ((Person) -> Void)? = nil) {
        self.mode = mode
        self.onSave = onSave
        switch mode {
        case .new:
            _name = State(initialValue: "")
            _color = State(initialValue: PeopleDirectory.shared.unusedColor)
        case .existing(let person):
            _name = State(initialValue: person.name)
            _color = State(initialValue: person.color)
            _original = State(initialValue: person)
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var edited: Person {
        var person = original ?? Person(id: newID)
        person.name = trimmedName
        person.color = color
        return person
    }

    private var hasChanges: Bool {
        if let original {
            return edited != original
        }
        return !trimmedName.isEmpty
    }

    private var isNew: Bool {
        original == nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    PersonAvatar(person: edited)
                        .frame(width: 88, height: 88)
                        .frame(maxWidth: .infinity)
                        .animation(.snappy, value: color)
                        .listRowBackground(Color.clear)
                }
                Section {
                    TextField("person_name", text: $name)
                        .textContentType(.name)
                        .textInputAutocapitalization(.words)
                        .focused($isNameFocused)
                        .submitLabel(.done)
                        .onSubmit(save)
                }
                Section("person_color") {
                    ColorChoices(selection: $color)
                }
                if !isNew {
                    Section {
                        Button("person_delete", role: .destructive) {
                            isConfirmingDelete = true
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle(isNew ? "person_add" : "person_edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) {
                        if hasChanges {
                            isShowingDiscardDialog = true
                        } else {
                            dismiss()
                        }
                    }
                    .confirmationDialog("discard_changes_title", isPresented: $isShowingDiscardDialog, titleVisibility: .visible) {
                        Button("discard_changes_button", role: .destructive) {
                            dismiss()
                        }
                        Button("keep_editing_button", role: .cancel) {}
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm, action: save)
                        .disabled(trimmedName.isEmpty)
                }
            }
            .alert(Text("person_delete_title \(original?.name ?? "")"), isPresented: $isConfirmingDelete) {
                Button("delete", role: .destructive) {
                    if let original {
                        directory.delete(original)
                    }
                    dismiss()
                }
            } message: {
                Text("person_delete_body")
            }
            .alert("save_failed_title", isPresented: $saveFailed) {
                Button("Ok", role: .cancel) {}
            } message: {
                Text("save_failed_body")
            }
            .onAppear {
                if isNew {
                    isNameFocused = true
                }
            }
        }
        .interactiveDismissDisabled(hasChanges)
    }

    private func save() {
        guard !trimmedName.isEmpty, !isSaved else { return }
        let person = edited
        guard isNew ? directory.add(person) : directory.update(person) else {
            saveFailed = true
            return
        }
        isSaved = true
        onSave?(person)
        dismiss()
    }
}

/// The colors to choose from, as swatches.
private struct ColorChoices: View {

    @Binding var selection: PersonColor

    @ScaledMetric(relativeTo: .body) private var swatchSize: CGFloat = 36

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: swatchSize + 8), spacing: 10)], spacing: 12) {
            ForEach(PersonColor.allCases) { color in
                Button {
                    withAnimation(.snappy) {
                        selection = color
                    }
                } label: {
                    Circle()
                        .fill(color.fill)
                        .frame(width: swatchSize, height: swatchSize)
                        .overlay {
                            if selection == color {
                                Image(systemName: "checkmark")
                                    .font(.system(size: swatchSize * 0.42, weight: .bold))
                                    .foregroundStyle(.white)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(3)
                        .overlay {
                            Circle()
                                .strokeBorder(selection == color ? color.color : .clear, lineWidth: 2)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(color.localizedName))
                .accessibilityAddTraits(selection == color ? .isSelected : [])
            }
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    EditPersonView(mode: .new)
}
