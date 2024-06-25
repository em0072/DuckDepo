//
//  AddFolderView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/06/2024.
//

import SwiftUI

struct AddFolderView: View {
    
    @StateObject var viewModel: AddFolderViewModel

    init() {
        self._viewModel = StateObject(wrappedValue: AddFolderViewModel())
    }
    
    var body: some View {
        VStack {
            HStack {
                AddCell {
                    
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Create Folder")
                        .font(.title2)
                    Text("Folders are used to group related documents")
                        .font(.caption)
                }
                .padding()
            }
            BindableFloatingTextField(title: "Name", value: $viewModel.folderName)
                .padding(.horizontal)
        }
    }
}

#Preview {
    AddFolderView()
}
