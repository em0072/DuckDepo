//
//  Password.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/11/2021.
//

import SwiftUI

struct Password: Identifiable {
    
    public var id: UUID
    public var name: String = ""
    public var login: String = ""
    public var value: String = ""
    public var website: String = ""
    public var websiteURL: URL?

    
    init(id: UUID = UUID(), name: String = "", login: String = "", value: String = "", website: String = "") {
        self.id = id
        self.name = name
        self.login = login
        self.value = value
        self.website = website
        if website.starts(with: "http") {
            self.websiteURL = URL(string: website)
        } else {
            self.websiteURL = URL(string: "https://\(website)")
        }
        

    }

    
}
