//
//  AppDefine.swift
//  EyeSee
//
//  Created by Leo Ho on 2024/5/27.
//

import Foundation
import SwiftHelpers

struct AppDefine {
    
    enum ChatInputMethod: Identifiable, CaseIterable, RawRepresentable {
        
        case voice
        
        case text
                
        init?(rawValue: ChatSegmentControlItem) {
            switch rawValue.symbols {
            case .keyboard:
                self = .text
            case .musicMic:
                self = .voice
            default:
                fatalError("Unknown ChatInputMethod type")
            }
        }
        
        var id: Self { self }
        
        var rawValue: ChatSegmentControlItem {
            switch self {
            case .text:
                return ChatSegmentControlItem(title: "Text", symbols: .keyboard)
            case .voice:
                return ChatSegmentControlItem(title: "Voice", symbols: .musicMic)
            }
        }
    }
    
    enum Tab: Equatable {
        
        case yoloDetectObject
        
        case perceiveEnvironment
        
        case rag
        
        case catchTextInPicture
        
        var symbols: SFSymbols {
            switch self {
            case .yoloDetectObject:
                return .viewfinder
            case .perceiveEnvironment:
                return .textBelowPhoto
            case .rag:
                return .ellipsisMessage
            case .catchTextInPicture:
                return .menucard
            }
        }
        
        var title: String {
            switch self {
            case .yoloDetectObject:
                return "Yolo Detect Object"
            case .perceiveEnvironment:
                return "Perceive The Environment"
            case .rag:
                return "Use RAG via LLMs"
            case .catchTextInPicture:
                return "Catch Text in Picture"
            }
        }
    }
}
