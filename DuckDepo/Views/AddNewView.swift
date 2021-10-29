//
//  AddNewFolderView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 26/10/2021.
//

import SwiftUI

struct AddNewView: View {
    
    enum DataType: String {
        case folder
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
                    AddFolderForm(folderDoesExsistAlertShown: $folderDoesExsistAlertShown, newCategoryName: $newCategoryName, type: type, addAction: addAction)
                }
            }
            .navigationTitle("New \(type.rawValue.capitalized)")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button {
                self.isPresented = false
            } label: {
                Text("Dismiss")
            })
        }
    }
}


struct AddFolderForm: View {
    
    @Binding var folderDoesExsistAlertShown: Bool
    @Binding var newCategoryName: String
    var type: AddNewView.DataType
    var addAction: ((String) -> ())?
    
    var body: some View {
        Form {
            Section {
                TextField("Add the name of a new \(type.rawValue)", text: $newCategoryName, prompt: Text("New \(type.rawValue.capitalized) Name"))
            } header: {
                Text("Enter a name for a new \(type.rawValue)")
            }
            Section {
                HStack {
                    Spacer()
                Button(action: {
                    self.addAction?(newCategoryName)
                }, label: {
                    Text("Add new \(type.rawValue)")
                })
                    .disabled(newCategoryName.isEmpty)
                    Spacer()
                }
                .foregroundColor(newCategoryName.isEmpty ? Color(white: 0.5) : Color.black)
                .listRowBackground(newCategoryName.isEmpty ? Color(white: 0.9) : Color.duckYellow)
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

