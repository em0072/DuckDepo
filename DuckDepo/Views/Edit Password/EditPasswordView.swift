//
//  EditPasswordView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/11/2021.
//

import SwiftUI

struct EditPasswordView: View {
    
    @ObservedObject var viewModel: ViewModel
    @Binding var isPresented: Bool
    @State var isShowingDeleteAlert: Bool = false
    @State var isShowingPassGenerator: Bool = false

    
    init(isPresented: Binding<Bool>, type: ViewModel.PasswordType = .new) {
        self.viewModel = ViewModel()
        _isPresented = isPresented
        viewModel.type = type
    }

    var body: some View {
        NavigationView {
            ZStack {
        Form {
            NameSection(viewModel: viewModel)
            Section {
                BindableFloatingTextField(title: "Login", value: $viewModel.passwordLogin)
                HStack {
                    BindableFloatingTextField(title: "Password", value: $viewModel.passwordValue)
                    FormButton(action: {
                        isShowingPassGenerator = true
                    }, imageSystemName: "wand.and.stars.inverse")
                }
            } header: {
                Text("Credentials")
            }
            Section {
                BindableFloatingTextField(title: "Website", value: $viewModel.passwordWebsite, keyboardType: .URL)
            } header: {
                Text("Additional Information")
            }
            AddButtonView(action: {
                viewModel.addNewPasswordButtonAction()
                isPresented = false
            }, title: viewModel.saveButtonTitle, isActive: .constant(!viewModel.passwordName.isEmpty))
        }
//        .blur(radius: 5)

//                PasswordGeneratorView(isPresented: $isShowingPassGenerator, onAction: { generatedPassword in
//                    viewModel.passwordValue = generatedPassword
//                })
            }
            
        .navigationTitle(viewModel.viewTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(leading: Button {
            self.isPresented = false
        } label: {
            Image(systemName: "xmark")
        }, trailing:
                                Group {
            if case .existing(_) = viewModel.type {
                Button(action: deleteButtonAction) {
                    Image(systemName: "trash.fill")
                }
            }
        })
        .fullScreenCover(isPresented: $isShowingPassGenerator, content: {
            passGenerationView
                .background(BackgroundCleanerView())
        })
        .alert("Delete confirmation", isPresented: $isShowingDeleteAlert, actions: {
            Button("Delete", role: .destructive, action: deleteAlertAction)
        }, message: {
            Text("Are you sure you want to delete this password?")
        })

        }
        .overlay(isShowingPassGenerator ? Color.duckOverlay : Color.clear)
        .animation(.default, value: isShowingPassGenerator)
    }
    
    var passGenerationView: some View {
        PasswordGeneratorView(isPresented: $isShowingPassGenerator, onAction: { generatedPassword in
            viewModel.passwordValue = generatedPassword
            isShowingPassGenerator = false
        })
        
    }
    
    func deleteButtonAction() {
        self.isShowingDeleteAlert = true
    }
    
    func deleteAlertAction() {
        self.isShowingDeleteAlert = false
        viewModel.delete()
        isPresented = false
    }
    
}



struct NameSection: View {
    
    @ObservedObject var viewModel: EditPasswordView.ViewModel
    
    var body: some View {
        Section {
            BindableFloatingTextField(title: "Name", value: $viewModel.passwordName)
        } header: {
            Text("General Information")
        }
    }
}

struct EditPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        EditPasswordView(isPresented: .constant(true))
    }
}
