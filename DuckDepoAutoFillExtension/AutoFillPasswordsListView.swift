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
                Color.neumorphicBackground
                    .ignoresSafeArea()
                
                if let password = viewModel.selectedPassword {
                    NavigationLink(isActive: $viewModel.showPasswordView) {
                        AutoFillPasswordView(password: password)
                    } label: { EmptyView() }
                }
                
                if !viewModel.passwords.isEmpty {
                    listView()
                } else {
                    InitialInstructionsView(type: .passwords)
                }
            }
            .navigationTitle("af_nav_title")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NeuNavigationCloseButton() {
                        onClose?()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.addNewPasswordButtonPressed()
                    } label: {
                        Image(systemName: "plus")
                            .font(.footnote)
                            .padding(7)
                    }
                    .buttonStyle(NeuCircleButtonStyle())
                }
            }
            .fullScreenCover(isPresented: $viewModel.isAddingNewPassword) {
                EditPasswordView(type: .new)
            }
            
        }
    }
    
    private func listView() -> some View {
        ScrollView {
            VStack(spacing: 12) {
                Section  {
                    ForEach(viewModel.recomendedPasswords) { password in
                        row(for: password)
                    }
                } header: {
                    NeuSectionTitle(title: "af_recommended_passwords".localized())
                }
                
                FixedSpacer(16)
                Section  {
                    ForEach(viewModel.passwords) { password in
                        row(for: password)
                    }
                } header: {
                    NeuSectionTitle(title: "af_all_passwords".localized())
                }
                
            }
            .padding(16)
        }
    }
    
    func row(for password: Password) -> some View {
        HStack {
            
            Button {
                onSelect?(password)
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
                    .padding(16)
                    Spacer()
                }
            }
            .buttonStyle(NeuRectButtonStyle())
            .padding(.trailing, 8)
            
            
            Button {
                viewModel.showPassword(password)
            } label: {
                Image(systemName: "info")
                    .foregroundColor(.neumorphicButtonText)
                    .font(.footnote)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 7)
            }
            .buttonStyle(NeuCircleButtonStyle())
            
        }
    }
    
    
}

struct AutoFillPasswordsListView_Previews: PreviewProvider {
    static var previews: some View {
        AutoFillPasswordsListView(identifiers: [String](), onClose: nil, onSelect: nil)
    }
}
