//
//  VNDocumentCameraViewControllerRepresentable.swift
//  EyeSee
//
//  Created by imac on 2024/9/11.
//

import SwiftUI
import VisionKit

struct VNDocumentCameraViewControllerRepresentable: UIViewControllerRepresentable {
    @Binding var scanResult: [UIImage]
    var onComplete: ([UIImage]) -> Void // 新增這個閉包，用來回調

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let documentCameraViewController = VNDocumentCameraViewController()
        documentCameraViewController.delegate = context.coordinator
        return documentCameraViewController
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(scanResult: $scanResult, onComplete: onComplete) // 將 onComplete 傳遞到 Coordinator
    }

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        @Binding var scanResult: [UIImage]
        var onComplete: ([UIImage]) -> Void // 儲存 onComplete 閉包

        init(scanResult: Binding<[UIImage]>, onComplete: @escaping ([UIImage]) -> Void) {
            _scanResult = scanResult
            self.onComplete = onComplete
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            controller.dismiss(animated: true, completion: nil)
            
            // 將所有掃描結果（可能有多頁）加入 scanResult
            scanResult = (0..<scan.pageCount).compactMap { scan.imageOfPage(at: $0) }
            
            // 呼叫 onComplete 並將掃描結果傳遞出去
            onComplete(scanResult)
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true, completion: nil)
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            print("Document scanner error: \(error.localizedDescription)")
            controller.dismiss(animated: true, completion: nil)
        }
    }
}
