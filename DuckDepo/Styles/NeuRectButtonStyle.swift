//
//  NeuRectButtonStyle.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 05/07/2022.
//

import SwiftUI


struct NeuRectButtonStyle: ButtonStyle {
        
    func makeBody(configuration: Configuration) -> some View {
//        GeometryReader { proxy in
        ZStack {
            if !configuration.isPressed {
                Image("RectButton")
//                    .resizable()
//                    .aspectRatio(contentMode: .fit)
//                    .layoutPriority(-1)
            }
            configuration.label
//                .background(RoundedRectangle(cornerRadius: 7).fill(Color.red))
//                    .padding(18)
//                    .padding(.horizontal, proxy.size.width * 0.0185)
//                    .padding(.vertical, proxy.size.height * 0.011)
//                .padding(32)
            if configuration.isPressed {
                Image("RectButtonPressed")
//                    .resizable()
//                    .aspectRatio(contentMode: .fit)
//                    .layoutPriority(-1)
            }
        }
//        }
    }
    
}



struct NeuRectButtonStyle_Preview: PreviewProvider {
        
    static var previews: some View {
        ZStack {
            Color.neumorphicBackground
                .ignoresSafeArea()
            Button {
                
            } label: {
                VStack {
                Text("++++====")
                    .font(.title)
                    Text("++++===")
                        .font(.title)
                    Text("++++===")
                        .font(.title)

                }
            }
//            .frame(width: 150, height: 150)
            .buttonStyle(NeuRectButtonStyle())
        }
        
        
    }
}
