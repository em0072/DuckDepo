//
//  HelpSection.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 28/06/2022.
//

import SwiftUI

struct HelpSection: View {
    
    @Binding var showAutofillInfo: Bool
    
    var body: some View {
        Section {
            Button {
                showAutofillInfo.toggle()
            } label: {
                HStack {
                    Text("sv_autofill_featute")
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .foregroundColor(.neumorphicButtonText)
            .buttonStyle(NeuRectButtonStyle())
        } header: {
            NeuSectionTitle(title: "sv_help".localized())
        }
    }
}

struct HelpSection_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            HelpSection(showAutofillInfo: .constant(false))
        }
    }
}
