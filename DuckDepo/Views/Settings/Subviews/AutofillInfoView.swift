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
            VStack {
                Image("AutoFill_screenshot")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(10)

                VStack(alignment: .leading, spacing: 12) {
                        Text("sv_autofill_feature_text1")
                        
                        Text("sv_autofill_feature_text2")
                    }
                .padding(.top, 16)
                Spacer()
            }
            .padding()
            .navigationTitle("sv_autofill_featute")
        }
    }
}

struct AutofillInfoView_Previews: PreviewProvider {
    static var previews: some View {
        AutofillInfoView()
    }
}
