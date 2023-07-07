//
//  PasswordGeneratorView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/11/2021.
//

import SwiftUI

struct PasswordGeneratorView: View {
    
    @Binding var isPresented: Bool
    @State var numberOfSymbols = 13.0
    @State var useNumbers = true
    @State var useCapitals = true
    @State var useSymbols = true
    @State var generatedPassword: String = "1232ewr@#$r"

    var onAction: ((String)->())?
    
    var body: some View {
        VStack(spacing: 10) {
            sliderView
            Divider()
            
            paramsView
            Divider()

            passView

            AddButtonView(title: "pgv_use_button".localized()) {
                onAction?(generatedPassword)
            }
            .padding()
            .background {
                Color.duckYellow
            }
            .cornerRadius(10)
        }
        .onAppear(perform: generatePassword)

    }
    
    private func generatePassword() {
        generatedPassword = PasswordGenerator.sharedInstance.generatePassword(includeNumbers: useNumbers, includeCapitals: useCapitals, includeSymbols: useSymbols, length: Int(numberOfSymbols))
    }
}

extension PasswordGeneratorView {
    private var titleView: some View {
        HStack {
            Text("pgv_title")
                .font(.title)
            Spacer()
            Button(action: {
                isPresented = false
            }, label: {
                Image(systemName: "xmark")
                    .font(.footnote)
                    .padding(7)
            })
        }
    }
    
    private var sliderView: some View {
        VStack {
            HStack {
                Text("pgv_num_of_symbols")
                Spacer()
                Text("\(Int(numberOfSymbols))")
            }
            Slider(value: $numberOfSymbols, in: 6...20, step: 1, label: {
                Text("pgv_num_of_symbols")
            }, minimumValueLabel: {
                Text("5")
            }, maximumValueLabel: {
                Text("20")
            })
            .tint(Color.duckYellow)
            .onChange(of: numberOfSymbols) { _ in
                generatePassword()
            }
        }
    }
    
    private var paramsView: some View {
        VStack {
            HStack {
                Text("pgv_params")
                Spacer()
            }
            
            HStack {
                VStack(spacing: 5) {
                    Text("123")
                    Toggle("", isOn: $useNumbers).labelsHidden()
                        .onChange(of: useNumbers) { _ in
                            generatePassword()
                        }
                }
                
                Spacer()
                VStack(spacing: 5) {
                    Text("aA")
                    Toggle("", isOn: $useCapitals).labelsHidden()
                        .onChange(of: useCapitals) { _ in
                            generatePassword()
                        }
                }
                Spacer()
                VStack(spacing: 5) {
                    Text("!@#")
                    Toggle("", isOn: $useSymbols).labelsHidden()
                        .onChange(of: useSymbols) { _ in
                            generatePassword()
                        }
                }
            }
            .tint(.duckYellow)
            .padding([ .top, .bottom], 3)
        }
    }
    
    private var passView: some View {
        VStack {
            HStack {
                Text(generatedPassword)
                    .font(.system(size: 34, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(height: 55)
                Spacer()
                
                Button(action: generatePassword) {
                    Image(systemName: "wand.and.rays.inverse")
                }
                .tint(.duckYellow)
            }
        }
    }
}

struct PasswordGeneratorView_Previews: PreviewProvider {
    static var previews: some View {
        PasswordGeneratorView(isPresented: .constant(true))
            .preferredColorScheme(.dark)
    }
}
