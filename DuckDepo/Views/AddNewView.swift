//
//  AddNewFolderView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 26/10/2021.
//

import SwiftUI

struct AddNewView: View {
    
    enum DataType: String {
        case folder = "category"
        case section
        case field
    }
    
    @Binding var isPresented: Bool
    @Binding var folderDoesExsistAlertShown: Bool
    @State private var newCategoryName: String = ""
    var type: DataType
    var addAction: ((String) -> ())?
    
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                VStack() {
                    AddFolderForm(folderDoesExsistAlertShown: $folderDoesExsistAlertShown, name: $newCategoryName, type: type, addAction: addAction)
                }
            }
            .navigationTitle("New \(type.rawValue.capitalized)")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button {
                self.isPresented = false
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
    var addAction: ((String) -> ())?
    
    var body: some View {
        Form {
            Section {
                TextField("Add the name of a new \(type.rawValue)", text: $name, prompt: Text("New \(type.rawValue.capitalized) Name"))
            } header: {
                Text("Enter a name for a new \(type.rawValue)")
            }
            Section {
                HStack {
                    Spacer()
                Button(action: {
                    self.addAction?(name)
                }, label: {
                    Text("Add new \(type.rawValue)")
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
            Text("The \(type.rawValue) with this name already exsists. Please choose a different name.")
        })
    }
    
}


struct AddNewFolderView_Previews: PreviewProvider {
    static var previews: some View {
        AddNewView(isPresented: .constant(true), folderDoesExsistAlertShown: .constant(false), type: .folder, addAction: nil)
    }
}

