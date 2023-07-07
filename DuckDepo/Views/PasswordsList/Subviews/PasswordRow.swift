//
//  PasswordRow.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 07/07/2023.
//

import SwiftUI

struct PasswordRow: View {
    
    let name: String
    let login: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(name)
                .foregroundColor(.primary)
            if !login.isEmpty {
                Text(login)
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .padding(.vertical, 2)
    }
    
}

struct PasswordRow_Previews: PreviewProvider {
    static var previews: some View {
        PasswordRow(name: "Name", login: "login")
    }
}
