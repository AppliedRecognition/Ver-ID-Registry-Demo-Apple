//
//  Errors.swift
//  Ver-ID Registry
//
//  Created by Jakub Dolejs on 27/08/2025.
//

import Foundation

enum ImageError: LocalizedError {
    case faceImageError
    
    var errorDescription: String? {
        switch self {
        case .faceImageError:
            return NSLocalizedString("Failed to extract face image", comment: "")
        }
    }
}
