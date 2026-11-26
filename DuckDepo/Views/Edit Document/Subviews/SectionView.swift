//
//  SectionView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 02/11/2021.
//

import SwiftUI

protocol SectionViewDelegate {
    func deleteSection(_ sectionID: UUID)
    func addField(_ field: Field, toSection sectionID: UUID)
    func deleteField(_ fieldID: UUID, inSection sectionID: UUID)
    func fieldIsDuplicate(named name: String, inSection sectionID: UUID) -> Bool
}

/// Editable sections. Each text field is bound to its field by ID, so deleting a field
/// can't shift values into the wrong rows.
struct SectionView: View {

    @Binding var sections: [DocSection]
    var delegate: SectionViewDelegate?

    @State private var showingAddNewFieldView = false
    @State private var customFieldSectionID: UUID?
    @State private var showDuplicatedAlert = false

    var body: some View {
        ForEach($sections) { $section in
            Section {
                ForEach($section.fields) { $field in
                    HStack {
                        fieldEditor($field)
                        deleteFieldButton(field, sectionID: section.id)
                    }
                }
                addField(for: section)
            } header: {
                sectionHeader(for: section)
            }
        }
        .sheet(isPresented: $showingAddNewFieldView) {
            AddNewView(isPresented: $showingAddNewFieldView, duplicateAlertPresented: $showDuplicatedAlert, type: .field, onSave: addCustomField)
                .presentationDetents([.height(250)])
                .presentationDragIndicator(.visible)
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
            FloatingTextField(title: field.wrappedValue.displayTitle, value: field.value)
        }
    }

    private func deleteFieldButton(_ field: Field, sectionID: UUID) -> some View {
        Button {
            delegate?.deleteField(field.id, inSection: sectionID)
        } label: {
            Image(systemName: "multiply.circle")
                .foregroundStyle(.red)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("sv_delete_field \(field.displayTitle)"))
    }

    @ViewBuilder
    private func addField(for section: DocSection) -> some View {
        let suggestions = section.missingPredefinedFields
        if suggestions.isEmpty {
            Button {
                showCustomFieldSheet(for: section)
            } label: {
                addFieldButtonLabel
            }
            .buttonStyle(RoundedRectYellowButtonStyle())
        } else {
            Menu {
                ForEach(suggestions, id: \.self) { key in
                    Button(key.localizedName) {
                        delegate?.addField(key.makeField(), toSection: section.id)
                    }
                }
                Button("sv_custom") {
                    showCustomFieldSheet(for: section)
                }
            } label: {
                addFieldButtonLabel
            }
            .menuStyle(RoundedRectYellowMenuStyle())
        }
    }

    private var addFieldButtonLabel: some View {
        Label("sv_add_field", systemImage: "plus")
            .font(.callout)
            .bold()
            .foregroundStyle(Color.duckYellow)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
    }

    private func sectionHeader(for section: DocSection) -> some View {
        HStack {
            Text(section.displayName)
            Spacer()
            Button {
                delegate?.deleteSection(section.id)
            } label: {
                Image(systemName: "multiply.circle.fill")
                    .foregroundStyle(.white, .red)
            }
            .accessibilityLabel(Text("sv_delete_section \(section.displayName)"))
        }
    }

    private func showCustomFieldSheet(for section: DocSection) {
        customFieldSectionID = section.id
        showingAddNewFieldView = true
    }

    private func addCustomField(_ name: String) {
        guard let sectionID = customFieldSectionID else { return }
        if delegate?.fieldIsDuplicate(named: name, inSection: sectionID) ?? false {
            showDuplicatedAlert = true
        } else {
            delegate?.addField(Field(title: name), toSection: sectionID)
            showingAddNewFieldView = false
        }
    }
}

/// A date field: "Add Date" until a day is picked, then a date picker.
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
            HStack {
                Text(title)
                Spacer()
                Button("date_add") {
                    value = FieldDate.storedValue(fromLocalDate: Date()) ?? ""
                }
                .tint(.duckYellow)
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
    List {
        SectionView(sections: $sections)
    }
    .listStyle(.insetGrouped)
}
