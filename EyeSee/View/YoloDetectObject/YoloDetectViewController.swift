//
//  YoloDetectViewController.swift
//  EyeSee
//
//  Created by imac-3570 on 2024/5/20.
//

import ARKit
import UIKit
import Vision
import AVFoundation

class YoloDetectViewController: UIViewController {
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var arscnv: ARSCNView!
    
    // MARK: - Variables
    
    var boundingBoxes = [BoundingBox]()
    
    var detectedObjectsModel: DetectedObjectsModel?
    
    // 定義計時器
    var detectionTimer: Timer?
    
    var detectionStatus = false
    
    var request: VNCoreMLRequest?
    
    let requestQueue = DispatchQueue(label: "Request Queue")
    
    var frameCount = 0
    
    var shouldYoloDetection: Bool {
        // True every ten frames.
        frameCount % 10 == 0
    }
    
    var isTapProcessing = false
    
    var startTimes: [CFTimeInterval] = []
    
    var resizedPixelBuffers: [CVPixelBuffer?] = []
    
    let drawBoundingBoxes = true
    
    var inflightBuffer = 0
    
    let yolo = YOLOHelper()
        
    // 允許同時進行的最大預測數量
    static let maxInflightBuffers = 3
    
    let semaphore = DispatchSemaphore(value: maxInflightBuffers)
    
    var framesDone = 0
    
    var frameCapturingStartTime = CACurrentMediaTime()
    
    var colors: [UIColor] = []
    
    var requests = [VNCoreMLRequest]()
    
    let synth = AVSpeechSynthesizer()
    
    // MARK: - LifeCycle
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupARSNView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpBoundingBoxes()
        setUpCoreImage()
        setUpVision()
        
        // 啟動檢測計時器
        startDetectionTimer()
        setupUI()
        synth.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAR()
    }
    
    // MARK: - UI Settings
    
    func setupUI() {
        setupARSNView()
    }
    
    func setupARSNView() {
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        arscnv.delegate = self
        
        for box in self.boundingBoxes {
            box.addToLayer(self.arscnv.layer)
        }
        
        let tapGesture = UITapGestureRecognizer(target: self,
                                                action: #selector(tapPredictItem))
        arscnv.addGestureRecognizer(tapGesture)
        
        arscnv.session.run(config)
    }
    
    func stopAR() {
        arscnv.session.pause()
    }
    
    func setUpBoundingBoxes() {
        for _ in 0..<YOLOHelper.maxBoundingBoxes {
            boundingBoxes.append(BoundingBox())
        }
        
        // 為每個邊界框設置顏色。
        for r: CGFloat in [0.2, 0.4, 0.6, 0.85, 1.0] {
          for g: CGFloat in [0.6, 0.7, 0.8, 0.9] {
            for b: CGFloat in [0.6, 0.7, 0.8, 1.0] {
              let color = UIColor(red: r, green: g, blue: b, alpha: 1)
              colors.append(color)
            }
          }
        }
    }
    
    func setUpCoreImage() {
        // 創建用於調整大小的像素緩衝區
        for _ in 0 ..< YoloDetectViewController.maxInflightBuffers {
            var resizedPixelBuffer: CVPixelBuffer?
            let status = CVPixelBufferCreate(nil, YOLOHelper.inputWidth, YOLOHelper.inputHeight,
                                             kCVPixelFormatType_32BGRA, nil,
                                             &resizedPixelBuffer)
            
            if status != kCVReturnSuccess {
                print("Error: could not create resized pixel buffer", status)
            }
            resizedPixelBuffers.append(resizedPixelBuffer)
        }
    }
    
    func setUpVision() {
        guard let modelURL = Bundle.main.url(forResource: "yolo",
                                             withExtension: "mlmodelc") else {
            print("找不到模型")
            return
        }
        
        do {
            for _ in 0 ..< YoloDetectViewController.maxInflightBuffers {
                let visionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
                request = VNCoreMLRequest(model: visionModel, completionHandler: visionRequestDidComplete)
                request!.imageCropAndScaleOption = .scaleFill
                requests.append(request!)
            }
        } catch {
            print("Model loading went wrong: \(error)")
        }
    }
    
    // 啟動檢測計時器
    func startDetectionTimer() {
        
        detectionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self = self else { return }
//            // 移除所有 3D 節點
            for childNode in self.arscnv.scene.rootNode.childNodes {
                childNode.removeFromParentNode()
            }
          
            self.detectionStatus = true
        }
    }
    
    func detectObject(in pixelBuffer: CVPixelBuffer, inflightIndex: Int) {
        
        startTimes.append(CACurrentMediaTime())
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                                   orientation: .right)
        let request = requests[inflightIndex]
        
        DispatchQueue.global().async {
            try? requestHandler.perform([request])
        }
    }
    
    func visionRequestDidComplete(request: VNRequest, error: Error?) {
        
        if let observations = request.results as? [VNCoreMLFeatureValueObservation],
           let features = observations.first?.featureValue.multiArrayValue {

            let boundingBoxes = yolo.computeBoundingBoxes(features: features)
          let elapsed = CACurrentMediaTime() - startTimes.remove(at: 0)
          showOnMainThread(boundingBoxes, elapsed)
        }
    }
    
    func measureFPS() -> Double {
        // 計算實際每秒傳遞的幀數
        framesDone += 1
        let frameCapturingElapsed = CACurrentMediaTime() - frameCapturingStartTime
        let currentFPSDelivered = Double(framesDone) / frameCapturingElapsed
        if frameCapturingElapsed > 1 {
            framesDone = 0
            frameCapturingStartTime = CACurrentMediaTime()
        }
        return currentFPSDelivered
    }
    
    func showOnMainThread(_ predictions: [YOLOHelper.Prediction], _ elapsed: CFTimeInterval) {
        if drawBoundingBoxes {
            DispatchQueue.main.async {
                self.show(predictions: predictions)
                
                _ = self.measureFPS()
                self.semaphore.signal()
            }
        }
    }
    
    func show(predictions: [YOLOHelper.Prediction]) {
        for i in 0..<boundingBoxes.count {
            if i < predictions.count {
                let prediction = predictions[i]

                // The predicted bounding box is in the coordinate space of the input
                // image, which is a square image of 416x416 pixels. We want to show it
                // on the video preview, which is as wide as the screen and has a 4:3
                // aspect ratio. The video preview also may be letterboxed at the top
                // and bottom.
                let width = view.bounds.width
                let height = width * 4 / 3
                let scaleX = width / CGFloat(YOLOHelper.inputWidth)
                let scaleY = height / CGFloat(YOLOHelper.inputHeight)
                let top = (view.bounds.height - height) / 2

                // Translate and scale the rectangle to our own coordinate system.
                var rect = prediction.rect
                rect.origin.x *= scaleX
                rect.origin.y *= scaleY
                rect.origin.y += top
                rect.size.width *= scaleX
                rect.size.height *= scaleY

                // Show the bounding box.
                let label = String(format: "%@", YOLOHelper().labels[prediction.classIndex])
                
                let color = colors[prediction.classIndex]
                boundingBoxes[i].show(frame: rect, label: label, color: color)
                addBoundingBox(rect: rect, predictItem: label, color: color)
            } else {
                boundingBoxes[i].hide()
            }
        }
    }
    
    func addBoundingBox(rect: CGRect, predictItem: String, color: UIColor) {
        guard let raycastQuery = arscnv.raycastQuery(from: CGPoint(x: rect.midX, y: rect.midY),
                                                     allowing: .estimatedPlane,
                                                     alignment: .any),
        let result = arscnv.session.raycast(raycastQuery).first else {
            print("Raycast failed for rect: \(rect)")
            return
        }
        
        guard let cameraPositionVector = arscnv.session.currentFrame?.camera.transform.columns.3 else { return }
        let cameraPosition = SCNVector3(x: cameraPositionVector.x,
                                        y: cameraPositionVector.y,
                                        z: cameraPositionVector.z)
        
        let position = simd_make_float3(result.worldTransform.columns.3)
        
        let distanceVector = SCNVector3(x: cameraPosition.x - position.x,
                                        y: cameraPosition.y - position.y,
                                        z: cameraPosition.z - position.z)
        
        let distanceFloat = distanceVector.length
        
        let box = SCNBox(width: rect.width, height: rect.height, length: 0.005, chamferRadius: 0)
        box.firstMaterial?.diffuse.contents = UIColor.clear
        
        let boxNode = SCNNode(geometry: box)
        boxNode.name = "\(predictItem)"  // 設置物件名稱，便於點擊時檢測
        boxNode.position = SCNVector3(x: position.x, y: position.y, z: position.z)
        
        arscnv.scene.rootNode.addChildNode(boxNode)  // 添加球體及文字
        
        print("Added sphere bounding box for \(predictItem) at position \(position)")
        
        if let detectedObjectsModel = detectedObjectsModel {
            let detectedObject = DetectedObject(name: predictItem,
                                                distance: distanceFloat,
                                                timestamp: Date())
            DispatchQueue.main.async {
                detectedObjectsModel.detectedObjects.append(detectedObject)
                // 保留最近 2 秒内的物体
                detectedObjectsModel.detectedObjects = detectedObjectsModel.detectedObjects.filter {
                    Date().timeIntervalSince($0.timestamp) <= 2
                }
            }
        }
    }
    
    // MARK: - IBAction
    
    @objc func tapPredictItem(_ recognizer: UITapGestureRecognizer)  {
        
        if(isTapProcessing == true) {
            return
        }
        
        let location = recognizer.location(in: arscnv)
        print("Tap location: \(location)")
        
        let hitTestResult = arscnv.hitTest(location, options: nil)
        print("Hit test results: \(hitTestResult)")
        
        if let node = hitTestResult.first?.node, let nodeName = node.name {
            print("Tapped node: \(nodeName)")
            
            guard let cameraPositionVector = arscnv.session.currentFrame?.camera.transform.columns.3 else {
                print("Camera position not available")
                return
            }
            
            let cameraPosition = SCNVector3(x: cameraPositionVector.x, y: cameraPositionVector.y, z: cameraPositionVector.z)
            let distanceSCN3 = node.position - cameraPosition
            let distanceFloat = distanceSCN3.length
            let roundedDistance = Int(round(distanceFloat * 100)) // 四捨五入並轉換為整數
            
            // 將物件名稱轉換為中文
            let translatedObject =  nodeName
            print("Translated object: \(translatedObject)")
            
            // 配置音頻會話
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("Failed to set up audio session: \(error)")
            }
            
            // 使用語音合成朗讀距離和名稱
            let speechUtterance = AVSpeechUtterance(string: "距離 \(translatedObject) 還有 \(roundedDistance) 公分")
            speechUtterance.voice = AVSpeechSynthesisVoice(language: "zh-TW") // 設置語言為中文
            speechUtterance.rate = 0.5 // 語速調整
            synth.speak(speechUtterance)
            isTapProcessing = true
            print("距離 \(translatedObject) 還有 \(roundedDistance) 公分")
        } else {
            print("No node tapped or node name not set")
        }
    }
}

// MARK: - Extension

extension YoloDetectViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let pixelBuffer = self.arscnv.session.currentFrame?.capturedImage else {
            return
        }
        
        if detectionStatus == true {
            semaphore.wait()
            
            let inflightIndex = inflightBuffer
            inflightBuffer += 1
            if inflightBuffer >= YoloDetectViewController.maxInflightBuffers {
                inflightBuffer = 0
            }
            self.detectObject(in: pixelBuffer, inflightIndex: inflightIndex)
            detectionStatus = false
        }
    }
}

extension simd_float3 {
    func length() -> Float {
        return sqrtf(x * x + y * y + z * z)
    }
}

extension SCNVector3 {
    
    static func -(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3(left.x - right.x, left.y - right.y, left.z - right.z)
    }
    
    // 向量的模
    var length: Float {
        return sqrt(x * x + y * y + z * z)
    }
}

extension YoloDetectViewController: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isTapProcessing = false
        print("是否開啟", isTapProcessing)
    }
}
