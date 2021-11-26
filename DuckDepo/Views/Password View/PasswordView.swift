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
                .alert("Are you sure?", isPresented: $viewModel.showShareAlert, actions: {
                    Button("Share", role: .destructive, action: sharePassword)
                }, message: {
                    Text("Sharing passwords with people you don't trust is unsafe and can result in your account being hacked! Are you sure you want to share your password?")
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
                Text("Credentials Are Empty")
            } else {
                if !password.login.isEmpty {
                    FloatingTextView(title: "Login", value: password.login)
                }
                if !password.value.isEmpty {
                    HStack {
                        ZStack {
                            FloatingTextView(title: "Password", value: password.value, isVisible: $isPasswordVisible)
                        }
                        FormButton(action: togglePasswordVisibility, imageSystemName: isPasswordVisible ? "eye.slash" : "eye")
                    }
                }
            }
        } header: {
            Text("Credentials")
        }
    }
    
    @ViewBuilder var websiteSection: some View {
        if !password.website.isEmpty {
        Section {
            FloatingTextView(title: "Website", value: password.website, url: password.websiteURL)
        } header: {
            Text("Additional Information")
        }
        }
    }
    
    private func sharePassword() {
        var shareString: String = ""
        if !password.name.isEmpty {
            shareString.append("Here is details of ")
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

        shareString.append("Shared with 🦆 DuckDepo.")
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
