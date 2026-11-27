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
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            List {
                Section {
                    OverviewCard(documentCount: viewModel.documentCount,
                                 passwordCount: viewModel.passwordCount,
                                 renewalCount: viewModel.renewalCount)
                }
                SecuritySection(isBiometryEnabled: $biometricController.isBiometryEnabled,
                                biometryDelay: $biometricController.biometricDelay,
                                clipboardLifetime: $viewModel.clipboardLifetime)
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
        .onAppear(perform: viewModel.start)
        .task {
            await viewModel.refreshSystemState()
        }
        .onChange(of: scenePhase) { _, phase in
            // The user may have turned AutoFill or notifications on or off in Settings.
            if phase == .active {
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
