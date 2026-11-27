//
//  PasswordGeneratorView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/11/2021.
//

import SwiftUI

struct PasswordGeneratorView: View {

    @Binding var isPresented: Bool
    var onAction: ((String) -> Void)?

    @State private var length = 16.0
    @State private var useNumbers = true
    @State private var useCapitals = true
    @State private var useSymbols = true
    @State private var generatedPassword = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text(verbatim: generatedPassword)
                            .font(.title3.monospaced().weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .contentTransition(.numericText())
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Button(action: regenerate) {
                            Image(systemName: "arrow.clockwise")
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel(Text("pgv_regenerate"))
                    }
                }
                Section {
                    VStack(alignment: .leading) {
                        LabeledContent("pgv_num_of_symbols") {
                            Text(Int(length), format: .number)
                                .monospacedDigit()
                                .contentTransition(.numericText(value: length))
                                .animation(.snappy, value: length)
                        }
                        Slider(value: $length, in: 8...32, step: 1) {
                            Text("pgv_num_of_symbols")
                        }
                    }
                    Toggle("pgv_numbers", isOn: $useNumbers)
                    Toggle("pgv_capitals", isOn: $useCapitals)
                    Toggle("pgv_symbols", isOn: $useSymbols)
                }
            }
            .navigationTitle("pgv_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) {
                        onAction?(generatedPassword)
                    }
                    .accessibilityLabel(Text("pgv_use_button"))
                }
            }
        }
        // Not animated while the sheet comes up.
        .onAppear(perform: generatePassword)
        .onChange(of: length) { regenerate() }
        .onChange(of: useNumbers) { regenerate() }
        .onChange(of: useCapitals) { regenerate() }
        .onChange(of: useSymbols) { regenerate() }
    }

    private func regenerate() {
        withAnimation(.snappy) {
            generatePassword()
        }
    }

    private func generatePassword() {
        generatedPassword = PasswordGenerator.sharedInstance.generatePassword(includeNumbers: useNumbers,
                                                                              includeCapitals: useCapitals,
                                                                              includeSymbols: useSymbols,
                                                                              length: Int(length))
    }
}

#Preview {
    PasswordGeneratorView(isPresented: .constant(true))
}
