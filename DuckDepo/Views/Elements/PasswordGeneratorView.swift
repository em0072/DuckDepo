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
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Button(action: generatePassword) {
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
        .onAppear(perform: generatePassword)
        .onChange(of: length) { generatePassword() }
        .onChange(of: useNumbers) { generatePassword() }
        .onChange(of: useCapitals) { generatePassword() }
        .onChange(of: useSymbols) { generatePassword() }
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
