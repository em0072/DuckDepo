//
//  ICloudSection.swift
//  DuckDepo
//

import SwiftUI

/// Shows whether iCloud sync is working, so a silent failure doesn't look like lost data.
struct ICloudSection: View {

    @ObservedObject var monitor: SyncMonitor

    var body: some View {
        Section {
            LabeledContent {
                statusView
            } label: {
                Label("icloud_sync", systemImage: "icloud")
            }
            if let error = monitor.lastErrorDescription, monitor.accountStatus == .available {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        } header: {
            Text("icloud_section_title")
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
                Text("icloud_status_synced \(date.formatted(.relative(presentation: .named)))")
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
    List {
        ICloudSection(monitor: SyncMonitor())
    }
}
