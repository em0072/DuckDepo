//
//  FixedSpacer.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 04/07/2022.
//

import SwiftUI

struct FixedSpacer: View {
    
    let amount: CGFloat
    
    init(_ amount: CGFloat) {
        self.amount = amount
    }
    
    var body: some View {
        Spacer()
            .frame(width: amount, height: amount)
    }
}

struct FixedSpacer_Previews: PreviewProvider {
    static var previews: some View {
        FixedSpacer(15)
    }
}
