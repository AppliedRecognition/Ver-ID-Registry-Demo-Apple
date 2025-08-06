//
//  ImageUtils.swift
//  Ver-ID Registry
//
//  Created by Jakub Dolejs on 01/08/2025.
//

import Foundation
import UIKit
import FaceCapture
import VerIDCommonTypes

struct ImageUtils {
    
    static func faceImageFromCapture(_ capturedFace: CapturedFace) -> UIImage? {
        guard let cgImage = capturedFace.image.toCGImage() else {
            return nil
        }
        let faceRect = capturedFace.face.bounds
        let longerDim = max(faceRect.height, faceRect.width)
        let cropRect = CGRect(x: faceRect.midX - longerDim / 2, y: faceRect.midY - longerDim / 2, width: longerDim, height: longerDim)
        if let croppedImage = cgImage.cropping(to: cropRect) {
            return UIImage(cgImage: croppedImage)
        } else {
            return nil
        }
    }
    
    static func cropImage(_ image: VerIDCommonTypes.Image, toFace face: Face) -> UIImage? {
        guard let cgImage = image.toCGImage() else {
            return nil
        }
        let minX = min(face.bounds.midX, CGFloat(image.width) - face.bounds.midX)
        let minY = min(face.bounds.midY, CGFloat(image.height) - face.bounds.midY)
        let minDistanceToEdge = min(minX, minY)
        let cropRect = CGRect(
            x: face.bounds.midX - minDistanceToEdge,
            y: face.bounds.midY - minDistanceToEdge,
            width: minDistanceToEdge * 2,
            height: minDistanceToEdge * 2
        )
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        return UIGraphicsImageRenderer(size: cropRect.size, format: format).image { context in
            UIImage(cgImage: cgImage).draw(at: CGPoint(x: 0-cropRect.minX, y: 0-cropRect.minY))
        }
    }
}
