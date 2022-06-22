//
//  AddNewDocumentView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 27/10/2021.
//

import SwiftUI

struct EditDocumentView: View {
    
    
    @ObservedObject var viewModel: ViewModel
    @Binding var isPresented: Bool
//    var type: ViewModel.DocumentType
    //MARK: Views States
    @State var isShowingAlert: Bool = false
    @State var isShowingDeleteAlert: Bool = false
    @State var alertTitle: String = ""
    @State var alertMessage: String = ""
    @State var showingAddNewSectionView = false
    @State var showingAddNewInfoDuplicateWarning = false
    
    init(isPresented: Binding<Bool>, type: ViewModel.DocumentType = .new) {
        self.viewModel = ViewModel()
        _isPresented = isPresented
        viewModel.type = type
    }
                
    var body: some View {
        NavigationView {
                    Form {
//                        NameAndFolderView(name: $viewModel.document.name, selectedFolder: $viewModel.selectedFolder, folders: $viewModel.folders)
                        TitleView(name:  $viewModel.document.name, description: $viewModel.document.description, documentType: $viewModel.document.documentType)
                        PhotosSectionView(images: $viewModel.document.photos, delegate: viewModel)
                        
                        SectionView(sections: $viewModel.document.sections, options: viewModel.inputOption.sections, delegate: viewModel)

                        AddSectionMenu(menuOptions: .constant(viewModel.inputOption.listOfSectionNames()), delegate: viewModel)
                        
                        AddButtonView(action: viewModel.addNewDocumentButtonAction, title: viewModel.saveButtonTitle, isActive: .constant(!viewModel.document.name.isEmpty))
                    }
            .navigationTitle(viewModel.viewTitle)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button {
                self.isPresented = false
            } label: {
                Image(systemName: "xmark")
            }, trailing:
                                    Group {
                if case .existing(_) = viewModel.type {
                    Button(action: deleteButtonAction) {
                        Image(systemName: "trash.fill")
                    }
                }
            })
        }
        .onAppear {
            viewModel.view = self
        }
        .alert(alertTitle, isPresented: $isShowingAlert, actions: {
            Button("Ok") {
                self.isShowingAlert = false
            }
        }, message: {
            Text(alertMessage)
        })
        .alert("delete_confirmation_title", isPresented: $isShowingDeleteAlert, actions: {
            Button("delete", role: .destructive, action: deleteAlertAction)
        }, message: {
            Text("delete_confirmation_body")
        })
    }
    
    func deleteButtonAction() {
        self.isShowingDeleteAlert = true
    }
    
    func deleteAlertAction() {
        self.isShowingDeleteAlert = false
        viewModel.delete()

    }
        
    func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        isShowingAlert = true
    }
    
}

struct AddNewDocumentVirew_Previews: PreviewProvider {

    static var previews: some View {
        EditDocumentView(isPresented: .constant(true), type: .new)
    }
}





