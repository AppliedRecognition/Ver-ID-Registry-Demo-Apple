//
//  TaggedFace.swift
//  Ver-ID Registry
//
//  Created by Jakub Dolejs on 31/07/2025.
//

import Foundation
import SwiftData
import UIKit
import VerIDCommonTypes
import FaceRecognitionArcFaceCore

@Model
final class TaggedFace {
    
    var dateAdded: Date
    var templateData: Data
    var userName: String
    @Attribute(.externalStorage)
    var imageData: Data
    
    init(template: FaceTemplate<V24, [Float]>, userName: String, image: UIImage, dateAdded: Date) {
        self.templateData = try! JSONEncoder().encode(template)
        self.userName = userName
        self.imageData = image.pngData()!
        self.dateAdded = dateAdded
    }
    
    var template: FaceTemplate<V24, [Float]> {
        try! JSONDecoder().decode(FaceTemplate<V24, [Float]>.self, from: self.templateData)
    }
    
    var image: UIImage {
        UIImage(data: self.imageData)!
    }
}
