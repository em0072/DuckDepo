//
//  PasswordsListView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 27/06/2022.
//

import SwiftUI

struct PasswordsListView: View {

    @State var viewModel: PasswordsListViewModel
    @State private var selection: Password.ID?
    @State private var passwordToDelete: Password?
    @Environment(\.openURL) private var openURL
    private var syncMonitor = SyncMonitor.shared

    init(viewModel: PasswordsListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationTitle("plv_title")
                .syncActivitySubtitle(syncMonitor)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: viewModel.addNewPasswordButtonPressed) {
                            Label("epv_new_password_title", systemImage: "plus")
                        }
                    }
                }
                .onAppear(perform: viewModel.start)
        } detail: {
            if let password = viewModel.password(with: selection) {
                PasswordView(password: password)
                    .id(password.id)
            } else {
                ContentUnavailableView("pl_no_selection_title",
                                       systemImage: "key",
                                       description: Text("no_doc_view_body_passwords"))
            }
        }
        .sheet(isPresented: $viewModel.isAddingNewPassword) {
            EditPasswordView(type: .new)
        }
        .alert("epv_delete_alert_title", isPresented: isConfirmingDelete, presenting: passwordToDelete) { password in
            Button("epv_delete_alert_delete", role: .destructive) {
                viewModel.delete(password)
            }
        } message: { _ in
            Text("epv_delete_alert_body")
        }
        .onChange(of: viewModel.passwords) { _, passwords in
            if let selection, !passwords.contains(where: { $0.id == selection }) {
                self.selection = nil
            }
        }
    }

    @ViewBuilder
    private var sidebar: some View {
        if viewModel.passwords.isEmpty {
            if syncMonitor.showsActivity && syncMonitor.isDownloading {
                DownloadingFromICloudView(type: .passwords)
            } else {
                ContentUnavailableView {
                    Label("ii_headline_passwords", systemImage: "key")
                } description: {
                    Text("ii_caption_passwords")
                } actions: {
                    Button("epv_add_new_password_button", action: viewModel.addNewPasswordButtonPressed)
                        .buttonStyle(.borderedProminent)
                        .foregroundStyle(.onDuckYellow)
                }
            }
        } else {
            listView
                .searchable(text: $viewModel.searchText, prompt: Text("pl_search_prompt"))
        }
    }

    private var listView: some View {
        List(viewModel.filteredPasswords, selection: $selection) { password in
            PasswordRow(name: password.name, login: password.login)
                .tag(password.id)
                .swipeActions(edge: .leading) {
                    Button {
                        viewModel.copyValue(of: password)
                    } label: {
                        Label("copy_password", systemImage: "key.fill")
                    }
                    .tint(.indigo)
                    if !password.login.isEmpty {
                        Button {
                            viewModel.copyLogin(of: password)
                        } label: {
                            Label("copy_login", systemImage: "person.fill")
                        }
                        .tint(.gray)
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button {
                        passwordToDelete = password
                    } label: {
                        Label("delete", systemImage: "trash")
                    }
                    .tint(.red)
                }
                .contextMenu {
                    contextMenu(for: password)
                }
        }
        .overlay {
            if viewModel.filteredPasswords.isEmpty {
                ContentUnavailableView.search(text: viewModel.searchText)
            }
        }
    }

    @ViewBuilder
    private func contextMenu(for password: Password) -> some View {
        if !password.login.isEmpty {
            Button {
                viewModel.copyLogin(of: password)
            } label: {
                Label("copy_login", systemImage: "person")
            }
        }
        Button {
            viewModel.copyValue(of: password)
        } label: {
            Label("copy_password", systemImage: "key")
        }
        if let url = password.websiteURL {
            Button {
                openURL(url)
            } label: {
                Label("dv_open_website", systemImage: "safari")
            }
        }
        Divider()
        Button(role: .destructive) {
            passwordToDelete = password
        } label: {
            Label("delete", systemImage: "trash")
        }
    }

    private var isConfirmingDelete: Binding<Bool> {
        Binding {
            passwordToDelete != nil
        } set: { isPresented in
            if !isPresented {
                passwordToDelete = nil
            }
        }
    }
}

#Preview {
    PasswordsListView(viewModel: PasswordsListViewModel())
}
