//
//  AutoFillPasswordsListView.swift
//  DuckDepoAutoFillExtension
//
//  Created by Evgeny Mitko on 28/06/2022.
//

import AuthenticationServices
import SwiftUI

struct AutoFillPasswordsListView: View {

    @State var viewModel: AutoFillPasswordsListViewModel
    var onClose: (() -> Void)?
    var onSelect: ((ASPasswordCredential) -> Void)?
    /// In one-time code mode, called with the code to fill in.
    var onSelectCode: ((String) -> Void)?

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("af_nav_title")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(role: .close) {
                            onClose?()
                        }
                    }
                    if viewModel.isStoreReady && !viewModel.isLocked && viewModel.mode == .passwords {
                        ToolbarItem(placement: .primaryAction) {
                            Button {
                                viewModel.addNewPasswordButtonPressed()
                            } label: {
                                Label("epv_new_password_title", systemImage: "plus")
                            }
                        }
                    }
                }
                .sheet(isPresented: $viewModel.isAddingNewPassword) {
                    EditPasswordView(type: .new)
                }
                .sheet(item: $viewModel.selectedPassword) { password in
                    NavigationStack {
                        PasswordView(password: password)
                    }
                    .presentationDragIndicator(.visible)
                }
        }
        .tint(.duckYellow)
    }

    @ViewBuilder
    private var content: some View {
        if !viewModel.isStoreReady {
            AutoFillMessageView(title: "af_open_app_title", message: "af_open_app_body", systemImage: "arrow.up.forward.app")
        } else if viewModel.isLocked {
            AutoFillUnlockView(onUnlock: viewModel.unlock)
                .task {
                    viewModel.unlock()
                }
        } else if viewModel.passwords.isEmpty {
            if viewModel.mode == .oneTimeCodes {
                ContentUnavailableView("af_no_codes_title", systemImage: "number",
                                       description: Text("af_no_codes_body"))
            } else {
                ContentUnavailableView {
                    Label("ii_headline_passwords", systemImage: "key")
                } description: {
                    Text("ii_caption_passwords")
                }
            }
        } else {
            listView
                .searchable(text: $viewModel.searchText)
        }
    }

    private var listView: some View {
        List {
            if !viewModel.recommendedPasswords.isEmpty && viewModel.searchText.isEmpty {
                Section {
                    ForEach(viewModel.recommendedPasswords) { password in
                        row(for: password)
                    }
                } header: {
                    Text("af_recommended_passwords")
                }
            }
            Section {
                ForEach(viewModel.filteredPasswords) { password in
                    row(for: password)
                }
            } header: {
                Text("af_all_passwords")
            }
        }
    }

    private func row(for password: Password) -> some View {
        HStack {
            Button {
                if viewModel.mode == .oneTimeCodes, let code = viewModel.oneTimeCodes[password.id] {
                    onSelectCode?(code.code())
                } else {
                    onSelect?(viewModel.credential(for: password))
                }
            } label: {
                HStack {
                    PasswordRow(name: password.name, login: password.login)
                    if let code = viewModel.oneTimeCodes[password.id] {
                        Spacer()
                        OneTimeCodeText(code: code)
                    }
                }
            }
            Spacer()
            Button {
                viewModel.showPassword(password)
            } label: {
                Image(systemName: "info.circle")
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(Text("af_show_details"))
        }
    }
}

/// Shown while the extension waits for the user to authenticate.
struct AutoFillUnlockView: View {
    let onUnlock: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text("lock_title")
                .font(.title3.bold())
            Button("lock_unlock_passcode", action: onUnlock)
                .buttonStyle(.borderedProminent)
                .tint(.duckYellow)
                .foregroundStyle(.onDuckYellow)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct AutoFillMessageView: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let systemImage: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.largeTitle)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    AutoFillPasswordsListView(viewModel: AutoFillPasswordsListViewModel(identifiers: [], isStoreReady: false))
}
