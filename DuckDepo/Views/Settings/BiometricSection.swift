//
//  BiometricSection.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 12/11/2021.
//

import SwiftUI

struct BiometricSection: View {
    
    @ScaledMetric private var size: CGFloat = 1
    @Binding var isBiometryEnabled: Bool
    @Binding var biometryDelay: BiometricController.BiometricDelay
    
    var body: some View {
        Section {
            if BiometricController.shared.deviceHasPasscode() {
                Toggle(isOn: $isBiometryEnabled.animation()) {
                Label(biometricToggleTitle, systemImage: biometricToggleImage)
                    .labelStyle(ColorfulIconLabelStyle(color: .green, size: size))
            }
                if isBiometryEnabled {
                    Picker("Ask after", selection: $biometryDelay) {
                        ForEach(BiometricController.BiometricDelay.allCases, id: \.self) { option in
                            Text(biometricDelayCasesText(option))
                        }
                    }
                }
            } else {
                Text("You need to enable passcode in the phone settings to secure DuckDepo app.")
                    .font(.caption)
            }
        } header: {
            Text("Security")
        }
    }
    
    private func biometricDelayCasesText(_ delay: BiometricController.BiometricDelay) -> String {
        switch delay {
        case .none:
            return "Immediatley"
        case .fiveSeconds:
            return "After 5 seconds"
        case .fiveteenSeconds:
            return "After 15 seconds"
        case .minute:
            return "After 1 minute"
        case .fiveMinutes:
            return "After 5 minutes"
        case .fiveteenMinutes:
            return "After 15 minutes"
        }
    }
    
    private var biometricToggleTitle: String {
        let type = BiometricController.shared.biometricType()
        if case .face = type {
            return "Enable Face ID"
        } else if case .touch = type {
            return "Enable Touch ID"
        } else {
            return "Enable Passcode"
        }
    }
    
    
    private var biometricToggleImage: String {
        let type = BiometricController.shared.biometricType()
        if case .face = type {
            return "faceid"
        } else if case .touch = type {
            return "touchid"
        } else {
            return "123.rectangle"
        }
    }
}

struct BiometricSection_Previews: PreviewProvider {
    static var previews: some View {
        BiometricSection(isBiometryEnabled: .constant(true), biometryDelay: .constant(.none))
    }
}
