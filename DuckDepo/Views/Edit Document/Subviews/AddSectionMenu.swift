//
//  AddSectionMenu.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 02/11/2021.
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

    @State private var showingAddNewSectionView = false
    @State private var showDuplicatedAlert = false

    var body: some View {
        Section {
            addButton
                .frame(maxWidth: .infinity)
                .sheet(isPresented: $showingAddNewSectionView) {
                    AddNewView(isPresented: $showingAddNewSectionView, duplicateAlertPresented: $showDuplicatedAlert, type: .section, onSave: addCustomSection)
                        .presentationDetents([.height(250)])
                        .presentationDragIndicator(.visible)
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
            Button {
                showingAddNewSectionView = true
            } label: {
                buttonLabel
            }
            .buttonStyle(RoundedRectYellowButtonStyle())
        } else {
            Menu {
                ForEach(availableSections, id: \.self) { key in
                    Button(key.localizedName) {
                        delegate?.addNewSection(key.makeSection())
                    }
                }
                Button("asm_custom") {
                    showingAddNewSectionView = true
                }
            } label: {
                buttonLabel
            }
            .menuStyle(RoundedRectYellowMenuStyle())
        }
    }

    private var buttonLabel: some View {
        Label("asm_add_section", systemImage: "plus")
            .font(.callout)
            .bold()
            .foregroundStyle(Color.duckYellow)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
    }

    private func addCustomSection(_ name: String) {
        if delegate?.sectionIsDuplicate(named: name) ?? false {
            showDuplicatedAlert = true
        } else {
            delegate?.addNewSection(DocSection(name: name))
            showingAddNewSectionView = false
        }
    }
}

#Preview {
    Form {
        AddSectionMenu(availableSections: SectionKey.allCases)
    }
}
