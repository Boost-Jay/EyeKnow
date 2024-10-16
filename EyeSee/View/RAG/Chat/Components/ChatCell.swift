//
//  ChatCell.swift
//  EyeSee
//
//  Created by Leo Ho on 2024/5/27.
//

import SwiftUI

struct ChatCell: View {
    
    let contentMessage: String
    
    let isCurrentUser: Bool
    
    var body: some View {
        Text(contentMessage)
            .padding(10)
            .foregroundColor(isCurrentUser ? .white : .black)
            .background(isCurrentUser ? .blue : Color(.white))
            .cornerRadius(10)
    }
}

#Preview {
    ChatCell(contentMessage: "This is a single message cell.",
             isCurrentUser: false)
}
