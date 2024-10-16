//
//  CustomTabBar.swift
//  EyeSee
//
//  Created by imac-3570 on 2024/5/10.
//

import SwiftHelpers
import SwiftUI

struct CustomTabBarView: View {
    
    @Binding var selectedTab: AppDefine.Tab
    @State var tabPoints: [CGFloat] = []
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Circle()
                    .frame(width: 30, height: 30)
                    .position(x: getCurvePoint(), y: proxy.frame(in: .local).midY)
                    .foregroundStyle(Color(uiColor: UIColor.purple))
                    .blur(radius: 10.0)
                
                HStack(spacing: 0) {
                    TabBarButton(image: .yoloDetectObject,
                                 selectedTab: $selectedTab,
                                 tabPoints: $tabPoints)
                    TabBarButton(image: .perceiveEnvironment,
                                 selectedTab: $selectedTab,
                                 tabPoints: $tabPoints)
                    TabBarButton(image: .rag,
                                 selectedTab: $selectedTab,
                                 tabPoints: $tabPoints)
                    TabBarButton(image: .catchTextInPicture,
                                 selectedTab: $selectedTab,
                                 tabPoints: $tabPoints)
                }
                .padding()
                .background(
                    Color(uiColor: UIColor.white)
                        .blur(radius: 3)
                        .opacity(0.7)
                )
                .cornerRadius(30)
                .shadow(radius: 5)
                .padding(.horizontal)
                
                Rectangle()
                    .frame(width: 25, height: 5)
                    .position(x: getCurvePoint(), y: proxy.size.height + 10)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .foregroundStyle(Color(uiColor: UIColor.purple))
                    .shadow(color: Color(uiColor: UIColor.purple), radius: 10)
            }
            .background(.clear)
        }
    }
    
    func getCurvePoint() -> CGFloat {
        if tabPoints.isEmpty {
            return 10
        } else {
            switch selectedTab {
            case .yoloDetectObject:
                return tabPoints[0]
            case .perceiveEnvironment:
                return tabPoints[1]
            case .rag:
                return tabPoints[2]
            case .catchTextInPicture:
                return tabPoints[3]
            }
        }
    }
}

struct TabBarButton : View {
    
    var image: AppDefine.Tab
    @Binding var selectedTab: AppDefine.Tab
    @Binding var tabPoints: [CGFloat]
    
    var body: some View {
        GeometryReader { reader -> AnyView in
            
            let midX = reader.frame(in: .global).midX
            
            DispatchQueue.main.async {
                if tabPoints.count <= 4 {
                    if !tabPoints.contains(midX) &&
                        midX != 32.0 {
                        tabPoints.append(midX)
                    }
                }
                
                if tabPoints.count == 4 {
                    tabPoints.sort { item1, item2 in
                        if item1 < item2 {
                            return true
                        } else {
                            return false
                        }
                    }
                }
            }
            
            return AnyView(
                Button {
                    withAnimation(.smooth) {
                        selectedTab = image
                    }
                } label: {
                    if selectedTab != image {
                        Image(systemName: "\(image.symbols.rawValue)")
                            .font(.system(size: 25, weight: .semibold))
                            .foregroundStyle(Color(uiColor: UIColor.purple))
                    } else if selectedTab.symbols == .viewfinder {
                        Image(symbols: .personFillViewfinder)
                            .font(.system(size: 25, weight: .semibold))
                            .foregroundStyle(Color(uiColor: UIColor.purple))
                    } else {
                        Image(systemName: "\(image.symbols.rawValue).fill")
                            .font(.system(size: 25, weight: .semibold))
                            .foregroundStyle(Color(uiColor: UIColor.purple))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .buttonStyle(NoTapAnimationStyle())
            )
        }
        .frame(height: 30)
    }
}

struct NoTapAnimationStyle: PrimitiveButtonStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
        // Make the whole button surface tappable. Without this only content in the label is tappable and not whitespace. Order is important so add it before the tap gesture
            .contentShape(Rectangle())
            .onTapGesture(perform: configuration.trigger)
    }
}

#Preview {
    ContentView()
}
