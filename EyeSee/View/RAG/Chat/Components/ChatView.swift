//
//  ChatView.swift
//  EyeSee
//
//  Created by Leo Ho on 2024/5/27.
//

import SwiftHelpers
import SwiftUI

struct ChatView: View {
    
    var currentChat: Chat
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            if !currentChat.isReply {
                Image(symbols: .personCircleFill)
                    .resizable()
                    .frame(width: 40, height: 40, alignment: .center)
                    .cornerRadius(20)
            } else {
                Spacer()
            }
            
            ChatCell(contentMessage: currentChat.content,
                     isCurrentUser: currentChat.isReply)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}

#Preview {
    ChatView(currentChat: Chat.previewValue)
}
