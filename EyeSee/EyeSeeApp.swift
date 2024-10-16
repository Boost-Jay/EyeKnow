//
//  EyeSeeApp.swift
//  EyeSee
//
//  Created by imac-3570 on 2024/5/9.
//

import SwiftData
import SwiftUI
import IQKeyboardManagerSwift

@main
struct EyeSeeApp: App {
    
    @State private var isActive = false
    
    init() {
       IQKeyboardManager.shared.enable = true
   }
    
    var body: some Scene {
        WindowGroup {
            if isActive {
                ContentView()
                    .modelContainer(for: [Chat.self])
            } else {
                LaunchScreenView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation {
                                isActive = true
                            }
                        }
                    }
            }
        }
    }
}

struct LaunchScreenView: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.5

    var body: some View {
        VStack {
            Image("logo", bundle: nil)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .scaleEffect(scale)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.easeIn(duration: 2.1)) {
                        scale = 2.0
                        opacity = 1.0
                    }
                }
                .padding(.bottom,60)
            Text("EyeKnow 你的另一雙眼")
                .font(.title3)
                .opacity(opacity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

