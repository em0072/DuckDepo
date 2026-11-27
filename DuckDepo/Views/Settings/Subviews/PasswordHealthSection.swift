//
//  PasswordHealthSection.swift
//  DuckDepo
//

import SwiftUI

/// Password Health in Settings: the screen, whether Passwords shows it too, and the leak check.
struct PasswordHealthSection: View {

    @Bindable var monitor: PasswordHealthMonitor

    var body: some View {
        Section {
            NavigationLink {
                PasswordHealthView()
            } label: {
                PasswordHealthLabel(toFixCount: monitor.report.toFixCount, isLoaded: monitor.isLoaded)
            }
            Toggle(isOn: $monitor.showsInPasswords.animation()) {
                Label("ph_show_in_passwords", systemImage: "key.fill")
                    .labelStyle(.tile(.gray))
            }
            Toggle(isOn: $monitor.checksLeakedPasswords.animation()) {
                Label("ph_check_leaks", systemImage: "network.badge.shield.half.filled")
                    .labelStyle(.tile(.red))
            }
        } header: {
            Text("ph_title")
        } footer: {
            Text("ph_leaks_footer")
        }
    }
}
