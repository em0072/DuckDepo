//
//  AutoFillPasswordsListView.swift
//  DuckDepoAutoFillExtension
//
//  Created by Evgeny Mitko on 28/06/2022.
//

import SwiftUI
import Combine

struct AutoFillPasswordsListView: View {
    
    @StateObject var viewModel: AutoFillPasswordsListViewModel
    var onClose: (()->())?
    var onSelect: ((Password)->())?
    
    init(identifiers: [String], onClose: (()->())?, onSelect: ((Password)->())?) {
        self._viewModel = StateObject(wrappedValue: AutoFillPasswordsListViewModel(identifiers: identifiers))
        self.onClose = onClose
        self.onSelect = onSelect
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if let password = viewModel.selectedPassword {
                    NavigationLink(isActive: $viewModel.showPasswordView) {
                        AutoFillPasswordView(password: password)
                    } label: { EmptyView() }
                }
                
                if !viewModel.passwords.isEmpty {
                    List {
                        if !viewModel.recomendedPasswords.isEmpty {
                            Section("af_recommended_passwords") {
                                ForEach(viewModel.recomendedPasswords) { password in
                                    row(for: password)
                                }
                            }
                        }
                        Section("All Passwords") {
                            ForEach(viewModel.passwords) { password in
                                row(for: password)
                            }
                        }
                    }
                } else {
                    InitialInstructionsView(type: .passwords)
                }
            }
            .navigationTitle("af_nav_title")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        onClose?()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.addNewPasswordButtonPressed()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .fullScreenCover(isPresented: $viewModel.isAddingNewPassword) {
                EditPasswordView(isPresented: $viewModel.isAddingNewPassword, type: .new)
            }

        }
    }
    
    func row(for password: Password) -> some View {
        ZStack(alignment: .leading) {
            
            Button {
                onSelect?(password)
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
        .swipeActions {
            Button {
                viewModel.showPassword(password)
            } label: {
                Image(systemName: "eye")
            }
            .tint(.blue)
        }
    }
    
}

struct AutoFillPasswordsListView_Previews: PreviewProvider {
    static var previews: some View {
        AutoFillPasswordsListView(identifiers: [String](), onClose: nil, onSelect: nil)
    }
}
