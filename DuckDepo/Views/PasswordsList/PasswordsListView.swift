//
//  NewPasswordsListView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 27/06/2022.
//

import SwiftUI

struct PasswordsListView: View {

    @State var viewModel: PasswordsListViewModel
    private var syncMonitor = SyncMonitor.shared

    var body: some View {
        NavigationSplitView {
            Group {
                if !viewModel.passwords.isEmpty {
                    List(viewModel.passwords) { password in
                        NavigationLink(value: password) {
                            PasswordRow(name: password.name, login: password.login)
                        }
                    }
                } else if syncMonitor.showsActivity && syncMonitor.isDownloading {
                    DownloadingFromICloudView(type: .passwords)
                } else {
                    InitialInstructionsView(type: .passwords)
                }
            }
            .navigationTitle("plv_title")
            .syncActivitySubtitle(syncMonitor)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: viewModel.addNewPasswordButtonPressed) {
                        Label("epv_new_password_title", systemImage: "plus")
                    }
                }
            }
            .navigationDestination(for: Password.self) { password in
                PasswordView(password: password)
            }
            .onAppear(perform: viewModel.start)
        } detail: {
            NoSelectionViewView(type: .password)
        }
        .fullScreenCover(isPresented: $viewModel.isAddingNewPassword) {
            EditPasswordView(type: .new)
        }
    }
}

#Preview {
    PasswordsListView(viewModel: PasswordsListViewModel())
}
