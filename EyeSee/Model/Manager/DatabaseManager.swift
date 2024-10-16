//
//  DatabaseManager.swift
//  EyeSee
//
//  Created by Leo Ho on 2024/5/27.
//

import Foundation
import SwiftData

final class DatabaseManager: NSObject {
    
    static let shared = DatabaseManager()
    
    func save<T>(context: ModelContext, model: T) throws where T: PersistentModel {
        context.insert(model)
    }
    
    func deleteAll<T>(context: ModelContext, model: T) throws where T: PersistentModel {
        context.delete(model)
    }
}
