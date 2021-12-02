//
//  AddSectionMenu.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 02/11/2021.
//

import SwiftUI

protocol AddSectionMenuDelegate {
    func addNewSection(_ name: String)
    func sectionIsDuplicate(_ name: String) -> Bool
}

struct AddSectionMenu: View {
    
    
    @State var showingAddNewSectionView: Bool = false
    @State var showDuplicatedAlert: Bool = false
    @Binding var menuOptions: [String]
    var delegate: AddSectionMenuDelegate?
    
    var body: some View {
        Section {
        addButton
            .frame(maxWidth: .infinity)
            .sheet(isPresented: $showingAddNewSectionView) {
                AddNewView(isPresented: $showingAddNewSectionView, duplicateAlertPresented: $showDuplicatedAlert, type: .section, onSave: addSection)
            }
            .alert("asm_duplicate_title", isPresented: $showDuplicatedAlert, actions: {
                Button("Ok") {
                    self.showDuplicatedAlert = false
                }
            }, message: {
                Text("asm_duplicate_body")
            })
        }
    }
    
    
    @ViewBuilder var addButton: some View {
        if possibleOptions.isEmpty {
            addCustomSectionButton
        } else {
            menuButton
        }
    }
    
    var addCustomSectionButton: some View {
        Button {
            self.showingAddNewSectionView = true
        } label: {
            Label("asm_add_section", systemImage: "plus.circle")
        }

    }
    
    var menuButton: some View {
        Menu {
            ForEach(possibleOptions, id: \.self) { section in
                    Button {
                        addSection(section)
                    } label: {
                        Text(section)
                    }
            }
            Button(role: .destructive) {
                self.showingAddNewSectionView = true
            } label: {
                Text("asm_custom")
            }
        } label: {
            Label("asm_add_section", systemImage: "plus.circle")
        }
    }
    
    var possibleOptions: [String] {
        var options = [String]()
        for option in menuOptions {
            let dupCheck = delegate?.sectionIsDuplicate(option) ?? false
            if !dupCheck {
                options.append(option)
            }
        }
        return options
    }
    
    func addSection(_ name: String) {
        let duplicateCheck = delegate?.sectionIsDuplicate(name) ?? false
        if duplicateCheck {
            showDuplicatedAlert = true
        } else {
            delegate?.addNewSection(name)
            showingAddNewSectionView = false
        }
    }
}

struct AddSectionMenu_Previews: PreviewProvider {
    static var previews: some View {
        Form {
            AddSectionMenu(menuOptions: .constant(InputOption().listOfSectionNames()))
        }
    }
}
