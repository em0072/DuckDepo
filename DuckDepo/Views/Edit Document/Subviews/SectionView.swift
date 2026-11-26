//
//  SectionView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 02/11/2021.
//

import SwiftUI

protocol SectionViewDelegate {
    func deleteSection(_ sectionID: UUID)
    func addField(named name: String, toSection sectionID: UUID)
    func deleteField(_ fieldID: UUID, inSection sectionID: UUID)
    func fieldIsDuplicate(_ name: String, inSection sectionID: UUID) -> Bool
}

/// Editable sections. Each text field is bound to its field by ID, so deleting a field
/// can't shift values into the wrong rows.
struct SectionView: View {

    @Binding var sections: [DocSection]
    var options: [SectionOption]
    var delegate: SectionViewDelegate?

    @State private var showingAddNewFieldView = false
    @State private var customFieldSectionID: UUID?
    @State private var showDuplicatedAlert = false

    var body: some View {
        ForEach($sections) { $section in
            Section {
                ForEach($section.fields) { $field in
                    HStack {
                        FloatingTextField(title: field.title, value: $field.value)
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

    private func deleteFieldButton(_ field: Field, sectionID: UUID) -> some View {
        Button {
            delegate?.deleteField(field.id, inSection: sectionID)
        } label: {
            Image(systemName: "multiply.circle")
                .foregroundStyle(.red)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("sv_delete_field \(field.title)"))
    }

    @ViewBuilder
    private func addField(for section: DocSection) -> some View {
        let suggestions = possibleFields(in: section)
        if suggestions.isEmpty {
            Button {
                showCustomFieldSheet(for: section)
            } label: {
                addFieldButtonLabel
            }
            .buttonStyle(RoundedRectYellowButtonStyle())
        } else {
            Menu {
                ForEach(suggestions, id: \.self) { name in
                    Button(name) {
                        delegate?.addField(named: name, toSection: section.id)
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

    private func possibleFields(in section: DocSection) -> [String] {
        guard let option = options.first(where: { $0.name == section.name }) else { return [] }
        return option.fields.map(\.name).filter { name in
            !(delegate?.fieldIsDuplicate(name, inSection: section.id) ?? false)
        }
    }

    private func sectionHeader(for section: DocSection) -> some View {
        HStack {
            Text(section.name)
            Spacer()
            Button {
                delegate?.deleteSection(section.id)
            } label: {
                Image(systemName: "multiply.circle.fill")
                    .foregroundStyle(.white, .red)
            }
            .accessibilityLabel(Text("sv_delete_section \(section.name)"))
        }
    }

    private func showCustomFieldSheet(for section: DocSection) {
        customFieldSectionID = section.id
        showingAddNewFieldView = true
    }

    private func addCustomField(_ name: String) {
        guard let sectionID = customFieldSectionID else { return }
        if delegate?.fieldIsDuplicate(name, inSection: sectionID) ?? false {
            showDuplicatedAlert = true
        } else {
            delegate?.addField(named: name, toSection: sectionID)
            showingAddNewFieldView = false
        }
    }
}

#Preview {
    @Previewable @State var sections = [
        DocSection(name: "IDs", fields: [Field(title: "Number", value: "12324311"), Field(title: "Date", value: "01.01.2022")]),
        DocSection(name: "Transport", fields: [Field(title: "Make", value: "Audi"), Field(title: "Model")])
    ]
    List {
        SectionView(sections: $sections, options: InputOption().sections)
    }
    .listStyle(.insetGrouped)
}
