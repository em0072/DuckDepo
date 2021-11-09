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
    var options: [SectionOption]
    var delegate: SectionViewDelegate?
    @State var showingAddNewFieldView: Bool = false
    @State var customFieldSection: DocSection?
    @State var showDuplicatedAlert: Bool = false
    @State var menuOptions: [String] = FieldOptions.allOptions

    
    //MARK: - View Bulding
    var body: some View {
        List(sections) { section in
//            section(for: section)
            Section {
                ForEach(section.fields) { field in
                    FloatingTextField(title: field.title, value: field.value, id: field.id, delegate: self)
                }
                .onDelete { offsets in
                    guard let index = offsets.first, index < section.fields.count else {return}
                    let fieldToDelete = section.fields[index]
                    delegate?.delete(fieldToDelete, in: section)
                }
                    addField(for: section)
//                Menu {
//                    ForEach(possibleFields(for: section.name), id: \.self) { field in
//                        let dupCheck = delegate?.fieldIsDuplicate(field, in: section) ?? false
//                        if !dupCheck {
//                            Button {
//                                delegate?.addNewFieldWith(name: field, in: section)
//                            } label: {
//                                Text(field)
//                            }
//                        }
//                    }
//                    Button(role: .destructive) {
//                        customFieldSection = section
//                        self.showingAddNewFieldView = true
//                    } label: {
//                        Text("Custom")
//                    }
//                } label: {
//                    Label("Add Field", systemImage: "plus.circle")
//                }
                .frame(maxWidth: .infinity)
            } header: {
                sectionHeader(for: section)
            }
            
        }
        .sheet(isPresented: $showingAddNewFieldView) {
            AddNewView(isPresented: $showingAddNewFieldView, duplicateAlertPresented: $showDuplicatedAlert, type: .field, onSave: addCustomField)
        }
        .alert("Duplicate", isPresented: $showDuplicatedAlert, actions: {
            Button("Ok") {
                self.showDuplicatedAlert = false
            }
        }, message: {
            Text("The field with this name already exsists. Please choose a different name.")
        })
    }
    
    @ViewBuilder func addField(for section: DocSection) -> some View {
            if possibleFields(in: section).isEmpty {
                addFieldButton(for: section)
                    .id(UUID(uuidString: "add"))
            } else {
                menuButton(for: section)
                    .id(UUID(uuidString: "add"))
            }
    }
    
    @ViewBuilder func addFieldButton(for section: DocSection) -> some View {
        Button {
            customFieldSection = section
            self.showingAddNewFieldView = true
        } label: {
            Label("Add Field", systemImage: "plus.circle")
        }
    }
    
    @ViewBuilder func menuButton(for section: DocSection) -> some View {
        Menu {
            ForEach(possibleFields(in: section), id: \.self) { field in
//                let dupCheck = delegate?.fieldIsDuplicate(field, in: section) ?? false
//                if !dupCheck {
                    Button {
                        delegate?.addNewFieldWith(name: field, in: section)
                    } label: {
                        Text(field)
                    }
//                }
            }
            Button(role: .destructive) {
                customFieldSection = section
                self.showingAddNewFieldView = true
            } label: {
                Text("Custom")
            }
        } label: {
            Label("Add Field", systemImage: "plus.circle")
        }
    }
    
    func possibleFields(in section: DocSection) -> [String] {
        var possibleFields = [String]()
        for option in options {
            if option.name == section.name {
                for field in option.fields {
                    let dupCheck = delegate?.fieldIsDuplicate(field.name, in: section) ?? false
                    if !dupCheck {
                        possibleFields.append(field.name)
                    }
                }
                break
            }
        }
        return possibleFields
    }

    
//    func predefinedFields(for section: String) -> [String] {
//        var possibleFields = [String]()
//        for sectionOption in options {
//            if sectionOption.name == section {
//                possibleFields = sectionOption.fields.map{ $0.name }
//                break
//            }
//        }
//        return possibleFields
//    }
    
    func sectionHeader(for section: DocSection) -> some View {
        return HStack {
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
    
    func fieldOptions(for section: DocSection) -> [String] {
        FieldOptions.allOptions
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
            SectionView(sections: .constant(doc.sections), options: InputOption().sections)
        }
    }
}
