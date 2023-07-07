//
//  PasswordView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/11/2021.
//

import SwiftUI

struct PasswordView: View {
    
    @Environment(\.dismiss) private var dismiss

    @StateObject var viewModel: PasswordViewModel
        
    init(password: Password) {
        let viewModel = PasswordViewModel(password: password)
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            credentialsSection

            websiteSection
        }
        .navigationBarTitle(viewModel.password.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                
                Button(action: shareAlert) {
                    Image(systemName: "square.and.arrow.up")
                }
                
                Button(action: editButtonAction) {
                    Image(systemName: "pencil")
                }
            }
            
        }
        .alert("pv_share_alert_title", isPresented: $viewModel.showShareAlert, actions: {
            Button("pv_share_alert_button", role: .destructive, action: viewModel.sharePassword)
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
        .fullScreenCover(isPresented: $viewModel.isEditingPassword) {
            EditPasswordView(type: .existing(viewModel.password), delegate: viewModel)
        }
        .onChange(of: viewModel.shouldDismissView, perform: dismissAction)
    }
                  
    private func dismissAction(_ shouldDismissView: Bool) {
        if shouldDismissView {
            dismiss()
        }
    }
    
    private func shareAlert() {
        viewModel.showShareAlert = true
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

extension PasswordView {

    private var credentialsSection: some View {
        Section {
                VStack {
                    if viewModel.shouldShowCredentialsSection {
                        loginView
                        if viewModel.isLoginExist && viewModel.isPasswordExist {
                            Divider()
                        }
                        passwordView
                    } else {
                        Text("pv_empty_credentials")
                    }
                }
        } header: {
            Text("pv_credentials")
        }
    }
    
    @ViewBuilder
    private var loginView: some View {
        if viewModel.isLoginExist {
            FloatingTextView(title: "pv_login".localized(), value: viewModel.password.login)
        }
    }

    @ViewBuilder
    private var passwordView: some View {
        if viewModel.isPasswordExist {
            HStack {
                ZStack {
                    FloatingTextView(title: "pv_password".localized(), value: viewModel.password.value, isVisible: $viewModel.isPasswordVisible)
                }
                Button(action: togglePasswordVisibility) {
                    Image(systemName: viewModel.isPasswordVisible ? "eye.slash" : "eye")
                }
                .tint(.duckYellow)
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
        private var websiteSection: some View {
        if viewModel.isWebsiteExist {
            Section {
                FloatingTextView(title: "pv_website".localized(), value: viewModel.password.website, url: viewModel.password.websiteURL)
            } header: {
                Text("pv_additional_information")
            }
        }
    }

}

struct PasswordView_Previews: PreviewProvider {
    
    static var demoPassword: Password {
        let id = UUID()
        let pass = Password(id: id, name: "Demo Name", login: "login@website.com", value: "sTr0nG Pa$$w0rD", website: "apple.com")
        return pass
    }
    
    static var previews: some View {
        NavigationStack {
            PasswordView(password: PasswordView_Previews.demoPassword)
        }
    }
}
