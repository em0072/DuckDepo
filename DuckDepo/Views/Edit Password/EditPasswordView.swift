//
//  EditPasswordView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 26/06/2022.
//

import SwiftUI

struct EditPasswordView: View {

    @Environment(\.dismiss) private var dismiss
    /// `@State`, so typed values survive the parent redrawing (e.g. when iCloud delivers changes).
    @State private var viewModel: EditPasswordViewModel
    @State private var isShowingDeleteAlert = false
    @State private var isShowingPassGenerator = false
    @State private var isShowingDiscardDialog = false
    #if !AUTOFILL_EXTENSION
    @State private var codeSetup = OneTimeCodeSetup()
    #endif

    init(type: EditPasswordViewModel.PasswordType = .new, delegate: EditPasswordViewModelDelegate? = nil) {
        _viewModel = State(initialValue: EditPasswordViewModel(type: type, delegate: delegate))
    }

    var body: some View {
        NavigationStack {
            formWithPresentations
                .onAppear(perform: viewModel.load)
                .navigationTitle(viewModel.viewTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(role: .close, action: closeButtonAction)
                            .confirmationDialog("discard_changes_title", isPresented: $isShowingDiscardDialog, titleVisibility: .visible) {
                                Button("discard_changes_button", role: .destructive) {
                                    dismiss()
                                }
                                Button("keep_editing_button", role: .cancel) {}
                            }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(role: .confirm, action: viewModel.save)
                            .disabled(!viewModel.canSave)
                    }
                }
                .sheet(isPresented: $isShowingPassGenerator) {
                    passGenerationView
                        .presentationDetents([.medium, .large])
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

    @ViewBuilder
    private var formWithPresentations: some View {
        #if AUTOFILL_EXTENSION
        form
        #else
        form.oneTimeCodeSetupPresentations(codeSetup, viewModel: viewModel)
        #endif
    }

    private var form: some View {
        Form {
            Section {
                LabeledTextField(title: "epv_name".localized(), value: $viewModel.passwordName, kind: .name)
            } header: {
                Text("epv_general_information")
            }
            Section {
                LabeledTextField(title: "epv_login".localized(), value: $viewModel.passwordLogin, kind: .login)
                HStack {
                    LabeledTextField(title: "epv_password".localized(), value: $viewModel.passwordValue, kind: .password)
                    Button {
                        isShowingPassGenerator = true
                    } label: {
                        Image(systemName: "wand.and.stars")
                            .font(.title3)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel(Text("pgv_title"))
                }
            } header: {
                Text("epv_credentials")
            }
            #if !AUTOFILL_EXTENSION
            OneTimeCodeSetupSection(viewModel: viewModel, setup: codeSetup)
            #endif
            Section {
                LabeledTextField(title: "epv_website".localized(), value: $viewModel.passwordWebsite, kind: .url)
            } header: {
                Text("epv_additional_information")
            }
            if !viewModel.isNew {
                Section {
                    Button("delete_password", role: .destructive) {
                        isShowingDeleteAlert = true
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var passGenerationView: some View {
        PasswordGeneratorView(isPresented: $isShowingPassGenerator) { generatedPassword in
            viewModel.passwordValue = generatedPassword
            isShowingPassGenerator = false
        }
    }
}

#Preview {
    EditPasswordView(type: .existing(Password.test))
}
