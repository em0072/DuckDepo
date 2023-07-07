//
//  AddPhotoCell.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 28/10/2021.
//

import SwiftUI

struct AddCell: View {
    
    var action: (()->())
    
    var body: some View {
            Button {
                action()
            } label: {
                Image(systemName: "plus")
                    .font(.title)
                    .padding(20)
                    .foregroundColor(.duckYellow)
            }
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.duckYellow, lineWidth: 3)
            }
    }
}

struct AddCell_Previews: PreviewProvider {
    static var previews: some View {
        AddCell() {
            
        }
        .frame(height: 50)
    }
}
