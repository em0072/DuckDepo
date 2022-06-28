//
//  AutoFillPasswordView.swift
//  DuckDepoAutoFillExtension
//
//  Created by Evgeny Mitko on 28/06/2022.
//

import SwiftUI

struct AutoFillPasswordView: View {
    
    @StateObject var viewModel: AutoFillPasswordViewModel
        
    init(password: Password) {
        let viewModel = AutoFillPasswordViewModel(password: password)
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
                    VStack(alignment: .leading, spacing: 5) {
                        Text("pv_login")
                            .font(.caption2)
                            .foregroundColor(Color(uiColor: .systemGray))
                        Text(viewModel.password.login)
                    }
                }
                if viewModel.isPasswordExist {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("pv_password")
                                .font(.caption2)
                                .foregroundColor(Color(uiColor: .systemGray))
                            Text(viewModel.passwordValue)
                        }
                        Spacer()
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
            VStack(alignment: .leading, spacing: 5) {
                Text("pv_website")
                    .font(.caption)
                Text(viewModel.password.website)
            }
        } header: {
            Text("pv_additional_information")
        }
        }
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

struct AutoFillPasswordView_Previews: PreviewProvider {
    
    static var demoPassword: Password {
        let id = UUID()
        let pass = Password(id: id, name: "Demo Name", login: "login@login.com", value: "sTr0nG Pa$$w0rD", website: "apple.com")
        return pass
    }

    static var previews: some View {
        AutoFillPasswordView(password: AutoFillPasswordView_Previews.demoPassword)
    }
}
