//
//  RegistrationErrorDialog.swift
//  Ver-ID Registry
//
//  Created by Jakub Dolejs on 12/08/2025.
//

import SwiftUI
import FaceTemplateRegistry
import VerIDCommonTypes
import FaceRecognitionArcFaceCore
import FaceCapture

struct RegistrationErrorDialog: View {
    
    let name: String
    let error: Error
    let onSave: (FaceTemplate<V24, [Float]>, String) -> Void
    
    var body: some View {
        switch self.error {
        case FaceTemplateRegistryError.similarFaceAlreadyRegisteredAs(let userName, let template, _):
            Button {
                self.onSave(template as! FaceTemplate<V24, [Float]>, userName)
            } label: {
                Text("Add face to \(userName)")
            }
            Button {
                self.onSave(template as! FaceTemplate<V24, [Float]>, self.name.trimmingCharacters(in: .whitespacesAndNewlines))
            } label: {
                Text("Save as \(self.name.trimmingCharacters(in: .whitespacesAndNewlines)) anyway")
            }
        case FaceTemplateRegistryError.faceDoesNotMatchExisting(let template, _):
            Button {
                self.onSave(template as! FaceTemplate<V24, [Float]>, self.name.trimmingCharacters(in: .whitespacesAndNewlines))
            } label: {
                Text("Save anyway")
            }
        default:
            EmptyView()
        }
        Button(role: .cancel) {} label: {
            Text("Dismiss")
        }
    }
}

extension View {
    @ViewBuilder
    func registrationErrorAlert(
        userName: String,
        isPresented: Binding<Bool>,
        presenting: Error?,
        onSave: @escaping (FaceTemplate<V24, [Float]>, String) -> Void
    ) -> some View {
        self.alert("Registration failed", isPresented: isPresented, presenting: presenting) { error in
            RegistrationErrorDialog(name: userName, error: error, onSave: onSave)
        } message: { error in
            if error is LocalizedError {
                Text(error.localizedDescription)
            } else {
                EmptyView()
            }
        }
    }
}

#Preview {
    NavigationStack {
        let err: Error? = FaceTemplateRegistryError
            .similarFaceAlreadyRegisteredAs("Talkative Sloth", FaceTemplate<V24, [Float]>(data: [0.5]), 0.6)
        VStack {
        }
        .registrationErrorAlert(userName: "Curious Koala", isPresented: .constant(true), presenting: err, onSave: { _, _ in })
    }
}

#Preview {
    NavigationStack {
        let err: Error? = FaceTemplateRegistryError
            .faceDoesNotMatchExisting(FaceTemplate<V24, [Float]>(data: [0.5]), 0.4)
        VStack {
        }
        .registrationErrorAlert(userName: "Curious Koala", isPresented: .constant(true), presenting: err, onSave: { _, _ in })
    }
}
