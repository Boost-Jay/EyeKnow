//
//  DetectedObjectsModel.swift
//  EyeSee
//
//  Created by imac on 2024/9/22.
//

import Combine
import Foundation

class DetectedObjectsModel: ObservableObject {
    @Published var detectedObjects: [DetectedObject] = []
}

struct DetectedObject {
    let name: String
    let distance: Float
    let timestamp: Date
}
