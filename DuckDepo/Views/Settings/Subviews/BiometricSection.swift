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
                VStack {
                    if BiometricController.shared.deviceHasPasscode() {
                        HStack {
                            Label(biometricToggleTitle, systemImage: biometricToggleImage)
                                .labelStyle(ColorfulIconLabelStyle(color: .green, size: size))

                            Toggle("", isOn: $isBiometryEnabled)
                                .tint(.duckYellow)
                        }
                        
                        VStack {
                            Divider()
                            HStack {
                                Text("sv_ask_after")
                                    .opacity(isBiometryEnabled ? 1 : 0.4)
                                
                                ZStack {
                                    Picker("", selection: $biometryDelay) {
                                        ForEach(BiometricController.BiometricDelay.allCases, id: \.self) { option in
                                            Text(biometricDelayCasesText(option))
                                        }
                                    }
                                    .pickerStyle(.menu)
                                }
                            }
                            .disabled(!isBiometryEnabled)
                        }
                    } else {
                        Text("sv_passcode_not_set")
                            .font(.caption)
                    }
                }
        } header: {
            Text("sv_security")
        }
    }
    
    private func biometricDelayCasesText(_ delay: BiometricController.BiometricDelay) -> String {
        switch delay {
        case .none:
            return "sv_immediatley".localized()
        case .fiveSeconds:
            return "sv_5_sec".localized()
        case .fiveteenSeconds:
            return "sv_15_sec".localized()
        case .minute:
            return "sv_1_min".localized()
        case .fiveMinutes:
            return "sv_5_min".localized()
        case .fiveteenMinutes:
            return "sv_15_min".localized()
        }
    }
    
    private var biometricToggleTitle: String {
        let type = BiometricController.shared.biometricType()
        if case .face = type {
            return "sv_enable_faceid".localized()
        } else if case .touch = type {
            return "sv_enable_touchid".localized()
        } else {
            return "sv_enable_passcode".localized()
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
        List {
            BiometricSection(isBiometryEnabled: .constant(true), biometryDelay: .constant(.none))
        }
        .preferredColorScheme(.dark)
    }
}
