//
//  SectionView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 02/11/2021.
//

import SwiftUI

protocol SectionViewDelegate {
    func delete(_ section: DocSection)
    func addNewFieldWith(name: String, in section: DocSection)
    func delete(_ field: Field, in section: DocSection)
    func fieldIsDuplicate(_ name: String, in section: DocSection) -> Bool
    func valueChanged(for field: Field, newValue: String)
    
}


struct SectionView: View {
    
    @Binding var sections: [DocSection]

    var delegate: SectionViewDelegate?
    @State var showingAddNewFieldView: Bool = false
    @State var customFieldSection: DocSection?
    @State var showDuplicatedAlert: Bool = false

    var body: some View {
        ForEach(sections) { section in
            Section {
                ForEach(section.fields) { field in
                    FloatingTextField(title: field.title, value: field.value, id: field.id, delegate: self)
                }
                .onDelete { offsets in
                    guard let index = offsets.first, index < section.fields.count else {return}
                    let fieldToDelete = section.fields[index]
                    delegate?.delete(fieldToDelete, in: section)
                }
                Menu {
                    Button(role: .destructive) {
                        customFieldSection = section
                        self.showingAddNewFieldView = true
                    } label: {
                        Text("Custom")
                    }
                    ForEach(FieldOptions.allOptions, id: \.self) { field in
                        let dupCheck = delegate?.fieldIsDuplicate(field, in: section) ?? false
                        if !dupCheck {
                            Button {
                                delegate?.addNewFieldWith(name: field, in: section)
                            } label: {
                                Text(field)
                            }
                        }
                    }
                } label: {
                    Label("Add Field", systemImage: "plus.circle")
                }
                .frame(maxWidth: .infinity)
            } header: {
                HStack {
                    Text(section.name)
                    Spacer()
                    Button {
                        delegate?.delete(section)
                    } label: {
                        Image(systemName: "multiply.circle.fill")
                            .foregroundColor(Color.red)
                    }
                }
            }
            
        }
        .sheet(isPresented: $showingAddNewFieldView) {
            AddNewView(isPresented: $showingAddNewFieldView, folderDoesExsistAlertShown: $showDuplicatedAlert, type: .field, addAction: addCustomField)
        }
        .alert("Duplicate", isPresented: $showDuplicatedAlert, actions: {
            Button("Ok") {
                self.showDuplicatedAlert = false
            }
        }, message: {
            Text("The field with this name already exsists. Please choose a different name.")
        })

    }
    
    private func addCustomField(_ name: String) {
        guard let customFieldSection = customFieldSection else { return }
        let duplicateCheck = delegate?.fieldIsDuplicate(name, in: customFieldSection) ?? false
        if duplicateCheck {
            showDuplicatedAlert = true
        } else {
            delegate?.addNewFieldWith(name: name, in: customFieldSection)
            showingAddNewFieldView = false
        }

    }
    
}


extension SectionView: FloatingTextFieldDelegate {
    func valueChangedForField(with id: UUID, newValue: String) {
        for section in sections {
            if let foundField = section.fields.first(where: { $0.id == id }) {
                delegate?.valueChanged(for: foundField, newValue: newValue)
            }
        }
    }
    
    
    
    
}

struct SectionView_Previews: PreviewProvider {
    
    static var doc = Document(name: "Passport", sections:
                                [DocSection(name: "Ids")
                                ,DocSection(name: "Transport")]
    )
    
    static var previews: some View {
        Form {
            SectionView(sections: .constant(doc.sections))
        }
    }
}
