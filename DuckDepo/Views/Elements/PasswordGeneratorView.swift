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
//        ZStack {
//            Color.clear
//                .blur(radius: 5)
        VStack {
            Spacer()
                .opacity(0)
        VStack {
            title
            slider
            params
            passView
            Divider()
            
            Button {
                onAction?(generatedPassword)
            } label: {
                Text("Use Password")
            }
            .buttonStyle(DuckButtonStyle())
            .clipShape(Capsule())

        }
        .padding()
        .background(Color.background)
        .cornerRadius(20)
        .padding(30)
        .shadow(color: .duckShadow, radius: 5, x: 0, y: 0)
        .onAppear(perform: generatePassword)
            Spacer()
                .opacity(0)
        }
//        }
//        .ignoresSafeArea()


        
    }
    
    @ViewBuilder var title: some View {
        HStack {
            Text("Password Generation")
                .font(.title)
            Spacer()
            Button(action: {
                isPresented = false
            }, label: {
                Image(systemName: "xmark")
            })
                .font(.headline)
        }
        Divider()
    }
    
    @ViewBuilder var slider: some View {
        HStack {
            Text("Number of symbols:")
            Spacer()
            Text("\(Int(numberOfSymbols))")
        }
        Slider(value: $numberOfSymbols, in: 6...20, step: 1, label: {
            Text("Number of symbols")
        }, minimumValueLabel: {
            Text("5")
        }, maximumValueLabel: {
            Text("20")
        })
        .accentColor(Color.duckYellow)
        .onChange(of: numberOfSymbols) { _ in
            generatePassword()
        }
        Divider()
    }
    
    @ViewBuilder var params: some View {
        HStack {
        Text("Parameters:")
            Spacer()
        }
        HStack {
            VStack(spacing: 5) {
                Text("123")
            Toggle("123", isOn: $useNumbers).labelsHidden()
                    .tint(Color.duckYellow)
                    .onChange(of: useNumbers) { _ in
                        generatePassword()
                    }
            }
            Spacer()
            VStack(spacing: 5) {
                Text("aA")
            Toggle("aA", isOn: $useCapitals).labelsHidden()
                    .tint(Color.duckYellow)
                    .onChange(of: useCapitals) { _ in
                        generatePassword()
                    }
            }
            Spacer()
            VStack(spacing: 5) {
                Text("!@#")
            Toggle("!@#", isOn: $useSymbols).labelsHidden()
                    .tint(Color.duckYellow)
                    .onChange(of: useSymbols) { _ in
                        generatePassword()
                    }
            }
        }
        .padding([ .top, .bottom], 3)
        Divider()
    }
    
    @ViewBuilder var passView: some View {
        HStack {
        Text(generatedPassword)
            .font(.system(size: 34, weight: .bold))
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .frame(height: 55)
            Spacer()
            FormButton(action: generatePassword, imageSystemName: "wand.and.rays.inverse")
        }
    }
    
    private func generatePassword() {
        generatedPassword = PasswordGenerator.sharedInstance.generatePassword(includeNumbers: useNumbers, includeCapitals: useCapitals, includeSymbols: useSymbols, length: Int(numberOfSymbols))
        
    }
}

struct PasswordGeneratorView_Previews: PreviewProvider {
    static var previews: some View {
        PasswordGeneratorView(isPresented: .constant(true))
    }
}
