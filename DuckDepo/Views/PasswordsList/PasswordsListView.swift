//
//  NewPasswordsListView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 27/06/2022.
//

import SwiftUI

struct PasswordsListView: View {

    @StateObject var viewModel: PasswordsListViewModel

    var body: some View {
        NavigationSplitView {
            Group {
                if viewModel.passwords.isEmpty {
                    InitialInstructionsView(type: .passwords)
                } else {
                    List(viewModel.passwords) { password in
                        NavigationLink(value: password) {
                            PasswordRow(name: password.name, login: password.login)
                        }
                    }
                }
            }
            .navigationTitle("plv_title")
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
