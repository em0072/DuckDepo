//
//  EditPasswordView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/11/2021.
//

import SwiftUI

struct EditPasswordView: View {
    @Environment(\.dismiss) var dismiss

    @ObservedObject var viewModel: EditPasswordViewModel
    @State var isShowingDeleteAlert: Bool = false
    @State var isShowingPassGenerator: Bool = false
    
    
    init(type: EditPasswordViewModel.PasswordType = .new, delegate: EditPasswordViewModelDelegate? = nil) {
        self.viewModel = EditPasswordViewModel()
        viewModel.type = type
        viewModel.delegate = delegate
        
    }
    
    var body: some View {
        NavigationView {
                contentView
            .onChange(of: viewModel.shouldCloseView, perform: closeAction)
            .navigationTitle(viewModel.viewTitle)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: closeButton,
                                trailing: deleteButton)
            .sheet(isPresented: $isShowingPassGenerator) {
                passGenerationView
                    .presentationDragIndicator(.visible)
                    .presentationDetents([.height(350)])
            }
            .alert("epv_delete_alert_title", isPresented: $isShowingDeleteAlert, actions: {
                Button("epv_delete_alert_delete", role: .destructive, action: deleteAlertAction)
            }, message: {
                Text("epv_delete_alert_body")
            })
            
        }
        .animation(.default, value: isShowingPassGenerator)
    }
    
    func deleteButtonAction() {
        self.isShowingDeleteAlert = true
    }
    
    func deleteAlertAction() {
        self.isShowingDeleteAlert = false
        viewModel.delete()
    }
    
    private func closeAction(_ shouldCloseView: Bool) {
        if shouldCloseView {
            dismiss()
        }
    }
    
}

extension EditPasswordView {
    
    private var contentView: some View {
        List {
            nameSection
            
            credentialsSection
            
            websiteSection
            
            AddButtonView(title: viewModel.saveButtonTitle) {
                viewModel.addNewPasswordButtonAction()
            }
            .disabled(viewModel.passwordName.isEmpty)
        }
        .listStyle(.insetGrouped)
    }
    
    private var nameSection: some View {
        Section {
            BindableFloatingTextField(title: "epv_name".localized(), value: $viewModel.passwordName)
        } header: {
            Text("epv_general_information")
        }
    }
    
    private var credentialsSection: some View {
        Section {
                VStack {
                    BindableFloatingTextField(title: "epv_login".localized(), value: $viewModel.passwordLogin)
                    
                    Divider()
                    
                    HStack {
                        BindableFloatingTextField(title: "epv_password".localized(), value: $viewModel.passwordValue)
                        
                        Button {
                            isShowingPassGenerator = true
                        } label: {
                            Image(systemName: "wand.and.stars.inverse")
                                .foregroundColor(.duckYellow)
                                .bold()
                        }
                        .buttonStyle(.plain)
                    }
                }
        } header: {
            Text("epv_credentials")
        }
    }
    
    private var websiteSection: some View {
        Section {
                VStack {
                    BindableFloatingTextField(title: "epv_website".localized(), value: $viewModel.passwordWebsite, keyboardType: .URL)
                }
        } header: {
            Text("epv_additional_information")
        }
    }
    
    private var closeButton: some View {
        CloseButton {
            dismiss()
        }
    }
    
    @ViewBuilder
    private var deleteButton: some View {
        if case .existing(_) = viewModel.type {
            Button(action: deleteButtonAction) {
                Image(systemName: "trash.fill")
            }
        }
    }
    
    private var passGenerationView: some View {
        PasswordGeneratorView(isPresented: $isShowingPassGenerator) { generatedPassword in
            viewModel.passwordValue = generatedPassword
            isShowingPassGenerator = false
        }
        .padding(.top, 20)
        .padding()
    }

}

struct EditPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        EditPasswordView(type: .existing(Password.test))
    }
}
