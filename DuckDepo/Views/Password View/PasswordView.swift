//
//  PasswordView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/11/2021.
//

import SwiftUI

struct PasswordView: View {
    
    @StateObject var viewModel: PasswordViewModel
        
    init(password: Password) {
        let viewModel = PasswordViewModel(password: password)
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Form {
            credentialsSection
            websiteSection
        }
        .navigationBarTitle(viewModel.password.name)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: shareAlert) {
                    Image(systemName: "square.and.arrow.up")
                }
                .alert("pv_share_alert_title", isPresented: $viewModel.showShareAlert, actions: {
                    Button("pv_share_alert_button", role: .destructive, action: sharePassword)
                }, message: {
                    Text("pv_share_alert_body")
                })
                .sheet(isPresented: $viewModel.showShareSheetView, onDismiss: {
                    viewModel.itemsToShare = nil
                }) {
                    if let items = viewModel.itemsToShare {
                        ShareSheetView(items: items)
                    }
                }
                Button(action: editButtonAction) {
                    Image(systemName: "pencil")
                }
                .fullScreenCover(isPresented: $viewModel.isEditingPassword) {
                    EditPasswordView(isPresented: $viewModel.isEditingPassword, type: .existing(viewModel.password), delegate: viewModel)
                }
            }
        }

    }
    
    var credentialsSection: some View {
        Section {
            if viewModel.shouldShowCredentialsSection {
                if viewModel.isLoginExist {
                    FloatingTextView(title: "pv_login".localized(), value: viewModel.password.login)
                }
                if viewModel.isPasswordExist {
                    HStack {
                        ZStack {
                            FloatingTextView(title: "pv_password".localized(), value: viewModel.password.value, isVisible: $viewModel.isPasswordVisible)
                        }
                        FormButton(action: togglePasswordVisibility, imageSystemName: viewModel.isPasswordVisible ? "eye.slash" : "eye")
                    }
                }
            } else {
                Text("pv_empty_credentials")
            }
        } header: {
            Text("pv_credentials")
        }
    }
    
    @ViewBuilder var websiteSection: some View {
        if viewModel.isWebsiteExist {
        Section {
            FloatingTextView(title: "pv_website".localized(), value: viewModel.password.website, url: viewModel.password.websiteURL)
        } header: {
            Text("pv_additional_information")
        }
        }
    }
    
    private func sharePassword() {
        var shareString: String = ""
        if viewModel.isNameExist {
            shareString.append("pv_share_details_title".localized())
            shareString.append(viewModel.password.name)
            shareString.append("\n\n")
        }
        if viewModel.isLoginExist {
            shareString.append("Login: ")
            shareString.append(viewModel.password.login)
            shareString.append("\n\n")
        }
        if viewModel.isPasswordExist {
            shareString.append("Password: ")
            shareString.append(viewModel.password.value)
            shareString.append("\n\n")
        }
        if viewModel.isWebsiteExist {
            shareString.append("Website: ")
            shareString.append(viewModel.password.website)
            shareString.append("\n\n")
        }

        shareString.append("pv_share_caption".localized())
        shareString.append("\n")
        shareString.append("https://DuckDepo.com")
        share(items: [shareString])
    }
    
    private func shareAlert() {
        viewModel.showShareAlert = true
    }
    
    private func share(items: [Any]) {
        viewModel.itemsToShare = items
        viewModel.showShareSheetView = true
    }

    
    private func togglePasswordVisibility() {
        viewModel.isPasswordVisible.toggle()
    }
        
    private func editButtonAction() {
        viewModel.isEditingPassword = true
    }
    
    func copy(_ value: String) {
        UIPasteboard.general.string = value
        NotificationCenter.default.post(name: .floatingTextFieldCopyNotification, object: nil, userInfo: nil)
    }
}

struct PasswordView_Previews: PreviewProvider {
    
    static var demoPassword: Password {
        let id = UUID()
        let pass = Password(id: id, name: "Demo Name", login: "login@login.com", value: "sTr0nG Pa$$w0rD", website: "apple.com")
        return pass
    }
    
    static var previews: some View {
        NavigationView {
            PasswordView(password: PasswordView_Previews.demoPassword)
        }
    }
}
