//
//  UIImage+Extensions.swift
//  EyeSee
//
//  Created by imac-3570 on 2024/4/29.
//

import UIKit

extension UIImage {
    
    public func pixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
        var maybePixelBuffer: CVPixelBuffer?
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
             kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue]
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         Int(width),
                                         Int(height),
                                         kCVPixelFormatType_32ARGB,
                                         attrs as CFDictionary,
                                         &maybePixelBuffer)
        
        guard status == kCVReturnSuccess, let pixelBuffer = maybePixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)
        
        guard let context = CGContext(data: pixelData,
                                      width: Int(width),
                                      height: Int(height),
                                      bitsPerComponent: 8,
                                      bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        else {
            return nil
        }
        
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)
        
        UIGraphicsPushContext(context)
        self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
    
    func uiImageToBase64Str() -> String? {
        let imageOrigin = self
        let dataTemp = imageOrigin.pngData()
        guard let data = dataTemp else{
            return nil
        }
        let base64Str = data.base64EncodedString()
        return base64Str
    }
    
    /// 調整圖像對比度
    func adjustedContrast(by contrast: CGFloat) -> UIImage? {
        guard let ciImage = CIImage(image: self) else { return nil }
        let context = CIContext(options: nil)
        let filter = CIFilter.colorControls()
        filter.inputImage = ciImage
        filter.contrast = Float(
            contrast
        ) // 對比度值，1.0為原始對比度，大於1.0提高對比度，介於0-1.0之間降低對比度
        filter.brightness = 0 // 根據需要調整亮度
        filter.saturation = 1 // 根據需要調整飽和度
        
        guard let outputImage = filter.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
}

