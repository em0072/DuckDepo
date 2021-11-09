//
//  AddNewFolderView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 26/10/2021.
//

import SwiftUI
import Introspect

struct AddNewView: View {
    
    enum DataType {
        case editFolder(name: String)
        case folder
        case section
        case field
        
        var title: String {
            switch self {
            case .folder, .editFolder(_):
                return "category"
            case .field:
                return "field"
            case .section:
                return "section"
            }
        }
    }
    
    @Binding var isPresented: Bool
    @Binding var folderDoesExsistAlertShown: Bool
    @State var name: String
    var type: DataType
    var onDismiss: (()->())?
    var onSave: ((String) -> ())?
    
    private var title: String {
        switch type {
        case .editFolder(let name):
            return "Edit \(name)"
        default:
            return "New \(type.title.capitalized)"
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
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button {
                self.isPresented = false
                onDismiss?()
            } label: {
                Image(systemName: "xmark")
            })
        }
    }
    
    
}


struct AddFolderForm: View {
    
    @Binding var folderDoesExsistAlertShown: Bool
    @Binding var name: String
    var type: AddNewView.DataType
    var onSave: ((String) -> ())?
    
    var sectionTitle: String {
        switch type {
        case .editFolder(_):
            return "Enter a new name for the \(type.title.capitalized)"
        default:
            return "Enter a name for a new \(type.title.capitalized)"
        }
    }
    
    var buttonTitle: String {
        switch type {
        case .editFolder(_):
            return "Edit \(type.title.capitalized)"
        default:
            return "Add new \(type.title.capitalized)"
        }
    }

    
    var body: some View {
        Form {
            Section {
                TextField("Add the name of a new \(type.title)", text: $name, prompt: Text("New \(type.title.capitalized) Name"))
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
        .alert("Duplicate", isPresented: $folderDoesExsistAlertShown, actions: {
            Button("Ok") {
                self.folderDoesExsistAlertShown = false
            }
        }, message: {
            Text("The \(type.title) with this name already exsists. Please choose a different name.")
        })
    }
    
}


struct AddNewFolderView_Previews: PreviewProvider {
    static var previews: some View {
        AddNewView(isPresented: .constant(true), duplicateAlertPresented: .constant(false), type: .folder)
    }
}

