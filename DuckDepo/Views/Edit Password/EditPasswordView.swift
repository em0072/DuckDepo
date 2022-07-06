//
//  EditPasswordView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/11/2021.
//

import SwiftUI

struct EditPasswordView: View {
    
    @ObservedObject var viewModel: ViewModel
    @Binding var isPresented: Bool
    @State var isShowingDeleteAlert: Bool = false
    @State var isShowingPassGenerator: Bool = false
    
    
    init(isPresented: Binding<Bool>, type: ViewModel.PasswordType = .new, delegate: EditPasswordViewModelDelegate? = nil) {
        self.viewModel = ViewModel()
        _isPresented = isPresented
        viewModel.type = type
        viewModel.delegate = delegate
        
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Form {
                    NameSection(viewModel: viewModel)
                    Section {
                        BindableFloatingTextField(title: "epv_login".localized(), value: $viewModel.passwordLogin)
                        HStack {
                            BindableFloatingTextField(title: "epv_password".localized(), value: $viewModel.passwordValue)
                            FormButton(action: {
                                isShowingPassGenerator = true
                            }, imageSystemName: "wand.and.stars.inverse")
                        }
                    } header: {
                        Text("epv_credentials")
                    }
                    Section {
                        BindableFloatingTextField(title: "epv_website".localized(), value: $viewModel.passwordWebsite, keyboardType: .URL)
                    } header: {
                        Text("epv_additional_information")
                    }
                    AddButtonView(title: viewModel.saveButtonTitle) {
                        viewModel.addNewPasswordButtonAction()
                        isPresented = false
                    }
                    .disabled(!viewModel.passwordName.isEmpty)
                }
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
            .fullScreenCover(isPresented: $isShowingPassGenerator, content: {
                passGenerationView
                    .background(BackgroundCleanerView())
            })
            .alert("epv_delete_alert_title", isPresented: $isShowingDeleteAlert, actions: {
                Button("epv_delete_alert_delete", role: .destructive, action: deleteAlertAction)
            }, message: {
                Text("epv_delete_alert_body")
            })
            
        }
        .overlay(isShowingPassGenerator ? Color.duckOverlay : Color.clear)
        .animation(.default, value: isShowingPassGenerator)
    }
    
    var passGenerationView: some View {
        PasswordGeneratorView(isPresented: $isShowingPassGenerator, onAction: { generatedPassword in
            viewModel.passwordValue = generatedPassword
            isShowingPassGenerator = false
        })
        
    }
    
    func deleteButtonAction() {
        self.isShowingDeleteAlert = true
    }
    
    func deleteAlertAction() {
        self.isShowingDeleteAlert = false
        viewModel.delete()
        isPresented = false
    }
    
}



struct NameSection: View {
    
    @ObservedObject var viewModel: EditPasswordView.ViewModel
    
    var body: some View {
        Section {
            BindableFloatingTextField(title: "epv_name".localized(), value: $viewModel.passwordName)
        } header: {
            Text("epv_general_information")
        }
    }
}

struct EditPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        EditPasswordView(isPresented: .constant(true))
    }
}
