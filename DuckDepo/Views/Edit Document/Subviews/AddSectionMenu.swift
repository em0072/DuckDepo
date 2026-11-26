//
//  AddSectionMenu.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 03/07/2022.
//

import SwiftUI

protocol AddSectionMenuDelegate {
    func addNewSection(_ section: DocSection)
    func sectionIsDuplicate(named name: String) -> Bool
}

struct AddSectionMenu: View {

    /// Predefined sections the document doesn't have yet.
    let availableSections: [SectionKey]
    var delegate: AddSectionMenuDelegate?

    @State private var isAddingCustomSection = false
    @State private var customSectionName = ""
    @State private var showDuplicatedAlert = false

    var body: some View {
        Section {
            addButton
                .alert("anv_new_section", isPresented: $isAddingCustomSection) {
                    TextField("anv_text_filed_new_name_section", text: $customSectionName)
                    Button("add_button", action: addCustomSection)
                        .disabled(customSectionName.trimmingCharacters(in: .whitespaces).isEmpty)
                    Button("cancel_button", role: .cancel) {}
                }
                .alert("asm_duplicate_title", isPresented: $showDuplicatedAlert) {
                    Button("Ok", role: .cancel) {}
                } message: {
                    Text("asm_duplicate_body")
                }
        }
    }

    @ViewBuilder
    private var addButton: some View {
        if availableSections.isEmpty {
            Button(action: startCustomSection) {
                buttonLabel
            }
        } else {
            Menu {
                ForEach(availableSections, id: \.self) { key in
                    Button(key.localizedName) {
                        delegate?.addNewSection(key.makeSection())
                    }
                }
                Divider()
                Button("asm_custom", action: startCustomSection)
            } label: {
                buttonLabel
            }
        }
    }

    private var buttonLabel: some View {
        Label("asm_add_section", systemImage: "plus.rectangle.on.rectangle")
    }

    private func startCustomSection() {
        customSectionName = ""
        isAddingCustomSection = true
    }

    private func addCustomSection() {
        let name = customSectionName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        if delegate?.sectionIsDuplicate(named: name) ?? false {
            showDuplicatedAlert = true
        } else {
            delegate?.addNewSection(DocSection(name: name))
        }
    }
}

#Preview {
    Form {
        AddSectionMenu(availableSections: SectionKey.allCases)
    }
}
