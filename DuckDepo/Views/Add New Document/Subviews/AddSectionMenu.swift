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
            Menu {
                Button(role: .destructive) {
                    self.showingAddNewSectionView = true
                } label: {
                    Text("Custom")
                }
                ForEach(menuOptions, id: \.self) { section in
                    let dupCheck = delegate?.sectionIsDuplicate(section) ?? false
                    if !dupCheck {
                        Button {
                            addSection(section)
                        } label: {
                            Text(section)
                        }
                    }
                }
            } label: {
                Label("Add Section", systemImage: "plus.circle")
            }
            .frame(maxWidth: .infinity)
            .sheet(isPresented: $showingAddNewSectionView) {
                AddNewView(isPresented: $showingAddNewSectionView, folderDoesExsistAlertShown: $showDuplicatedAlert, type: .section, addAction: addSection)
            }
            
            .alert("Duplicate", isPresented: $showDuplicatedAlert, actions: {
                Button("Ok") {
                    self.showDuplicatedAlert = false
                }
            }, message: {
                Text("The section with this name already exsists. Please choose a different name.")
            })
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
            AddSectionMenu(menuOptions: .constant(SectionOptions.allOptions))
        }
    }
}
