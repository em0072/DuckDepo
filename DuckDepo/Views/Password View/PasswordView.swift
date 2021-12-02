//
//  PasswordView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/11/2021.
//

import SwiftUI

struct PasswordView: View {
    
    @StateObject var viewModel = ViewModel()
    @ObservedObject var password: DDPassword
    
    @State var isPasswordVisible: Bool = false
    
    var body: some View {
        Form {
            credentialsSection
            websiteSection
        }
        .navigationBarTitle(password.name)
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
                    EditPasswordView(isPresented: $viewModel.isEditingPassword, type: .existing(password))
                }
            }
        }

    }
    
    var credentialsSection: some View {
        Section {
            if password.login.isEmpty, password.value.isEmpty {
                Text("pv_empty_credentials")
            } else {
                if !password.login.isEmpty {
                    FloatingTextView(title: "pv_login".localized(), value: password.login)
                }
                if !password.value.isEmpty {
                    HStack {
                        ZStack {
                            FloatingTextView(title: "pv_password".localized(), value: password.value, isVisible: $isPasswordVisible)
                        }
                        FormButton(action: togglePasswordVisibility, imageSystemName: isPasswordVisible ? "eye.slash" : "eye")
                    }
                }
            }
        } header: {
            Text("pv_credentials")
        }
    }
    
    @ViewBuilder var websiteSection: some View {
        if !password.website.isEmpty {
        Section {
            FloatingTextView(title: "pv_website".localized(), value: password.website, url: password.websiteURL)
        } header: {
            Text("pv_additional_information")
        }
        }
    }
    
    private func sharePassword() {
        var shareString: String = ""
        if !password.name.isEmpty {
            shareString.append("pv_share_details_title".localized())
            shareString.append(password.name)
            shareString.append("\n\n")
        }
        if !password.login.isEmpty {
            shareString.append("Login: ")
            shareString.append(password.login)
            shareString.append("\n\n")
        }
        if !password.value.isEmpty {
            shareString.append("Password: ")
            shareString.append(password.value)
            shareString.append("\n\n")
        }
        if !password.website.isEmpty {
            shareString.append("Website: ")
            shareString.append(password.website)
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
        isPasswordVisible.toggle()
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
    
    static var demoPassword: DDPassword {
        let pass = DDPassword(context: PersistenceController.shared.context)
        pass.name = "Demo Name"
        pass.login = "login@login.com"
        pass.value = "0234irnim0w9eifngm3-i0nfow"
        pass.website = "apple.com"
        return pass
    }
    
    static var previews: some View {
        NavigationView {
            PasswordView(password: demoPassword)
        }
    }
}
