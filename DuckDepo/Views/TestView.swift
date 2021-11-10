//
//  TestView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 09/11/2021.
//

import SwiftUI
import CloudKit

struct TestView: View {
    
    @State var shares = [CKShare]()
    
    var body: some View {
        ZStack {
            Color.red
            List(shares, id: \.url) { share in
                Text(share.description)
            }
        }
        .onAppear {
            fetch()
        }
    }
    
    func fetch() {
        let sh = try? PersistenceController.shared.container.fetchShares(in: nil)
        shares = sh ?? []
    }
}

struct TestView_Previews: PreviewProvider {
    static var previews: some View {
        TestView()
    }
}
