//
//  EditPasswordView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/11/2021.
//

import SwiftUI

struct EditPasswordView: View {
    @Environment(\.dismiss) private var dismiss

    /// `@State`, so typed values survive the parent redrawing (e.g. when iCloud delivers changes).
    @State private var viewModel: EditPasswordViewModel
    @State private var isShowingDeleteAlert = false
    @State private var isShowingPassGenerator = false
    @State private var isShowingDiscardDialog = false

    init(type: EditPasswordViewModel.PasswordType = .new, delegate: EditPasswordViewModelDelegate? = nil) {
        _viewModel = State(initialValue: EditPasswordViewModel(type: type, delegate: delegate))
    }

    var body: some View {
        NavigationStack {
            contentView
                .onAppear(perform: viewModel.load)
                .navigationTitle(viewModel.viewTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        CloseButton(action: closeButtonAction)
                            .confirmationDialog("discard_changes_title", isPresented: $isShowingDiscardDialog, titleVisibility: .visible) {
                                Button("discard_changes_button", role: .destructive) {
                                    dismiss()
                                }
                                Button("keep_editing_button", role: .cancel) {}
                            }
                    }
                    if !viewModel.isNew {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                isShowingDeleteAlert = true
                            } label: {
                                Label("epv_delete_alert_delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .sheet(isPresented: $isShowingPassGenerator) {
                    passGenerationView
                        .presentationDragIndicator(.visible)
                        .presentationDetents([.height(350)])
                }
                .alert("epv_delete_alert_title", isPresented: $isShowingDeleteAlert) {
                    Button("epv_delete_alert_delete", role: .destructive, action: viewModel.delete)
                } message: {
                    Text("epv_delete_alert_body")
                }
                .alert("save_failed_title", isPresented: $viewModel.saveFailed) {
                    Button("Ok", role: .cancel) {}
                } message: {
                    Text("save_failed_body")
                }
        }
        .interactiveDismissDisabled(viewModel.hasChanges)
        .onChange(of: viewModel.shouldCloseView) { _, shouldClose in
            if shouldClose {
                dismiss()
            }
        }
    }

    private func closeButtonAction() {
        if viewModel.hasChanges {
            isShowingDiscardDialog = true
        } else {
            dismiss()
        }
    }
}

extension EditPasswordView {

    private var contentView: some View {
        List {
            Section {
                FloatingTextField(title: "epv_name".localized(), value: $viewModel.passwordName, kind: .name)
            } header: {
                Text("epv_general_information")
            }

            Section {
                FloatingTextField(title: "epv_login".localized(), value: $viewModel.passwordLogin, kind: .login)
                HStack {
                    FloatingTextField(title: "epv_password".localized(), value: $viewModel.passwordValue, kind: .password)
                    Button {
                        isShowingPassGenerator = true
                    } label: {
                        Image(systemName: "wand.and.stars.inverse")
                            .foregroundStyle(Color.duckYellow)
                            .bold()
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("pgv_title"))
                }
            } header: {
                Text("epv_credentials")
            }

            Section {
                FloatingTextField(title: "epv_website".localized(), value: $viewModel.passwordWebsite, kind: .url)
            } header: {
                Text("epv_additional_information")
            }

            AddButtonView(title: viewModel.saveButtonTitle, action: viewModel.save)
                .disabled(!viewModel.canSave)
        }
        .listStyle(.insetGrouped)
    }

    private var passGenerationView: some View {
        PasswordGeneratorView(isPresented: $isShowingPassGenerator) { generatedPassword in
            viewModel.passwordValue = generatedPassword
            isShowingPassGenerator = false
        }
        .padding(.top, 20)
        .padding()
    }
}

#Preview {
    EditPasswordView(type: .existing(Password.test))
}
