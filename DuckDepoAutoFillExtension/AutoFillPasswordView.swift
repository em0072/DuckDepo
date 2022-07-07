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
        ZStack {
            Color.neumorphicBackground
                .ignoresSafeArea()
            
            contentView()
                .padding(16)
        }
        .navigationBarTitle(viewModel.password.name)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: editButtonAction) {
                    Image(systemName: "pencil")
                        .font(.footnote)
                        .padding(7)
                }
                .buttonStyle(NeuCircleButtonStyle())
                .fullScreenCover(isPresented: $viewModel.isEditingPassword) {
                    EditPasswordView(type: .existing(viewModel.password), delegate: viewModel)
                }
            }
        }

    }
    
    private func contentView() -> some View {
        ScrollView {
            credentialsSection()
            FixedSpacer(25)
            websiteSection()
        }
    }

    
    private func credentialsSection() -> some View {
        Section {
            ZStack {
                VStack {
                    if viewModel.shouldShowCredentialsSection {
                        loginView()
                        passwordView()
                    } else {
                        Text("pv_empty_credentials")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                NeuSectionBackground()
            }
        } header: {
            NeuSectionTitle(title: "pv_credentials".localized())
        }
    }
    
    @ViewBuilder
    private func loginView() -> some View {
        if viewModel.isLoginExist {
            HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text("pv_login")
                    .font(.caption)
                Text(viewModel.password.login)
            }
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    private func passwordView() -> some View {
        if viewModel.isPasswordExist {
            Divider()
            HStack {
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("pv_password")
                        .font(.caption)
                    Text(viewModel.passwordValue)
                }
                
                Spacer()
                
                Button(action: togglePasswordVisibility) {
                    Image(systemName: viewModel.isPasswordVisible ? "eye.slash" : "eye")
                        .font(.footnote)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 5)
                }
                .buttonStyle(NeuCircleButtonStyle())
            }
        }
    }

    @ViewBuilder
    private func websiteSection() -> some View {
        if viewModel.isWebsiteExist {
            Section {
                ZStack {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("pv_website")
                                .font(.caption)
                            Text(viewModel.password.website)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        Spacer()
                    }
                    NeuSectionBackground()
                }
            } header: {
                NeuSectionTitle(title: "pv_additional_information".localized())
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
