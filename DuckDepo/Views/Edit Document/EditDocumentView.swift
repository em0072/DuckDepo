//
//  AddNewDocumentView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 27/10/2021.
//

import SwiftUI

struct EditDocumentView: View {
    
    @Environment(\.dismiss) var dismiss
    
    @StateObject var viewModel: ViewModel
    
    //MARK: Views States
    @State var isShowingAlert: Bool = false
    @State var isShowingDeleteAlert: Bool = false
    @State var alertTitle: String = ""
    @State var alertMessage: String = ""
    @State var showingAddNewSectionView = false
    @State var showingAddNewInfoDuplicateWarning = false
    
    init(type: ViewModel.DocumentType = .new) {
        self._viewModel = StateObject(wrappedValue: ViewModel(type: type))
    }
    
    var body: some View {
        NavigationView {
            List {
                TitleView(name:  $viewModel.document.name, description: $viewModel.document.description, documentType: $viewModel.document.documentType)
                
                PhotosSectionView(images: $viewModel.document.photos, delegate: viewModel)
                
                SectionView(sections: $viewModel.document.sections, options: viewModel.inputOption.sections, delegate: viewModel)
                
                AddSectionMenu(menuOptions: .constant(viewModel.inputOption.listOfSectionNames()), delegate: viewModel)
                
                AddButtonView(title: viewModel.saveButtonTitle, action: viewModel.addNewDocumentButtonAction)
                    .disabled(viewModel.document.name.isEmpty)
            }
            .listStyle(.insetGrouped)
            .navigationTitle(viewModel.viewTitle)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: closeButton(),
                                trailing: deleteButton())
        }
        .onChange(of: viewModel.shouldCloseView, perform: closeAction)
        .fullScreenCover(isPresented: $viewModel.showingImageViewer, onDismiss: nil) {
            if let selctedPhoto = viewModel.imageViewerImage {
                ImageViewer(photos: viewModel.document.photos, selectedImage: selctedPhoto)
            }
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
    
    private func closeButton() -> some View {
        CloseButton() {
            dismiss()
        }
    }
    
    private func deleteButton() -> some View {
        Group {
            if case .existing(_) = viewModel.type {
                Button(action: deleteButtonAction) {
                    Image(systemName: "trash.fill")
                }
            }
        }
    }
    
    private func closeAction(_ shouldCloseView: Bool) {
        if shouldCloseView {
            dismiss()
        }
    }
    
    func deleteButtonAction() {
        self.isShowingDeleteAlert = true
    }
    
    func deleteAlertAction() {
        self.isShowingDeleteAlert = false
        viewModel.delete()
        
    }
}

struct AddNewDocumentVirew_Previews: PreviewProvider {
    
    
    static var previews: some View {
        EditDocumentView(type: .existing(Document.test))
    }
}





