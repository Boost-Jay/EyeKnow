//
//  CameraManager.swift
//  EyeSee
//
//  Created by imac-3570 on 2024/3/23.
//

import AVFoundation
import Vision
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

class CameraManager: ObservableObject {
    
    var session: AVCaptureSession?
    
    var delegate: AVCapturePhotoCaptureDelegate?
    
    let output = AVCapturePhotoOutput()
    
    let previewLayer = AVCaptureVideoPreviewLayer()
    
    let networkManager = NetworkManager.shared
    
    var documentDetectionRequest = VNDetectRectanglesRequest()

    func start(delegate: AVCapturePhotoCaptureDelegate,
               completion: @escaping (Error?) -> ()) {
        self.delegate = delegate
        checkPermissions(completion: completion)
        
        // 設置文檔檢測參數
        setupDocumentDetection()
    }
    
    func stop() {
        DispatchQueue.global(qos: .background).async {
            self.session?.stopRunning()
        }
    }

    private func setupDocumentDetection() {
        // 設置 Vision 的矩形檢測
        documentDetectionRequest.minimumAspectRatio = 0.5
        documentDetectionRequest.maximumObservations = 1 // 我們只需要一個文檔
    }
    
    private func checkPermissions(completion: @escaping (Error?) -> ()) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard granted else { return }
                DispatchQueue.main.async {
                    self?.setupCamera(completion: completion)
                }
            }
        case .restricted, .denied:
            // 處理權限被拒絕的情況
            completion(NSError(domain: "Camera", code: -1, userInfo: [NSLocalizedDescriptionKey: "Camera access denied"]))
        case .authorized:
            setupCamera(completion: completion)
        @unknown default:
            break
        }
    }
    
    private func processImage(_ image: UIImage) -> UIImage {
        guard let ciImage = CIImage(image: image) else {
            return image
        }
        
        // 使用 CIColorControls 濾鏡來調整對比度
        let filter = CIFilter.colorControls()
        filter.inputImage = ciImage
        filter.contrast = 2.0 // 調整對比度來強化圖片中的文字
        
        guard let outputImage = filter.outputImage else {
            return image
        }
        
        let context = CIContext()
        if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        
        return image
    }

    
    private func setupCamera(completion: @escaping (Error?) -> ()) {
        let session = AVCaptureSession()
        if let device = AVCaptureDevice.default(for: .video) {
            do {
                let input = try AVCaptureDeviceInput(device: device)
                if session.canAddInput(input) {
                    session.addInput(input)
                }
                
                if session.canAddOutput(output) {
                    session.addOutput(output)
                }
                
                previewLayer.videoGravity = .resizeAspectFill
                previewLayer.session = session
                
                DispatchQueue.global(qos: .background).async {
                    session.startRunning()
                }
               
                self.session = session
                
            } catch {
                completion(error)
            }
        }
    }
    
    func capturePhoto(with settings: AVCapturePhotoSettings = AVCapturePhotoSettings()) {
        guard let delegate = delegate else {
            print("Error: delegate is nil")
            return
        }
        output.capturePhoto(with: settings, delegate: delegate)
    }
    
    func capturePhoto(with settings: AVCapturePhotoSettings = AVCapturePhotoSettings(), completion: @escaping (UIImage) -> Void) {
        guard let delegate = delegate else {
            print("Error: delegate is nil")
            return
        }
        output.capturePhoto(with: settings, delegate: delegate)
        }

    
    // 添加文檔檢測功能
    func detectDocument(in image: UIImage, completion: @escaping (UIImage?) -> ()) {
        guard let ciImage = CIImage(image: image) else {
            completion(nil)
            return
        }

        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        
        do {
            try handler.perform([documentDetectionRequest])
            if let result = documentDetectionRequest.results?.first as? VNRectangleObservation {
                let correctedImage = self.correctImagePerspective(for: ciImage, with: result)
                completion(correctedImage)
            } else {
                completion(nil)
            }
        } catch {
            print("文檔檢測失敗: \(error)")
            completion(nil)
        }
    }
    
    // 透視校正功能
    private func correctImagePerspective(for image: CIImage, with observation: VNRectangleObservation) -> UIImage? {
        let correctedImage = image.applyingFilter("CIPerspectiveCorrection", parameters: [
            "inputTopLeft": CIVector(cgPoint: observation.topLeft),
            "inputTopRight": CIVector(cgPoint: observation.topRight),
            "inputBottomLeft": CIVector(cgPoint: observation.bottomLeft),
            "inputBottomRight": CIVector(cgPoint: observation.bottomRight)
        ])
        
        let context = CIContext()
        if let cgImage = context.createCGImage(correctedImage, from: correctedImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        return nil
    }
}


//MARK: - CallAPI

extension CameraManager {
    
    func callAPIToChatGPTV4(question: String,
                            imageBase64Str: String) async throws -> ChatGPT4VisionResponse {
        
        let content1 = Content(type: "text", text: question)
        let imageUrl = ImageUrl(url: "data:image/jpeg;base64,\(imageBase64Str)", detail: "low")
        let content2 = Content(type: "image_url", image_url: imageUrl)
        let totalContent = [content1, content2]
        
        let message = RequestMessages(role: "user", content: totalContent)
        
        let request = ChatGPT4VisionRequest(model: "gpt-4o",
                                            messages: [message],
                                            maxTokens: 800)
        
        do {
            let response: ChatGPT4VisionResponse = try await networkManager.requestData(method: .post,
                                                                                        server: .openai,
                                                                                        path: .chatGPT,
                                                                                        parameters: request)
            return response
        } catch {
            throw error
        }
    }
}
