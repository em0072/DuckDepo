//
//  RemindersSection.swift
//  DuckDepo
//

import SwiftUI

/// Expiry reminders: on or off, and when.
struct RemindersSection: View {

    @Bindable var viewModel: SettingsViewModel
    @Environment(\.openURL) private var openURL

    var body: some View {
        Section {
            Toggle(isOn: isEnabled) {
                Label("sv_expiry_reminders", systemImage: "bell.badge.fill")
                    .labelStyle(.tile(.red))
            }
            Picker(selection: $viewModel.reminderSchedule) {
                ForEach(ReminderSchedule.allCases) { schedule in
                    Text(schedule.title).tag(schedule)
                }
            } label: {
                Label("sv_remind_me", systemImage: "calendar")
                    .labelStyle(.tile(.gray))
            }
            .pickerStyle(.menu)
            .disabled(!viewModel.areRemindersEnabled)
            if viewModel.areNotificationsBlocked {
                Button {
                    if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                        openURL(url)
                    }
                } label: {
                    Label("sv_notifications_off", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
            }
        } header: {
            Text("sv_reminders")
        } footer: {
            Text("sv_reminders_footer")
        }
    }

    private var isEnabled: Binding<Bool> {
        Binding {
            viewModel.areRemindersEnabled
        } set: { isOn in
            Task {
                await viewModel.setRemindersEnabled(isOn)
            }
        }
    }
}
