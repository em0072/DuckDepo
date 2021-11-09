//
//  SettingsView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 26/10/2021.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            Form {
                CategorySection()
            }.navigationBarTitle(Text("Settings"))
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}


struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

struct CategorySection: View {
    var body: some View {
        Section {
            NavigationLink {
                EditFoldersView()
            } label: {
                Text("Edit Categories")
            }
        } header: {
            Text("Categories")
        }
    }
}
