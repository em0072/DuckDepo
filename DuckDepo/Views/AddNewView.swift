//
//  AddNewFolderView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 26/10/2021.
//

import SwiftUI

struct AddNewView: View {
    
    enum DataType {
        case editFolder(name: String)
        case folder
        case section
        case field
        
        var title: String {
            switch self {
            case .folder, .editFolder(_):
                return "anv_category".localized()
            case .field:
                return "anv_field".localized()
            case .section:
                return "anv_section".localized()
            }
        }
    }
    
    @Binding var isPresented: Bool
    @Binding var folderDoesExsistAlertShown: Bool
    @State var name: String
    var type: DataType
    var onDismiss: (()->())?
    var onSave: ((String) -> ())?
    
    private var title: LocalizedStringKey {
        switch type {
        case .editFolder(let name):
            return "anv_edit_folder \(name)"
        case .folder:
            return "anv_new_folder"
        case .section:
            return "anv_new_section"
        case .field:
            return "anv_new_field"
        }
    }
    
        init(isPresented: Binding<Bool>, duplicateAlertPresented: Binding<Bool>, type: DataType, onDismiss: (()->())? = nil, onSave: ((String) -> ())? = nil) {
            _isPresented = isPresented
            _folderDoesExsistAlertShown = duplicateAlertPresented
            if case .editFolder(let name) = type {
                self.name = name
            } else {
                self.name = ""
            }
            self.type = type
            self.onDismiss = onDismiss
            self.onSave = onSave
        }


    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                VStack() {
                    AddFolderForm(folderDoesExsistAlertShown: $folderDoesExsistAlertShown, name: $name, type: type, onSave: onSave)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(title)
            .navigationBarItems(leading: Button {
                self.isPresented = false
                onDismiss?()
            } label: {
                Image(systemName: "xmark")
            })
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    
}


struct AddFolderForm: View {
    
    @Binding var folderDoesExsistAlertShown: Bool
    @Binding var name: String
    var type: AddNewView.DataType
    var onSave: ((String) -> ())?
    
    var sectionTitle: LocalizedStringKey {
        switch type {
        case .editFolder(_), .folder:
            return "anv_enter_name_folder"
        case .section:
            return "anv_enter_name_section"
        case .field:
            return "anv_enter_name_field"
        }
    }
    
    var buttonTitle: LocalizedStringKey {
        switch type {
        case .editFolder(_):
            return "anv_edit_folder"
        case .folder:
            return "anv_add_new_folder"
        case .section:
            return "anv_add_new_section"
        case .field:
            return "anv_add_new_field"
        }
    }
    
    var textFieldPrompt: LocalizedStringKey {
        switch type {
        case .editFolder(_), .folder:
            return "anv_text_filed_new_name_folder"
        case .section:
            return "anv_text_filed_new_name_section"
        case .field:
            return "anv_text_filed_new_name_field"
        }
    }

    
    var body: some View {
        Form {
            Section {
                TextField(textFieldPrompt, text: $name, prompt: Text(textFieldPrompt))
            } header: {
                Text(sectionTitle)
            }
            Section {
                HStack {
                    Spacer()
                Button(action: {
                    self.onSave?(name)
                }, label: {
                    Text(buttonTitle)
                })
                    .disabled(name.isEmpty)
                    Spacer()
                }
                .foregroundColor(name.isEmpty ? Color.duckDisabledText : Color.black)
                .listRowBackground(name.isEmpty ? Color.duckDisabledButton : Color.duckYellow)
            }
        }
        .alert("anv_duplicate_title", isPresented: $folderDoesExsistAlertShown, actions: {
            Button("Ok") {
                self.folderDoesExsistAlertShown = false
            }
        }, message: {
            Text("asm_duplicate_body \(type.title)")
        })
    }
    
}


struct AddNewFolderView_Previews: PreviewProvider {
    static var previews: some View {
        AddNewView(isPresented: .constant(true), duplicateAlertPresented: .constant(false), type: .folder)
    }
}

