//
//  ICloudSection.swift
//  DuckDepo
//

import SwiftUI

/// iCloud sync status and Password AutoFill.
struct SyncSection: View {

    let monitor: SyncMonitor
    let viewModel: SettingsViewModel

    var body: some View {
        Section {
            LabeledContent {
                statusView
            } label: {
                Label("icloud_sync", systemImage: "icloud.fill")
                    .labelStyle(.tile(.blue))
            }
            if let error = monitor.lastErrorDescription, monitor.accountStatus == .available {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
            NavigationLink {
                AutoFillView(viewModel: viewModel)
            } label: {
                LabeledContent {
                    if let isEnabled = viewModel.isAutoFillEnabled {
                        Text(isEnabled ? "sv_on" : "sv_off")
                    }
                } label: {
                    Label("sv_autofill", systemImage: "key.fill")
                        .labelStyle(.tile(.indigo))
                }
            }
        } header: {
            Text("sv_sync_autofill")
        } footer: {
            Text("icloud_keychain_footer")
        }
        .onAppear(perform: monitor.refreshAccountStatus)
    }

    @ViewBuilder
    private var statusView: some View {
        switch monitor.accountStatus {
        case .checking:
            ProgressView()
        case .available:
            if monitor.isSyncing {
                HStack(spacing: 6) {
                    ProgressView()
                    Text("icloud_status_syncing")
                }
            } else if monitor.lastErrorDescription != nil {
                Text("icloud_status_error")
                    .foregroundStyle(.red)
            } else if let date = monitor.lastSyncDate {
                Label {
                    Text("icloud_status_synced \(date.formatted(.relative(presentation: .named)))")
                } icon: {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 7))
                        .foregroundStyle(.green)
                }
            } else {
                Text("icloud_status_on")
            }
        case .noAccount:
            Text("icloud_status_no_account")
        case .restricted:
            Text("icloud_status_restricted")
        case .temporarilyUnavailable, .unknown:
            Text("icloud_status_unavailable")
        }
    }
}

#Preview {
    NavigationStack {
        List {
            SyncSection(monitor: SyncMonitor(), viewModel: SettingsViewModel())
        }
    }
}
