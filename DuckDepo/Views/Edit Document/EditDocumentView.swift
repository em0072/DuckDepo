//
//  AddNewDocumentView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 27/10/2021.
//

import SwiftUI
import ImageViewer



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


    var onDismiss: (() -> ())?
    
    init(isPresented: Binding<Bool>, type: ViewModel.DocumentType = .new, selectedFolder: String? = nil, onDismiss: (() -> ())? = nil) {
        self.viewModel = ViewModel()
        _isPresented = isPresented
        viewModel.type = type
    }
                
    var body: some View {
        NavigationView {
                    Form {
//                        NameAndFolderView(name: $viewModel.document.name, selectedFolder: $viewModel.selectedFolder, folders: $viewModel.folders)
                        NameView(name:  $viewModel.document.name)
                        PhotosSectionView(images: $viewModel.document.photos, delegate: viewModel)
                        
                        SectionView(sections: $viewModel.document.sections, options: viewModel.inputOption.sections, delegate: viewModel)

                        AddSectionMenu(menuOptions: .constant(viewModel.inputOption.listOfSectionNames()), delegate: viewModel)
                        
                        AddDocumentButton(action: viewModel.addNewDocumentButtonAction, title: viewModel.saveButtonTitle)
                            .listRowBackground(viewModel.document.name.isEmpty ? Color.duckDisabledButton : Color.duckYellow)
                            .foregroundColor(viewModel.document.name.isEmpty ? Color.duckDisabledText : Color.black)
                            .disabled(viewModel.document.name.isEmpty)
                    }
            .navigationTitle(viewModel.viewTitle)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button {
                onDismiss?()
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
        .overlay(ImageViewer(image: $viewModel.imageViewerImage, viewerShown: $viewModel.showingImageViewer))
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
        .alert("Delete confirmation", isPresented: $isShowingDeleteAlert, actions: {
            Button("Delete", role: .destructive, action: deleteAlertAction)
        }, message: {
            Text("Are you sure you want to delete this document?")
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





