//
//  YOLOHelper.swift
//  EyeSee
//
//  Created by imac-3570 on 2024/4/29.
//

import Accelerate
import CoreML
import Foundation

class YOLOHelper {
    
    // YOLO2 input is 608x608
    public static let inputWidth = 608
    public static let inputHeight = 608
    public static let maxBoundingBoxes = 3
    
    // Tweak these values to get more or fewer predictions.
    let confidenceThreshold: Float = 0.5
    let iouThreshold: Float = 0.6
    let anchors: [Float] = [0.57273, 0.677385, 1.87446, 2.06253, 3.33843, 5.47434, 7.88282, 3.52778, 9.77052, 9.16828]
    
    struct Prediction {
        let classIndex: Int
        let score: Float
        let rect: CGRect
    }
    
    let labels = [
        "人",
        "自行車",
        "汽車",
        "摩托車",
        "飛機",
        "公車",
        "火車",
        "卡車",
        "船",
        "紅綠燈",
        "消防栓",
        "停止標誌",
        "停車計時器",
        "長椅",
        "鳥",
        "貓",
        "狗",
        "馬",
        "羊",
        "牛",
        "大象",
        "熊",
        "斑馬",
        "長頸鹿",
        "背包",
        "雨傘",
        "手提包",
        "領帶",
        "行李箱",
        "飛盤",
        "滑雪板",
        "單板滑雪",
        "運動球",
        "風箏",
        "棒球棒",
        "棒球手套",
        "滑板",
        "衝浪板",
        "網球拍",
        "瓶子",
        "酒杯",
        "杯子",
        "叉子",
        "刀子",
        "湯匙",
        "碗",
        "香蕉",
        "蘋果",
        "三明治",
        "橙子",
        "青花菜",
        "胡蘿蔔",
        "熱狗",
        "披薩",
        "甜甜圈",
        "蛋糕",
        "椅子",
        "沙發",
        "盆栽",
        "床",
        "餐桌",
        "廁所",
        "電視螢幕",
        "筆記型電腦",
        "滑鼠",
        "遙控器",
        "鍵盤",
        "手機",
        "微波爐",
        "烤箱",
        "烤麵包機",
        "水槽",
        "冰箱",
        "書",
        "鐘",
        "花瓶",
        "剪刀",
        "泰迪熊",
        "吹風機",
        "牙刷"
    ]
    
    //  let model = yolo()
    //
    //  public init() { }
    
    let model: yolo
    
    public init() {
        let configuration = MLModelConfiguration()
        do {
            model = try yolo(configuration: configuration)
        } catch {
            // Handle the error appropriately. For example, you might log the error and use a fallback model.
            fatalError("Failed to load YOLO model: \(error)")
        }
    }
    
    public func predict(image: CVPixelBuffer) throws -> [Prediction] {
        if let output = try? model.prediction(input__0: image) {
            return computeBoundingBoxes(features: output.output__0)
        } else {
            return []
        }
    }
    
    public func computeBoundingBoxes(features: MLMultiArray) -> [Prediction] {
        //    assert(features.count == 125*13*13)
        assert(features.count == 425*19*19)
        
        var predictions = [Prediction]()
        
        let blockSize: Float = 32
        let gridHeight = 19
        let gridWidth = 19
        let boxesPerCell = 5;//Int(anchors.count/5)
        let numClasses = 80
        
        // The 608x608 image is divided into a 19x19 grid. Each of these grid cells
        // will predict 5 bounding boxes (boxesPerCell). A bounding box consists of
        // five data items: x, y, width, height, and a confidence score. Each grid
        // cell also predicts which class each bounding box belongs to.
        //
        // The "features" array therefore contains (numClasses + 5)*boxesPerCell
        // values for each grid cell, i.e. 425 channels. The total features array
        // contains 425x19x19 elements.
        
        // NOTE: It turns out that accessing the elements in the multi-array as
        // `features[[channel, cy, cx] as [NSNumber]].floatValue` is kinda slow.
        // It's much faster to use direct memory access to the features.
        let featurePointer = UnsafeMutablePointer<Double>(OpaquePointer(features.dataPointer))
        let channelStride = features.strides[0].intValue
        let yStride = features.strides[1].intValue
        let xStride = features.strides[2].intValue
        
        func offset(_ channel: Int, _ x: Int, _ y: Int) -> Int {
            return channel*channelStride + y*yStride + x*xStride
        }
        
        for cy in 0..<gridHeight {
            for cx in 0..<gridWidth {
                for b in 0..<boxesPerCell {
                    
                    // For the first bounding box (b=0) we have to read channels 0-24,
                    // for b=1 we have to read channels 25-49, and so on.
                    let channel = b*(numClasses + 5)
                    
                    // The slow way:
                    /*
                     let tx = features[[channel    , cy, cx] as [NSNumber]].floatValue
                     let ty = features[[channel + 1, cy, cx] as [NSNumber]].floatValue
                     let tw = features[[channel + 2, cy, cx] as [NSNumber]].floatValue
                     let th = features[[channel + 3, cy, cx] as [NSNumber]].floatValue
                     let tc = features[[channel + 4, cy, cx] as [NSNumber]].floatValue
                     */
                    
                    // The fast way:
                    let tx = Float(featurePointer[offset(channel    , cx, cy)])
                    let ty = Float(featurePointer[offset(channel + 1, cx, cy)])
                    let tw = Float(featurePointer[offset(channel + 2, cx, cy)])
                    let th = Float(featurePointer[offset(channel + 3, cx, cy)])
                    let tc = Float(featurePointer[offset(channel + 4, cx, cy)])
                    
                    // The predicted tx and ty coordinates are relative to the location
                    // of the grid cell; we use the logistic sigmoid to constrain these
                    // coordinates to the range 0 - 1. Then we add the cell coordinates
                    // (0-12) and multiply by the number of pixels per grid cell (32).
                    // Now x and y represent center of the bounding box in the original
                    // 608x608 image space.
                    let x = (Float(cx) + sigmoid(tx)) * blockSize
                    let y = (Float(cy) + sigmoid(ty)) * blockSize
                    
                    // The size of the bounding box, tw and th, is predicted relative to
                    // the size of an "anchor" box. Here we also transform the width and
                    // height into the original 416x416 image space.
                    let w = exp(tw) * anchors[2*b    ] * blockSize
                    let h = exp(th) * anchors[2*b + 1] * blockSize
                    
                    // The confidence value for the bounding box is given by tc. We use
                    // the logistic sigmoid to turn this into a percentage.
                    let confidence = sigmoid(tc)
                    
                    // Gather the predicted classes for this anchor box and softmax them,
                    // so we can interpret these numbers as percentages.
                    var classes = [Float](repeating: 0, count: numClasses)
                    for c in 0..<numClasses {
                        // The slow way:
                        //classes[c] = features[[channel + 5 + c, cy, cx] as [NSNumber]].floatValue
                        
                        // The fast way:
                        classes[c] = Float(featurePointer[offset(channel + 5 + c, cx, cy)])
                    }
                    classes = softmax(classes)
                    
                    // Find the index of the class with the largest score.
                    let (detectedClass, bestClassScore) = classes.argmax()
                    
                    // Combine the confidence score for the bounding box, which tells us
                    // how likely it is that there is an object in this box (but not what
                    // kind of object it is), with the largest class prediction, which
                    // tells us what kind of object it detected (but not where).
                    let confidenceInClass = bestClassScore * confidence
                    
                    // Since we compute 19x19x5 = 1805 bounding boxes, we only want to
                    // keep the ones whose combined score is over a certain threshold.
                    if confidenceInClass > confidenceThreshold {
                        let rect = CGRect(x: CGFloat(x - w/2), y: CGFloat(y - h/2),
                                          width: CGFloat(w), height: CGFloat(h))
                        
                        let prediction = Prediction(classIndex: detectedClass,
                                                    score: confidenceInClass,
                                                    rect: rect)
                        predictions.append(prediction)
                    }
                }
            }
        }
        
        // We already filtered out any bounding boxes that have very low scores,
        // but there still may be boxes that overlap too much with others. We'll
        // use "non-maximum suppression" to prune those duplicate bounding boxes.
        return nonMaxSuppression(boxes: predictions, limit: YOLOHelper.maxBoundingBoxes, threshold: iouThreshold)
    }
}


/**
 計算兩個邊界框之間的交集比上聯集（intersection-over-union，簡稱 IoU）重疊度。
 */
public func IOU(a: CGRect, b: CGRect) -> Float {
    let areaA = a.width * a.height
    if areaA <= 0 { return 0 }
    
    let areaB = b.width * b.height
    if areaB <= 0 { return 0 }
    
    let intersectionMinX = max(a.minX, b.minX)
    let intersectionMinY = max(a.minY, b.minY)
    let intersectionMaxX = min(a.maxX, b.maxX)
    let intersectionMaxY = min(a.maxY, b.maxY)
    let intersectionArea = max(intersectionMaxY - intersectionMinY, 0) *
    max(intersectionMaxX - intersectionMinX, 0)
    return Float(intersectionArea / (areaA + areaB - intersectionArea))
}

/// Logistic sigmoid.
public func sigmoid(_ x: Float) -> Float {
    return 1 / (1 + exp(-x))
}

/**
 計算一個陣列上的"softmax" 函數。
 
 基於 https://github.com/nikolaypavlov/MLPNeuralNet/ 的代碼。
 
 以下是使用 Python 和 numpy 的 "偽代碼"（實際代碼）中的 softmax 形式：
 
 x -= np.max(x)
 exp_scores = np.exp(x)
 softmax = exp_scores / np.sum(exp_scores)
 
 首先我們將 x 的值偏移，使得陣列中的最大值為 0。
 這樣可以確保指數的數值穩定性，避免它們的數值爆炸。
 */
public func softmax(_ x: [Float]) -> [Float] {
    var x = x
    let len = vDSP_Length(x.count)
    
    // 在 input array 中找到最大值
    var max: Float = 0
    vDSP_maxv(x, 1, &max, len)
    
    // 從陣列中的所有元素中減去最大值。
    // 現在陣列中的最高值是 0。
    max = -max
    vDSP_vsadd(x, 1, &max, &x, 1, len)
    
    // 對 Array 的所有元素進行指數運算。
    var count = Int32(x.count)
    vvexpf(&x, x, &count)
    
    // 計算所有指數化值的總和。
    var sum: Float = 0
    vDSP_sve(x, 1, &sum, len)
    
    // 將每個元素除以總和。這樣可以正規化陣列內容
    // 使它們加起來總和為 1。
    vDSP_vsdiv(x, 1, &sum, &x, 1, len)
    
    return x
}

func nonMaxSuppression(boxes: [YOLOHelper.Prediction], limit: Int, threshold: Float) -> [YOLOHelper.Prediction] {
    
    // Do an argsort on the confidence scores, from high to low.
    let sortedIndices = boxes.indices.sorted { boxes[$0].score > boxes[$1].score }
    
    var selected: [YOLOHelper.Prediction] = []
    var active = [Bool](repeating: true, count: boxes.count)
    var numActive = active.count
    
    // The algorithm is simple: Start with the box that has the highest score.
    // Remove any remaining boxes that overlap it more than the given threshold
    // amount. If there are any boxes left (i.e. these did not overlap with any
    // previous boxes), then repeat this procedure, until no more boxes remain
    // or the limit has been reached.
    outer: for i in 0..<boxes.count {
        if active[i] {
            let boxA = boxes[sortedIndices[i]]
            selected.append(boxA)
            if selected.count >= limit { break }
            
            for j in i+1..<boxes.count {
                if active[j] {
                    let boxB = boxes[sortedIndices[j]]
                    if IOU(a: boxA.rect, b: boxB.rect) > threshold {
                        active[j] = false
                        numActive -= 1
                        if numActive <= 0 { break outer }
                    }
                }
            }
        }
    }
    return selected
}
