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
//            section(for: section)
            Section {
//                ZStack {
//                    VStack {
                ZStack {
                VStack {
                    ForEach(section.fields) { field in
                        FloatingTextField(title: field.title, value: .constant(field.value), id: field.id, delegate: self)
                        Divider()
                    }
                    .onDelete { offsets in
                        guard let index = offsets.first, index < section.fields.count else {return}
                        let fieldToDelete = section.fields[index]
                        delegate?.delete(fieldToDelete, in: section)
                    }
                    .padding(.bottom, 4)
                    
                    addField(for: section)
                        .padding(.vertical, 12)
                }
                .padding(16)
                    
                    NeuSectionBackground()
                }
//                .neumorphicRoundedInner(cornerRadius: 15)
                FixedSpacer(24)
//                    }/
//                NeuSectionBackground()
//                }
            } header: {
                sectionHeader(for: section)
            }
            
                
        }
        .sheet(isPresented: $showingAddNewFieldView) {
            AddNewView(isPresented: $showingAddNewFieldView, duplicateAlertPresented: $showDuplicatedAlert, type: .field, onSave: addCustomField)
        }
        .alert("sv_duplicate_title", isPresented: $showDuplicatedAlert, actions: {
            Button("Ok") {
                self.showDuplicatedAlert = false
            }
        }, message: {
            Text("sv_duplicate_body")
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
            addFieldButtonLabel()
        }
//        .buttonStyle(NeuRectButtonStyle())
        .buttonStyle(NeumorphicRoundedButtonStyle(cornerRadius: 15))
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
        .background(Color.neumorphicBackground)
        .contentShape(Rectangle())
        .cornerRadius(15)
        .neumorphicOuter()

//        .menuStyle(MenuSty)
    }
    
    private func addFieldButtonLabel() -> some View {
        HStack {
            Spacer()
            Label("sv_add_field", systemImage: "plus")
                .font(.callout)
                .foregroundColor(.neumorphicButtonText)
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
                    .foregroundColor(Color.red)
            }
            .buttonStyle(NeumorphicCircleButtonStyle())
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
        ZStack {
            Color.neumorphicBackground
                .ignoresSafeArea()
            VStack {
                SectionView(sections: .constant(doc.sections), options: InputOption().sections)
            }
        }
    }
}
