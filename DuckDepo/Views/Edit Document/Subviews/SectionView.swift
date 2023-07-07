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
    
    //MARK: - View Bulding
    var body: some View {
        ForEach(sections) { section in
            Section {
                    VStack {
                        ForEach(0..<section.fields.count, id: \.self) { index in
                            let field = section.fields[index]
                            HStack {
                                FloatingTextField(title: field.title, value: .constant(field.value), id: field.id, delegate: self)
                                deleteField(field, in: section)
                            }
                            if index != section.fields.count - 1 {
                                Divider()
                            }
                        }
                        .padding(.bottom, 4)
                        addField(for: section)
                    }
            } header: {
                sectionHeader(for: section)
            }
            
            
        }
        .sheet(isPresented: $showingAddNewFieldView) {
            AddNewView(isPresented: $showingAddNewFieldView, duplicateAlertPresented: $showDuplicatedAlert, type: .field, onSave: addCustomField)
                .presentationDetents([.height(250)])
                .presentationDragIndicator(.visible)
        }
        .alert("sv_duplicate_title", isPresented: $showDuplicatedAlert, actions: {
            Button("Ok") {
                self.showDuplicatedAlert = false
            }
        }, message: {
            Text("sv_duplicate_body")
        })
    }
    
    private func deleteField(_ field: Field, in section: DocSection) -> some View {
        Button {
            delegate?.delete(field, in: section)
        } label: {
            Image(systemName: "multiply.circle")
                .foregroundColor(Color.red)
        }
        .buttonStyle(.plain)
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
            addFieldButtonLabel()
        }
        .buttonStyle(RoundedRectYellowButtonStyle())
    }
    
    @ViewBuilder func menuButton(for section: DocSection) -> some View {
        Menu {
            ForEach(possibleFields(in: section), id: \.self) { field in
                Button {
                    delegate?.addNewFieldWith(name: field, in: section)
                } label: {
                    Text(field)
                }
            }
            
            Button(role: .destructive) {
                customFieldSection = section
                self.showingAddNewFieldView = true
            } label: {
                Text("sv_custom")
            }
        } label: {
            addFieldButtonLabel()
        }
        .menuStyle(RoundedRectYellowMenuStyle())
    }
    
    private func addFieldButtonLabel() -> some View {
        HStack {
            Spacer()
            Label("sv_add_field", systemImage: "plus")
                .font(.callout)
                .bold()
                .foregroundColor(.duckYellow)
                .padding(.vertical, 14)
            Spacer()
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
    
    func sectionHeader(for section: DocSection) -> some View {
        return HStack {
            Text(section.name)
                .font(.footnote)
                .foregroundColor(.neumorphicText)
                .textCase(.uppercase)
            
            Spacer()
            Button {
                delegate?.delete(section)
            } label: {
                Image(systemName: "multiply.circle.fill")
                    .foregroundStyle(.white, .red)
            }
        }
        .padding(.horizontal, 16)
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
                                [DocSection(name: "IDs", fields: [Field(title: "Number", value: "12324311"),
                                                                  Field(title: "Date", value: "01.01.2022")])
                                 ,DocSection(name: "Transport", fields: [Field(title: "Make", value: "Audi"),
                                                                         Field(title: "Model")])]
    )
    
    static var previews: some View {
            List {
                SectionView(sections: .constant(doc.sections), options: InputOption().sections)
            }
            .listStyle(.insetGrouped)
    }
}
