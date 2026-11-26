//
//  SyncActivityViews.swift
//  DuckDepo
//

import SwiftUI

/// Shown instead of the empty-list instructions while iCloud is still downloading,
/// so a fresh install doesn't look like all the data is gone.
struct DownloadingFromICloudView: View {

    let type: InitialInstructionsView.ViewType

    var body: some View {
        ContentUnavailableView {
            Label("sync_downloading_title", systemImage: "icloud.and.arrow.down")
        } description: {
            Text(type == .documents ? "sync_downloading_documents" : "sync_downloading_passwords")
        } actions: {
            ProgressView()
        }
    }
}

private struct SyncActivitySubtitle: ViewModifier {

    @ObservedObject var monitor: SyncMonitor

    func body(content: Content) -> some View {
        // CloudKit reports when a sync starts and ends, not how far along it is, so there is no percentage to show.
        content.navigationSubtitle(monitor.showsActivity ? Text("sync_subtitle_syncing") : Text(verbatim: ""))
    }
}

extension View {

    /// Shows "Syncing with iCloud…" under the navigation title while a sync is running.
    func syncActivitySubtitle(_ monitor: SyncMonitor = .shared) -> some View {
        modifier(SyncActivitySubtitle(monitor: monitor))
    }
}

#Preview {
    DownloadingFromICloudView(type: .documents)
}
