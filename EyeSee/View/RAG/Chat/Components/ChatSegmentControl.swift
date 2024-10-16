//
//  ChatSegmentControl.swift
//  EyeSee
//
//  Created by Leo Ho on 2024/5/27.
//

import SwiftHelpers
import SwiftUI

struct ChatSegmentControlItem: Previews {
    
    let title: LocalizedStringKey
    
    let symbols: SFSymbols
        
    static var previewValue: ChatSegmentControlItem {
        get {
            return ChatSegmentControlItem(title: "Text", symbols: .keyboard)
        }
    }
}

struct ChatSegmentControl: View {
    
    @Binding var selectedIndex: Int
    
    let options: [ChatSegmentControlItem]
    
    var body: some View {
        ZStack(alignment: .center) {
            GeometryReader { proxy in
                RoundedRectangle(cornerRadius: 6.0)
                    .foregroundColor(.blue)
                    .cornerRadius(6.0)
                    .padding(4)
                    .frame(width: proxy.size.width / CGFloat(options.count))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 1, y: 1)
                    .offset(x: proxy.size.width / CGFloat(options.count) * CGFloat(selectedIndex), y: 0)
            }
            .frame(height: 40)
            
            HStack(spacing: 0) {
                ForEach((0 ..< options.count), id: \.self) { index in
                    HStack(spacing: 6) {
                        Image(symbols: options[index].symbols)
                        Text(options[index].title)
                    }
                    .font(.system(size: 16, weight: .regular))
                    .frame(maxWidth: .infinity)
                    .background(.gray.opacity(0.00001))
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.150)) {
                            selectedIndex = index
                        }
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 6.0)
                .fill(Color.black.opacity(0.05))
        )
    }
}

/*
 Reference: https://blog.stackademic.com/custom-segment-control-in-swiftui-280e90a0f351
 */
