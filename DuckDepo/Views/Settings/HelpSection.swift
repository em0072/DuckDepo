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
                Text("sv_autofill_featute")
            }
        } header: {
            Text("sv_help")
        }    }
}

struct HelpSection_Previews: PreviewProvider {
    static var previews: some View {
        HelpSection(showAutofillInfo: .constant(false))
    }
}
