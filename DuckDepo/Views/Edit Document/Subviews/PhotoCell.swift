//
//  PhotoCell.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 28/10/2021.
//

import SwiftUI

struct PhotoCell: View {
    
    var image: UIImage
    
    var body: some View {
        
        ZStack {
            GeometryReader { proxy in
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width)
            }
        }
        .clipped()
        .aspectRatio(1, contentMode: .fit)
        .cornerRadius(15)
        .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color(white: 0, opacity: 0), lineWidth: 0.5)
            )
    }
}

struct PhotoCell_Previews: PreviewProvider {
    static var previews: some View {
        PhotoCell(image: UIImage(named: "duck")!)
    }
}
