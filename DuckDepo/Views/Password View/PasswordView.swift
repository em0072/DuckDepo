//
//  PasswordView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 27/06/2022.
//

import SwiftUI

struct PasswordView: View {

    @Environment(\.dismiss) private var dismiss
    @State var viewModel: PasswordViewModel
    /// The list's copy, to notice changes that arrive from iCloud.
    private let password: Password

    init(password: Password) {
        self.password = password
        _viewModel = State(initialValue: PasswordViewModel(password: password))
    }

    var body: some View {
        List {
            credentialsSection
            websiteSection
        }
        .navigationTitle(viewModel.password.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: viewModel.load)
        .onChange(of: password) { _, password in
            viewModel.listItemChanged(password)
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
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
        .sheet(isPresented: $viewModel.isEditingPassword) {
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
                    FieldValueRow(title: "pv_login".localized(), value: viewModel.password.login)
                }
                if viewModel.isPasswordExist {
                    FieldValueRow(title: "pv_password".localized(), value: viewModel.password.value,
                                  isSecret: true, isMonospaced: true)
                }
            } else {
                Text("pv_empty_credentials")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("pv_credentials")
        }
    }

    @ViewBuilder
    private var websiteSection: some View {
        if viewModel.isWebsiteExist {
            Section {
                FieldValueRow(title: "pv_website".localized(), value: viewModel.password.website,
                              url: viewModel.password.websiteURL)
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
