//
//  SecuritySection.swift
//  DuckDepo
//

import SwiftUI

/// App lock and the clipboard.
struct SecuritySection: View {

    @Binding var isBiometryEnabled: Bool
    @Binding var biometryDelay: BiometricController.BiometricDelay
    @Binding var clipboardLifetime: ClipboardLifetime

    private let biometrics = BiometricController.shared

    var body: some View {
        Section {
            if biometrics.deviceHasPasscode() {
                Toggle(isOn: $isBiometryEnabled.animation()) {
                    Label(lockTitle, systemImage: lockSymbol)
                        .labelStyle(.tile(.green))
                }
                Picker(selection: $biometryDelay) {
                    ForEach(BiometricController.BiometricDelay.allCases, id: \.self) { delay in
                        Text(title(for: delay))
                    }
                } label: {
                    Label("sv_ask_after", systemImage: "timer")
                        .labelStyle(.tile(.gray))
                }
                .disabled(!isBiometryEnabled)
            } else {
                Label("sv_passcode_not_set", systemImage: "lock.slash.fill")
                    .labelStyle(.tile(.gray))
                    .foregroundStyle(.secondary)
            }
            Picker(selection: $clipboardLifetime) {
                ForEach(ClipboardLifetime.allCases) { lifetime in
                    Text(lifetime.title).tag(lifetime)
                }
            } label: {
                Label("sv_clipboard", systemImage: "doc.on.clipboard")
                    .labelStyle(.tile(.blue))
            }
        } header: {
            Text("sv_security")
        } footer: {
            Text("sv_clipboard_footer")
        }
        .pickerStyle(.menu)
    }

    private var lockTitle: LocalizedStringKey {
        switch biometrics.biometricType() {
        case .opticId: "sv_enable_opticid"
        case .face: "sv_enable_faceid"
        case .touch: "sv_enable_touchid"
        case .none: "sv_enable_passcode"
        }
    }

    private var lockSymbol: String {
        switch biometrics.biometricType() {
        case .opticId: "opticid"
        case .face: "faceid"
        case .touch: "touchid"
        case .none: "lock.fill"
        }
    }

    private func title(for delay: BiometricController.BiometricDelay) -> LocalizedStringKey {
        switch delay {
        case .none: "sv_immediatley"
        case .fiveSeconds: "sv_5_sec"
        case .fifteenSeconds: "sv_15_sec"
        case .minute: "sv_1_min"
        case .fiveMinutes: "sv_5_min"
        case .fifteenMinutes: "sv_15_min"
        }
    }
}

#Preview {
    @Previewable @State var isOn = true
    @Previewable @State var delay = BiometricController.BiometricDelay.none
    @Previewable @State var lifetime = ClipboardLifetime.oneMinute
    List {
        SecuritySection(isBiometryEnabled: $isOn, biometryDelay: $delay, clipboardLifetime: $lifetime)
    }
}
