//
//  AddFolderViewModel.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/06/2024.
//

import Foundation
import UIKit

class AddFolderViewModel: ObservableObject {
    
    @Published var folder: Folder = Folder.empty
    @Published var images: [UIImage] = []
    @Published var folderName: String = ""
    

}
