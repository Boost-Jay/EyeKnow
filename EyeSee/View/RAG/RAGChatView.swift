//
//  RAGChatView.swift
//  EyeSee
//
//  Created by Leo Ho on 2024/5/27.
//

import SwiftUI

struct RAGChatView: View {
    
    @State private var selectedIndex: Int = 0
    
    private var chatSegmentControlVM = ChatSegmentControlViewModel()
    
    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ChatSegmentControl(selectedIndex: $selectedIndex,
                                   options: chatSegmentControlVM.chatInputMethodOptions)
                .frame(maxWidth: 250)
                ChatListView(proxy: proxy)
                ChatFooterView(selectedIndex: $selectedIndex)
            }
        }
        .padding()
    }
}

#Preview {
    RAGChatView()
}
