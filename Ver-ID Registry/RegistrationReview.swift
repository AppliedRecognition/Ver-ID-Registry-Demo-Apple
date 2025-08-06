//
//  RegistrationReview.swift
//  Ver-ID Registry
//
//  Created by Jakub Dolejs on 31/07/2025.
//

import SwiftUI
import SwiftData
import VerIDCommonTypes
import FaceCapture
import FaceTemplateRegistry
import FaceRecognitionArcFaceCore
import FaceRecognitionArcFaceCloud

struct RegistrationReview: View {
    
    let capturedFace: CapturedFace
    let faceTemplateRegistry: FaceTemplateRegistry<V24, [Float], FaceRecognitionArcFace>
    @Binding var navigationPath: NavigationPath
    let uiImage: UIImage?
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: Settings
    @State var error: Error?
    @State var registering: Bool = false
    @State var name: String
    
    init(capturedFace: CapturedFace, faceTemplateRegistry: FaceTemplateRegistry<V24, [Float], FaceRecognitionArcFace>, navigationPath: Binding<NavigationPath>) {
        self.capturedFace = capturedFace
        self.faceTemplateRegistry = faceTemplateRegistry
        self._navigationPath = navigationPath
        self.uiImage = ImageUtils.cropImage(capturedFace.image, toFace: capturedFace.face)
        self._name = State(initialValue: RandomNameGenerator.generateRandomName())
    }
    
    var body: some View {
        Group {
            if self.registering {
                VStack {
                    ProgressView().progressViewStyle(.circular)
                    Text("Registering face")
                }
            } else if let uiImage = self.uiImage {
                RegistrationReviewPrivate(image: uiImage, name: $name, onSubmit: {
                    let name = self.name.trimmingCharacters(in: .whitespacesAndNewlines)
                    if name.isEmpty {
                        return
                    }
                    self.registerUser(name, capturedFace: self.capturedFace)
                })
            } else {
                Text("Failed to load image")
            }
        }
        .alert("Error", isPresented: Binding(get: { self.error != nil }, set: { newVal in if !newVal { self.error = nil }}), presenting: self.error) { error in
            if case FaceTemplateRegistryError.similarFaceAlreadyRegisteredAs(let userName, let template, _) = error {
                Button {
                    Task {
                        do {
                            try await self.saveFaceTemplate(template as! FaceTemplate<V24, [Float]>, capturedFace: self.capturedFace, as: userName)
                        } catch {
                            await MainActor.run {
                                self.error = error
                            }
                        }
                    }
                } label: {
                    Text("Add face to \(userName)")
                }
                Button {
                    Task {
                        do {
                            try await self.saveFaceTemplate(template as! FaceTemplate<V24, [Float]>, capturedFace: self.capturedFace, as: self.name.trimmingCharacters(in: .whitespacesAndNewlines))
                        } catch {
                            await MainActor.run {
                                self.error = error
                            }
                        }
                    }
                } label: {
                    Text("Save as \(self.name.trimmingCharacters(in: .whitespacesAndNewlines)) anyway")
                }
            }
            Button(role: .cancel) {} label: {
                Text("Dismiss")
            }
        } message: { error in
            Text("Registration failed: \(error.localizedDescription)")
        }
    }
    
    private func registerUser(_ name: String, capturedFace: CapturedFace) {
        self.registering = true
        Task(priority: .high) {
            do {
                let registeredTemplate = try await self.faceTemplateRegistry.registerFace(capturedFace.face, image: capturedFace.image, identifier: name)
                try await self.saveFaceTemplate(registeredTemplate, capturedFace: capturedFace, as: name)
            } catch {
                await MainActor.run {
                    self.error = error
                }
            }
            await MainActor.run {
                self.registering = false
            }
        }
    }
    
    private func saveFaceTemplate(_ faceTemplate: FaceTemplate<V24,[Float]>,
                                  capturedFace: CapturedFace,
                                  as name: String) async throws {
        guard let faceImage = ImageUtils.faceImageFromCapture(capturedFace) else {
            throw NSError()
        }
        try await MainActor.run {
            let taggedFace = TaggedFace(template: faceTemplate, userName: name, image: faceImage, dateAdded: .now)
            self.modelContext.insert(taggedFace)
            try self.modelContext.save()
            self.navigationPath.removeLast(2)
            self.navigationPath.append(Route.user(name))
        }
    }
}

fileprivate struct RegistrationReviewPrivate: View {
    
    let image: UIImage
    let onSubmit: () -> Void
    @FocusState private var isTextFieldFocused: Bool
    @Binding private var name: String
    
    init(image: UIImage, name: Binding<String>, onSubmit: @escaping () -> Void) {
        self.image = image
        self.onSubmit = onSubmit
        self._name = name
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing, height: geometry.size.height + geometry.safeAreaInsets.top - 100)
                    .clipped()
                    .ignoresSafeArea(edges: [.top, .leading, .trailing])
                VStack(alignment: .leading) {
                    Text("Your name")
                        .font(.caption)
                    TextField(text: $name) {
                        Text("Enter your name")
                    }
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.done)
                    .focused($isTextFieldFocused)
                    .onSubmit(self.submit)
                }
                .padding()
                .frame(height: 100)
            }
            .ignoresSafeArea(edges: [.top, .bottom])
            .onAppear {
                self.isTextFieldFocused = true
            }
        }
        .toolbar {
            ToolbarItem {
                Button {
                    self.submit()
                } label: {
                    Text("Save")
                }
                .buttonStyle(.borderedProminent)
                .disabled(self.name.isEmpty)
            }
        }
    }
    
    private func submit() {
        if !self.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.onSubmit()
        }
    }
}

#Preview {
    NavigationStack {
        RegistrationReviewPrivate(image: UIImage(named: "face-image")!, name: .constant("Test"), onSubmit: {})
    }
}
