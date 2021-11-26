//
//  CoreData Countable.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/11/2021.
//

import Foundation
import CoreData

protocol CoreDataCountable {
    static func fetchRequest() -> NSFetchRequest<NSFetchRequestResult>
}
