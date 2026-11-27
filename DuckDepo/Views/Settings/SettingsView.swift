//
//  SettingsView.swift
//  DuckDepo
//

import SwiftUI

struct SettingsView: View {

    @State private var viewModel = SettingsViewModel()
    @State private var exporter = CredentialExporter()
    @Bindable private var biometricController = BiometricController.shared
    private let syncMonitor = SyncMonitor.shared
    private let passwordHealth = PasswordHealthMonitor.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            List {
                Section {
                    OverviewCard(documentCount: viewModel.documentCount,
                                 passwordCount: viewModel.passwordCount,
                                 renewalCount: viewModel.renewalCount,
                                 toFixCount: passwordHealth.isLoaded ? passwordHealth.report.toFixCount : nil)
                }
                SecuritySection(isBiometryEnabled: $biometricController.isBiometryEnabled,
                                biometryDelay: $biometricController.biometricDelay,
                                clipboardLifetime: $viewModel.clipboardLifetime)
                PasswordHealthSection(monitor: passwordHealth)
                RemindersSection(viewModel: viewModel)
                SyncSection(monitor: syncMonitor, viewModel: viewModel)
                TransferSection(exporter: exporter)
                AboutSection(version: viewModel.version)
                DeleteAllSection(onDeleteAction: viewModel.deleteEverything)
            }
            .navigationTitle("sv_title")
        }
        .alert("export_failed_title", isPresented: isShowingExportFailure) {
            Button("OK") {}
        } message: {
            Text(exporter.failure ?? "")
        }
        .pillNotification(text: exporter.doneMessage, show: $exporter.isShowingDone)
        .onAppear {
            viewModel.start()
            passwordHealth.start()
        }
        .task {
            await viewModel.refreshSystemState()
        }
        .onChange(of: scenePhase) { _, phase in
            // The user may have turned AutoFill or notifications on or off in Settings, and a password
            // may have changed on another device (only in the keychain).
            if phase == .active {
                passwordHealth.refresh()
                Task {
                    await viewModel.refreshSystemState()
                }
            }
        }
    }

    private var isShowingExportFailure: Binding<Bool> {
        Binding { exporter.failure != nil } set: { if !$0 { exporter.failure = nil } }
    }
}

#Preview {
    SettingsView()
}
