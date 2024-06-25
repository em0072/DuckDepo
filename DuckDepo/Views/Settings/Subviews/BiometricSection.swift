//
//  BiometricSection.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 12/11/2021.
//

import SwiftUI
import SFSafeSymbols

struct BiometricSection: View {
    
    @Binding var isBiometryEnabled: Bool
    @Binding var biometryDelay: BiometricController.BiometricDelay
    
    var body: some View {
        Section {
            VStack {
                if BiometricController.shared.deviceHasPasscode() {
                    BiometricToggleView(isBiometryEnabled: $isBiometryEnabled)
                    
                    Divider()
                    
                    BiometricAskAfterView(isBiometryEnabled: isBiometryEnabled, biometryDelay: $biometryDelay)
                } else {
                    Text("sv_passcode_not_set")
                        .font(.caption)
                }
            }
            .animation(.default, value: isBiometryEnabled)
        } header: {
            Text("sv_security")
        }
    }
}

private struct BiometricToggleView: View {
    
    @Binding var isBiometryEnabled: Bool
    @ScaledMetric private var size: CGFloat = 1

    var body: some View {
        Toggle(isOn: $isBiometryEnabled, label: {
            Label(biometricToggleTitle, systemSymbol: biometricToggleSymbol)
                .labelStyle(ColorfulIconLabelStyle(color: .green, size: size))
        })
        .tint(.duckYellow)
    }
    
    private var biometricToggleTitle: String {
        let type = BiometricController.shared.biometricType()
        switch type {
        case .opticId:
            return "sv_enable_opticid".localized()
        case .face:
            return "sv_enable_faceid".localized()
        case .touch:
            return "sv_enable_touchid".localized()
        default:
            return "sv_enable_passcode".localized()
        }
    }
    
    
    private var biometricToggleSymbol: SFSymbol {
        let type = BiometricController.shared.biometricType()
        switch type {
        case .opticId:
            if #available(iOS 17.0, *) {
                return SFSymbol.opticid
            } else {
                return SFSymbol.eye
            }
        case .face:
            return SFSymbol.faceid
        case .touch:
            return SFSymbol.touchid
        default:
            return SFSymbol._123Rectangle
        }
    }
}


private struct BiometricAskAfterView: View {
    
    var isBiometryEnabled: Bool
    @Binding var biometryDelay: BiometricController.BiometricDelay
    
    var body: some View {
        
        HStack {
            Picker(selection: $biometryDelay, content: {
                ForEach(BiometricController.BiometricDelay.allCases, id: \.self) { option in
                    Text(biometricDelayCasesText(option))
                }
            }, label: {
                Text("sv_ask_after")
                    .opacity(isBiometryEnabled ? 1 : 0.4)
            })
                .pickerStyle(.menu)
                .tint(.duckYellow)
        }
        .disabled(!isBiometryEnabled)
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
}

#Preview {
    
    struct PreviewWrapper: View {
        @State var value: Bool = true
        
        var body: some View {
            List {
                BiometricSection(isBiometryEnabled: $value, biometryDelay: .constant(.none))
            }
            .preferredColorScheme(.dark)
        }
    }
    
    return PreviewWrapper()
}
