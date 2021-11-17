//
//  NameView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 10/11/2021.
//

import SwiftUI

struct NameView: View {
    
    @Binding var name: String
    
    var body: some View {
        Section("Main Info") {
            TextField("Add New Document", text: $name, prompt: Text("Document Name"))
        }
    }

}

struct NameView_Previews: PreviewProvider {
    static var previews: some View {
        NameView(name: .constant("Document Name"))
    }
}
