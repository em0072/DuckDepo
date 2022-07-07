//
//  EditPasswordView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/11/2021.
//

import SwiftUI

struct EditPasswordView: View {
    @Environment(\.dismiss) var dismiss

    @ObservedObject var viewModel: ViewModel
    @State var isShowingDeleteAlert: Bool = false
    @State var isShowingPassGenerator: Bool = false
    
    
    init(type: ViewModel.PasswordType = .new, delegate: EditPasswordViewModelDelegate? = nil) {
        self.viewModel = ViewModel()
        viewModel.type = type
        viewModel.delegate = delegate
        
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.neumorphicBackground
                    .ignoresSafeArea()
                
                contentView()
            }
            .onChange(of: viewModel.shouldCloseView, perform: closeAction)
            .navigationTitle(viewModel.viewTitle)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: closeButton(),
                                trailing: deleteButton())
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
        .overlay(isShowingPassGenerator ? Color.neumorphicBackground.opacity(0.8) : Color.clear)
        .animation(.default, value: isShowingPassGenerator)
    }
    
    private func contentView() -> some View {
        ScrollView {
            VStack {
                nameSection()
                FixedSpacer(25)
                credentialsSection()
                FixedSpacer(25)
                websiteSection()
                FixedSpacer(25)
                AddButtonView(title: viewModel.saveButtonTitle) {
                    viewModel.addNewPasswordButtonAction()
                }
                .disabled(viewModel.passwordName.isEmpty)
            }
            .padding(16)
        }
        
    }
    
    private func nameSection() -> some View {
        Section {
            ZStack {
                BindableFloatingTextField(title: "epv_name".localized(), value: $viewModel.passwordName)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                NeuSectionBackground()
            }
        } header: {
            NeuSectionTitle(title: "epv_general_information".localized())
        }
    }
    
    private func credentialsSection() -> some View {
        Section {
            ZStack {
                VStack {
                    BindableFloatingTextField(title: "epv_login".localized(), value: $viewModel.passwordLogin)
                    Divider()
                    HStack {
                        BindableFloatingTextField(title: "epv_password".localized(), value: $viewModel.passwordValue)
                        FormButton(action: {
                            isShowingPassGenerator = true
                        }, imageSystemName: "wand.and.stars.inverse")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                NeuSectionBackground()
            }
        } header: {
            NeuSectionTitle(title: "epv_credentials".localized())
        }
    }
    
    private func websiteSection() -> some View {
        Section {
            ZStack {
                VStack {
                    BindableFloatingTextField(title: "epv_website".localized(), value: $viewModel.passwordWebsite, keyboardType: .URL)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                NeuSectionBackground()
            }
        } header: {
            NeuSectionTitle(title: "epv_additional_information".localized())
        }
    }
    
    var passGenerationView: some View {
        PasswordGeneratorView(isPresented: $isShowingPassGenerator, onAction: { generatedPassword in
            viewModel.passwordValue = generatedPassword
            isShowingPassGenerator = false
        })
        
    }
    
    private func closeButton() -> some View {
        NeuNavigationCloseButton() {
            dismiss()
        }
    }
    
    private func deleteButton() -> some View {
        Group {
            if case .existing(_) = viewModel.type {
                Button(action: deleteButtonAction) {
                    Image(systemName: "trash.fill")
                        .font(.footnote)
                        .padding(6)
                }
                .buttonStyle(NeuCircleButtonStyle())
            }
        }
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



//struct NameSection: View {
//
//    @ObservedObject var viewModel: EditPasswordView.ViewModel
//
//    var body: some View {
//
//    }
//}

struct EditPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        EditPasswordView(type: .existing(Password.test))
    }
}
