//
//  AppProgressView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 27/06/2022.
//

import SwiftUI

struct AppProgressView: View {
    
    @Binding var progressValue: CGFloat
    
    var body: some View {
        VStack(alignment: .center) {
            Image("LaunchScreenDuck")
            Text("apv_sorry")
                .font(.title)
            Text("apv_duckIsBusy")
                .font(.body)
                
                .padding()
            ProgressView(value: progressValue, total: 1)
                .padding()
                .tint(.duckYellow)
        }
        .animation(.default, value: progressValue)
    
    }
}

struct AppProgressView_Previews: PreviewProvider {
    static var previews: some View {
        AppProgressView(progressValue: .constant(0.2))
    }
}
