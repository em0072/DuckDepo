//
//  PhotoCell.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 28/10/2021.
//

import SwiftUI

struct PhotoCell: View {
    
    var image: UIImage
    var action: ()->()
    
    var body: some View {
        Button {
            action()
        } label: {
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                    )
                .clipShape(RoundedRectangle(cornerRadius: 11))
                .padding(10)

        }
        .buttonStyle(NeuRectButtonStyle())
//        .buttonStyle(NeumorphicRoundedButtonStyle(cornerRadius: 15))
    }
}

struct PhotoCell_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.red)
                .frame(width: 90, height: 90)
            
        PhotoCell(image: UIImage(named: "duck")!) {
            
        }
        .frame(width: 90, height: 90)
        }

    }
}
