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
        _viewModel = StateObject(wrappedValue: PasswordViewModel(password: password))
    }

    var body: some View {
        List {
            credentialsSection
            websiteSection
        }
        .navigationTitle(viewModel.password.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    viewModel.showShareAlert = true
                } label: {
                    Label("pv_share_alert_button", systemImage: "square.and.arrow.up")
                }
                Button {
                    viewModel.isEditingPassword = true
                } label: {
                    Label("edit_button", systemImage: "pencil")
                }
            }
        }
        .alert("pv_share_alert_title", isPresented: $viewModel.showShareAlert) {
            Button("pv_share_alert_button", role: .destructive, action: viewModel.sharePassword)
        } message: {
            Text("pv_share_alert_body")
        }
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
        .onChange(of: viewModel.shouldDismissView) { _, shouldDismiss in
            if shouldDismiss {
                dismiss()
            }
        }
    }
}

extension PasswordView {

    private var credentialsSection: some View {
        Section {
            if viewModel.shouldShowCredentialsSection {
                if viewModel.isLoginExist {
                    FloatingTextView(title: "pv_login".localized(), value: viewModel.password.login)
                }
                if viewModel.isPasswordExist {
                    HStack {
                        FloatingTextView(title: "pv_password".localized(), value: viewModel.password.value,
                                         isMonospaced: true, isVisible: $viewModel.isPasswordVisible)
                        Button {
                            viewModel.isPasswordVisible.toggle()
                        } label: {
                            Image(systemName: viewModel.isPasswordVisible ? "eye.slash" : "eye")
                        }
                        .tint(.duckYellow)
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text(viewModel.isPasswordVisible ? "pv_hide_password" : "pv_show_password"))
                    }
                }
            } else {
                Text("pv_empty_credentials")
            }
        } header: {
            Text("pv_credentials")
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

#Preview {
    NavigationStack {
        PasswordView(password: Password(name: "Demo Name", login: "login@website.com", value: "sTr0nG Pa$$w0rD", website: "apple.com"))
    }
}
