//
//  NewPasswordsListView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 27/06/2022.
//

import SwiftUI

struct PasswordsListView: View {
        
    @StateObject var viewModel = PasswordsListViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                if !viewModel.passwords.isEmpty {
                    List(viewModel.passwords) { password in
                        NavigationLink {
                            PasswordView(password: password)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(password.name)
                                if !password.login.isEmpty {
                                    Text(password.login)
                                        .font(.caption)
                                }
                            }

                        }
                    }
                } else {
                    InitialInstructionsView(type: .passwords)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.isAddingNewPassword = true
                    }) {
                            Image(systemName: "plus")
                        }
                }
            }
            .navigationTitle("plv_title")
            .fullScreenCover(isPresented: $viewModel.isAddingNewPassword) {
                EditPasswordView(isPresented: $viewModel.isAddingNewPassword, type: .new)
            }
            NoSelectionViewView(type: .password)
        }
    }
}

struct NewPasswordsListView_Previews: PreviewProvider {
    static var previews: some View {
        PasswordsListView()
    }
}
