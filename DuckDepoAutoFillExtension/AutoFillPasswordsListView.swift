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
        
    var body: some View {
        NavigationStack {
            ZStack {
                if !viewModel.passwords.isEmpty {
                    listView()
                } else {
                    InitialInstructionsView(type: .passwords)
                }
            }
            .navigationTitle("af_nav_title")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    CloseButton() {
                        onClose?()
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
    
    private func listView() -> some View {
        List {
            if !viewModel.recomendedPasswords.isEmpty {
                Section  {
                    ForEach(viewModel.recomendedPasswords) { password in
                        row(for: password)
                    }
                } header: {
                    Text("af_recommended_passwords")
                }
            }
            Section  {
                ForEach(viewModel.passwords) { password in
                    row(for: password)
                }
            } header: {
                Text("af_all_passwords")
            }
        }
    }
    
    func row(for password: Password) -> some View {
        HStack {
            Button {
                onSelect?(password)
            } label: {
                PasswordRow(name: password.name, login: password.login)
            }
            
            Spacer()
            
            Button {
                viewModel.showPassword(password)
            } label: {
                Image(systemName: "info")
                    .foregroundColor(.duckYellow)
                    .bold()
            }
            .buttonStyle(.plain)
        }
    }
    
    
}

struct AutoFillPasswordsListView_Previews: PreviewProvider {
    
    static var viewModel: AutoFillPasswordsListViewModel {
        let viewModel = AutoFillPasswordsListViewModel(identifiers: [])
        viewModel.passwords = Array(repeating: Password.test, count: 2)
        return viewModel
    }
    
    static var previews: some View {
        AutoFillPasswordsListView(viewModel: viewModel, onClose: nil, onSelect: nil)
    }
}
