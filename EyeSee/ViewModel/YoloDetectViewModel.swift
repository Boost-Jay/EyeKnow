//
//  YoloDetectViewModel.swift
//  EyeSee
//
//  Created by imac-3570 on 2024/5/20.
//

import Foundation
import SwiftUI

struct YoloDetectViewModel: UIViewControllerRepresentable {
    
    @ObservedObject var detectedObjectsModel: DetectedObjectsModel
    
    func makeUIViewController(context: Context) -> YoloDetectViewController {
        let controller = YoloDetectViewController(
            nibName: "YoloDetectViewController",
            bundle: nil
        )
        controller.detectedObjectsModel = detectedObjectsModel
        return controller
    }
    
    func updateUIViewController(_ uiViewController: YoloDetectViewController,
                                context: Context) {
        // 更新控制器（如果需要）
    }
}
