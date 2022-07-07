//
//  AutofillInfoView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 28/06/2022.
//

import SwiftUI

struct AutofillInfoView: View {
    
    @Environment(\.dismiss) var dismiss

    
    var body: some View {
        NavigationView {
            ZStack {
                Color.neumorphicBackground
                    .ignoresSafeArea()
                
            VStack {
                Image("AutoFill_screenshot")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(10)
                    .neumorphicOuter()
                FixedSpacer(25)
                ZStack {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("sv_autofill_feature_text1")
                        
                        Text("sv_autofill_feature_text2")
                    }
                    .padding(16)
                    
                    NeuSectionBackground()
                }
                
                Spacer()
            }
            .padding()
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    NeuNavigationCloseButton() {
                        dismiss()
                    }
                }
            })
            .navigationTitle("sv_autofill_featute")
        }
        }
    }
}

struct AutofillInfoView_Previews: PreviewProvider {
    static var previews: some View {
        AutofillInfoView()
    }
}
