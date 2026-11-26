//
//  AutofillInfoView.swift
//  DuckDepo
//

import SwiftUI

/// Whether DuckDepo fills in passwords, a way to turn it on, and what it looks like.
struct AutoFillView: View {

    let viewModel: SettingsViewModel

    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    IconTile(color: .indigo, size: 56) {
                        Image(systemName: "key.fill")
                    }
                    .padding(.top, 6)
                    Text(isEnabled ? "autofill_on_title" : "autofill_off_title")
                        .font(.title3.weight(.semibold))
                    Text(isEnabled ? "autofill_on_body" : "autofill_off_body")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    if !isEnabled {
                        Button("autofill_turn_on", action: viewModel.openAutoFillSettings)
                            .buttonStyle(.borderedProminent)
                            .foregroundStyle(.onDuckYellow)
                            .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            Section {
                AutoFillIllustration()
                    .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                ForEach(Array(AutoFillStep.all.enumerated()), id: \.offset) { index, step in
                    StepRow(number: index + 1, step: step)
                }
            } header: {
                Text("autofill_how_title")
            }
        }
        .navigationTitle("sv_autofill")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.refreshSystemState()
        }
    }

    private var isEnabled: Bool {
        viewModel.isAutoFillEnabled ?? false
    }
}

private struct AutoFillStep {
    let title: LocalizedStringKey
    let body: LocalizedStringKey

    static let all = [
        AutoFillStep(title: "autofill_step_turn_on_title", body: "autofill_step_turn_on_body"),
        AutoFillStep(title: "autofill_step_suggest_title", body: "autofill_step_suggest_body"),
        AutoFillStep(title: "autofill_step_list_title", body: "autofill_step_list_body"),
        AutoFillStep(title: "autofill_step_lock_title", body: "autofill_step_lock_body"),
        AutoFillStep(title: "autofill_step_new_title", body: "autofill_step_new_body"),
    ]
}

private struct StepRow: View {

    let number: Int
    let step: AutoFillStep

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: "\(number).circle.fill")
                .font(.title2)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(step.title)
                    .font(.headline)
                Text(step.body)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

/// A sign-in form with DuckDepo's suggestion above the keyboard, drawn rather than a screenshot so it
/// follows the language, the appearance and the text size.
private struct AutoFillIllustration: View {

    var body: some View {
        VStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 10) {
                // Not `Label`: its icon spacing is too wide here.
                HStack(spacing: 4) {
                    Image(systemName: "globe")
                    Text(verbatim: "example.com")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                field(title: "pv_login", value: "jane@example.com", isFocused: false)
                field(title: "pv_password", value: nil, isFocused: true)
            }
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 14, style: .continuous))

            HStack(spacing: 10) {
                Image(systemName: "key.fill")
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 0) {
                    Text(verbatim: "jane@example.com")
                        .font(.subheadline.weight(.semibold))
                    Text("autofill_illustration_source")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Color(.secondarySystemGroupedBackground), in: .capsule)
        }
        .padding(12)
        .background(Color(.systemGroupedBackground), in: .rect(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("autofill_illustration_label"))
    }

    private func field(title: LocalizedStringKey, value: String?, isFocused: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 0) {
                if let value {
                    Text(verbatim: value)
                }
                if isFocused {
                    Capsule()
                        .fill(.tint)
                        .frame(width: 2, height: 18)
                }
                Spacer(minLength: 0)
            }
            .font(.subheadline)
            .padding(.horizontal, 10)
            .frame(height: 34)
            .background(Color(.tertiarySystemFill), in: .rect(cornerRadius: 8, style: .continuous))
            .overlay {
                if isFocused {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(.tint, lineWidth: 1.5)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AutoFillView(viewModel: SettingsViewModel())
    }
}
