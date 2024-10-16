//
//  YoloDetectObject.swift
//  EyeSee
//
//  Created by imac-3570 on 2024/5/20.
//

import SwiftUI

struct YoloDetectObjectView: View {
    @ObservedObject var detectedObjectsModel: DetectedObjectsModel
    
    var body: some View {
        YoloDetectViewModel(detectedObjectsModel: detectedObjectsModel)
    }
}
