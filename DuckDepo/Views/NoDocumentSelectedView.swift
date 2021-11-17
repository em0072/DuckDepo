//
//  NoDocumentSelectedView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 17/11/2021.
//

import SwiftUI

struct NoDocumentSelectedView: View {
    var body: some View {
        Text("Welcome to DuckDepo!")
            .font(.title)
            .padding()
        Text("Currently, no document selected. Please select a document on the left panel.")
            .font(.body)
    }
}

struct NoDocumentSelectedView_Previews: PreviewProvider {
    static var previews: some View {
        NoDocumentSelectedView()
    }
}
