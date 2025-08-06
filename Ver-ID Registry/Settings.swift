//
//  Settings.swift
//  Ver-ID Registry
//
//  Created by Jakub Dolejs on 05/08/2025.
//

import Foundation
import SwiftUI
import Combine
import FaceTemplateRegistry
import FaceCapture
import FaceDetectionRetinaFace
import SpoofDeviceDetection
import AVFoundation

final class Settings: ObservableObject {
    
    @Published var identificationThreshold: Float
    @Published var useBackCamera: Bool
    @Published var enableSpoofDetection: Bool
    
    private var cancellables = Set<AnyCancellable>()
    private let defaults: [String: Any] = [
        SettingKeys.identificationThreshold: FaceTemplateRegistryConfiguration().identificationThreshold,
        SettingKeys.useBackCamera: false,
        SettingKeys.enableSpoofDetection: true
    ]

    init() {
        UserDefaults.standard.register(defaults: self.defaults)
        self.identificationThreshold = UserDefaults.standard.float(forKey: SettingKeys.identificationThreshold)
        self.useBackCamera = UserDefaults.standard.bool(forKey: SettingKeys.useBackCamera)
        self.enableSpoofDetection = UserDefaults.standard.bool(forKey: SettingKeys.enableSpoofDetection)
        self.$identificationThreshold.sink { newValue in
            UserDefaults.standard.setValue(newValue, forKey: SettingKeys.identificationThreshold)
        }.store(in: &self.cancellables)
        self.$useBackCamera.sink { newValue in
            UserDefaults.standard.setValue(newValue, forKey: SettingKeys.useBackCamera)
        }.store(in: &self.cancellables)
        self.$enableSpoofDetection.sink { newValue in
            UserDefaults.standard.setValue(newValue, forKey: SettingKeys.enableSpoofDetection)
        }.store(in: &self.cancellables)
    }
    
    func reset() {
        self.identificationThreshold = self.defaults[SettingKeys.identificationThreshold] as! Float
        self.useBackCamera = self.defaults[SettingKeys.useBackCamera] as! Bool
        self.enableSpoofDetection = self.defaults[SettingKeys.enableSpoofDetection] as! Bool
    }
    
    func configureFaceCapture(configuration: inout FaceCaptureConfiguration) throws {
        let faceDetection = try FaceDetectionRetinaFace()
        configuration.faceDetection = faceDetection
        configuration.useBackCamera = self.useBackCamera
        if self.enableSpoofDetection {
            let cameraPosition: AVCaptureDevice.Position = self.useBackCamera ? .back : .front
            if FaceCaptureSession.supportsDepthCaptureOnDeviceAt(cameraPosition) {
                configuration.faceTrackingPlugins = [DepthLivenessDetection()]
            } else if let apiKey = Bundle.main.object(forInfoDictionaryKey: "SpoofDeviceDetectionApiKey") as? String,
                      let urlString = Bundle.main.object(forInfoDictionaryKey: "SpoofDeviceDetectionUrl") as? String,
                      let url = URL(string: urlString) {
                let spoofDeviceDetection = SpoofDeviceDetection(apiKey: apiKey, url: url)
                configuration.faceTrackingPlugins = [try LivenessDetectionPlugin(spoofDetectors: [spoofDeviceDetection])]
            }
        }
    }
}

struct SettingKeys {
    static let identificationThreshold = "identificationThreshold"
    static let useBackCamera = "useBackCamera"
    static let enableSpoofDetection = "enableSpoofDetection"
    private init() {}
}
