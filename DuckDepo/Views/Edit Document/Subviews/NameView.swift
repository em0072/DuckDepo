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
        Section {
            TextField("nv_add_new_doc", text: $name, prompt: Text("nv_doc_name"))
        } header: {
            Text("nv_main_info")
        }
    }

}

struct NameView_Previews: PreviewProvider {
    static var previews: some View {
        NameView(name: .constant("nv_doc_name"))
    }
}
