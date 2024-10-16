//
//  ChatListView.swift
//  EyeSee
//
//  Created by Leo Ho on 2024/5/27.
//

import Combine
import SwiftData
import SwiftUI

struct ChatListView: View {
    
    let proxy: ScrollViewProxy
    
    @Query(sort: \Chat.timestamp)
    private var chats: [Chat]
    
    var body: some View {
        ScrollView {
            VStack {
                ForEach(chats, id: \.id) { chat in
                    ChatView(currentChat: chat)
                }
            }
            .onAppear {
                withAnimation {
                    proxy.scrollTo(chats.last?.id, anchor: .bottom)
                }
            }
            .onReceive(chats.publisher) { output in
                guard !output.content.isEmpty else {
                    return
                }
                proxy.scrollTo(output.id, anchor: .top)
            }
        }
    }
}
