//
//  PerceiveEnvironmentViewModel.swift
//  EyeSee
//
//  Created by imac-3570 on 2024/5/20.
//

import SwiftUI
import AVFoundation
import Speech

struct PerceiveEnvironmentViewModel: UIViewControllerRepresentable {
    
    typealias UIViewControllerType = UIViewController
    private let networkManager = NetworkManager.shared
    
    // Camera
    let cameraManager: CameraManager
    let didFinishProcessingPhoto: (Result<AVCapturePhoto, Error>) -> ()
    
    // Speech
    let speechManager: SpeechManager
    let speechIsAvailable: (Bool) -> ()
    
    func makeUIViewController(context: Context) -> UIViewController {
        
        cameraManager.start(delegate: context.coordinator) { error in
            if let error = error {
                didFinishProcessingPhoto(.failure(error))
                return
            }
        }
        
        let viewController = UIViewController()
        viewController.view.backgroundColor = .black
        viewController.view.layer.addSublayer(cameraManager.previewLayer)
        cameraManager.previewLayer.frame = viewController.view.bounds
        return viewController
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self,
                    didFinishProcessingPhoto: didFinishProcessingPhoto,
                    speechIsAvailable: speechIsAvailable)
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        //
    }
}

class Coordinator: NSObject {
    
    let parent: PerceiveEnvironmentViewModel
    
    private var didFinishProcessingPhoto: (Result<AVCapturePhoto, Error>) -> ()
    
    private var speechIsAvailable: (Bool) -> ()
    
    init(_ parent: PerceiveEnvironmentViewModel,
         didFinishProcessingPhoto: @escaping (Result<AVCapturePhoto, Error>) -> (),
         speechIsAvailable: @escaping (Bool) -> ()) {
        self.parent = parent
        self.didFinishProcessingPhoto = didFinishProcessingPhoto
        self.speechIsAvailable = speechIsAvailable
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension Coordinator: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        AudioServicesDisposeSystemSoundID(1108)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        AudioServicesDisposeSystemSoundID(1108)
    }
    
    
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        if let error = error {
            didFinishProcessingPhoto(.failure(error))
            return
        }
        didFinishProcessingPhoto(.success(photo))
    }
}

// MARK: - SFSpeechRecognizerDelegate

extension Coordinator: SFSpeechRecognizerDelegate{
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer,
                          availabilityDidChange available: Bool) {
        if available {
            speechIsAvailable(false)
        } else {
            speechIsAvailable(true)
        }
    }
}
