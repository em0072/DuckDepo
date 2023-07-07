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
            ZStack {
                if viewModel.passwords.isEmpty {
                    InitialInstructionsView(type: .passwords)
                } else {
                    listView
                }
            }
            .navigationTitle("plv_title")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: viewModel.addNewPasswordButtonPressed) {
                        Image(systemName: "plus")
                    }
                }
            }
        } detail: {
            NoSelectionViewView(type: .password)
        }
        .fullScreenCover(isPresented: $viewModel.isAddingNewPassword) {
            EditPasswordView(type: .new)
        }
    }
    
}

extension PasswordsListView {
    private var listView: some View {
        List(viewModel.passwords) { password in
            NavigationLink(value: password) {
                PasswordRow(name: password.name, login: password.login)
            }
            .navigationDestination(for: Password.self) { password in
                PasswordView(password: password)
            }
        }
    }
    
    private func passwordRowView(name: String, login: String) -> some View {
        VStack(alignment: .leading) {
            Text(name)
                .foregroundColor(.primary)
            if !login.isEmpty {
                Text(login)
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .padding(.vertical, 2)
    }
}

struct NewPasswordsListView_Previews: PreviewProvider {
    static var viewModel: PasswordsListViewModel {
        let viewModel = PasswordsListViewModel()
        viewModel.passwords = Array(repeating: Password(name: "Name", login: "@login"), count: 2)
        return viewModel
    }
    
    static var previews: some View {
        PasswordsListView(viewModel: Self.viewModel)
    }
}
