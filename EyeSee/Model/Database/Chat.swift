//
//  Chat.swift
//  EyeSee
//
//  Created by Leo Ho on 2024/5/27.
//

import Foundation
import SwiftData

@Model
class Chat: Hashable, Identifiable {
    
    @Attribute(.unique)
    var id: UUID
    
    var content: String
    
    var isReply: Bool
    
    var timestamp: Double
    
    init(content: String, isReply: Bool) {
        self.id = UUID()
        self.content = content
        self.isReply = isReply
        self.timestamp = Date().timeIntervalSince1970
    }
}

extension Chat: Previews {
    
    static var previewValue: Chat {
        get {
            return Chat(content: "This is a single message cell with avatar. If user is current user, we won't display the avatar.",
                        isReply: false)
        }
    }
}
