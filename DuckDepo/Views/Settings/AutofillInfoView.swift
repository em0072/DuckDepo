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
            VStack(spacing: 12) {
                Image("AutoFill_screenshot")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                Text("sv_autofill_feature_text1")
                Text("sv_autofill_feature_text2")
                Spacer()
            }
            .padding()
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }

                }
            })
            .navigationTitle("sv_autofill_featute")
        }
    }
}

struct AutofillInfoView_Previews: PreviewProvider {
    static var previews: some View {
        AutofillInfoView()
    }
}
