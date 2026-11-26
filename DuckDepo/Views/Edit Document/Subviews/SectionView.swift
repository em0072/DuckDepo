//
//  SectionView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 04/07/2022.
//

import SwiftUI

protocol SectionViewDelegate {
    func deleteSection(_ sectionID: UUID)
    func addField(_ field: Field, toSection sectionID: UUID)
    func deleteField(_ fieldID: UUID, inSection sectionID: UUID)
    func fieldIsDuplicate(named name: String, inSection sectionID: UUID) -> Bool
}

/// The document's sections, each with its fields, a way to add fields and a menu to remove the section.
struct SectionView: View {

    @Binding var sections: [DocSection]
    var delegate: SectionViewDelegate?

    @State private var customFieldSectionID: UUID?
    @State private var customFieldName = ""
    @State private var showDuplicatedAlert = false

    var body: some View {
        ForEach($sections) { $section in
            Section {
                ForEach($section.fields) { $field in
                    fieldEditor($field)
                }
                .onDelete { offsets in
                    let ids = offsets.map { section.fields[$0].id }
                    for id in ids {
                        delegate?.deleteField(id, inSection: section.id)
                    }
                }
                addFieldButton(for: section)
            } header: {
                sectionHeader(for: section)
            }
        }
        .alert("anv_new_field", isPresented: isAddingCustomField) {
            TextField("anv_text_filed_new_name_field", text: $customFieldName)
            Button("add_button", action: addCustomField)
                .disabled(customFieldName.trimmingCharacters(in: .whitespaces).isEmpty)
            Button("cancel_button", role: .cancel) {}
        }
        .alert("sv_duplicate_title", isPresented: $showDuplicatedAlert) {
            Button("Ok", role: .cancel) {}
        } message: {
            Text("sv_duplicate_body")
        }
    }

    @ViewBuilder
    private func fieldEditor(_ field: Binding<Field>) -> some View {
        // A date field whose text an older version wrote and that couldn't be read as one day stays text.
        if field.wrappedValue.type == .date,
           field.wrappedValue.value.isEmpty || FieldDate.components(from: field.wrappedValue.value) != nil {
            DateFieldRow(title: field.wrappedValue.displayTitle, value: field.value)
        } else {
            LabeledTextField(title: field.wrappedValue.displayTitle, value: field.value,
                             kind: field.wrappedValue.isMultiline ? .multiline : .text)
        }
    }

    @ViewBuilder
    private func addFieldButton(for section: DocSection) -> some View {
        let suggestions = section.missingPredefinedFields
        if suggestions.isEmpty {
            Button {
                startCustomField(in: section)
            } label: {
                Label("sv_add_field", systemImage: "plus.circle.fill")
            }
        } else {
            Menu {
                ForEach(suggestions, id: \.self) { key in
                    Button(key.localizedName) {
                        delegate?.addField(key.makeField(), toSection: section.id)
                    }
                }
                Divider()
                Button("sv_custom") {
                    startCustomField(in: section)
                }
            } label: {
                Label("sv_add_field", systemImage: "plus.circle.fill")
            }
        }
    }

    private func sectionHeader(for section: DocSection) -> some View {
        HStack {
            Text(section.displayName)
            Spacer()
            Menu {
                Button(role: .destructive) {
                    delegate?.deleteSection(section.id)
                } label: {
                    Label("remove_section", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.body)
            }
            .accessibilityLabel(Text("section_options \(section.displayName)"))
        }
    }

    private var isAddingCustomField: Binding<Bool> {
        Binding {
            customFieldSectionID != nil
        } set: { isPresented in
            if !isPresented {
                customFieldSectionID = nil
            }
        }
    }

    private func startCustomField(in section: DocSection) {
        customFieldName = ""
        customFieldSectionID = section.id
    }

    private func addCustomField() {
        let name = customFieldName.trimmingCharacters(in: .whitespaces)
        guard let sectionID = customFieldSectionID, !name.isEmpty else { return }
        if delegate?.fieldIsDuplicate(named: name, inSection: sectionID) ?? false {
            showDuplicatedAlert = true
        } else {
            delegate?.addField(Field(title: name), toSection: sectionID)
        }
    }
}

struct DateFieldRow: View {

    let title: String
    /// "yyyy-MM-dd", or empty.
    @Binding var value: String

    var body: some View {
        if let date = FieldDate.localDate(from: value) {
            DatePicker(selection: Binding(get: { date }, set: { newDate in
                if let stored = FieldDate.storedValue(fromLocalDate: newDate) {
                    value = stored
                }
            }), displayedComponents: .date) {
                Text(title)
            }
        } else {
            LabeledContent(title) {
                Button("date_add") {
                    value = FieldDate.storedValue(fromLocalDate: Date()) ?? ""
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var sections = [
        DocSection(key: SectionKey.documentInfo.rawValue, name: "Document Info",
                   fields: [FieldKey.number.makeField(), FieldKey.expiryDate.makeField()]),
        DocSection(name: "Transport", fields: [Field(title: "Make", value: "Audi"), Field(title: "Model")])
    ]
    Form {
        SectionView(sections: $sections)
    }
}
