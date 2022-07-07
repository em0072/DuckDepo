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
                    Color.neumorphicBackground
                        .ignoresSafeArea()

                    if !viewModel.passwords.isEmpty {
                        listView()
                    } else {
                        InitialInstructionsView(type: .passwords)
                    }
                }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.isAddingNewPassword = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.footnote)
                            .padding(7)
                    }
                    .buttonStyle(NeuCircleButtonStyle())
                }
            }
            .navigationTitle("plv_title")
            .fullScreenCover(isPresented: $viewModel.isAddingNewPassword) {
                EditPasswordView(type: .new)
            }
            NoSelectionViewView(type: .password)
        }
    }
    
    
    private func listView() -> some View {
        ScrollView {
            VStack(spacing: 6) {
                    ForEach(viewModel.passwords) { password in
                        NavigationLink(tag: password, selection: $viewModel.selectedPassword) {
                            PasswordView(password: password)
                        } label: {EmptyView()}
                        
                        Button {
                            viewModel.selectedPassword = password
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(password.name)
                                        .foregroundColor(.duckText)
                                    if !password.login.isEmpty {
                                        Text(password.login)
                                            .foregroundColor(.duckText)
                                            .font(.caption)
                                    }
                                }
                                Spacer()
                            }
                            .padding(14)
                        }
                        .buttonStyle(NeuRectButtonStyle())
                    }
                }
                .padding(16)
        }
    }
}

struct NewPasswordsListView_Previews: PreviewProvider {
    static var previews: some View {
        PasswordsListView()
    }
}
