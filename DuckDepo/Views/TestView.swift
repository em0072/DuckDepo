//
//  TestView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 09/11/2021.
//

import SwiftUI

struct TestView: View {
    
    @State var items = InputOption()
    
    var body: some View {
        ZStack {
            Color.red
            List(items.sections, id: \.name) { section in
                Section(section.name) {
                    ForEach(section.fields, id: \.name) { field in
                        Text(field.name)
                    }
                }
            }
        }
        .onAppear() {
            print(items.sections)
        }
    }
}

struct TestView_Previews: PreviewProvider {
    static var previews: some View {
        TestView()
    }
}
