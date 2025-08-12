//
//  ContentView.swift
//  Ver-ID Registry
//
//  Created by Jakub Dolejs on 31/07/2025.
//

import SwiftUI
import SwiftData
import FaceCapture
import FaceTemplateRegistry
import FaceRecognitionArcFaceCore
import FaceRecognitionArcFaceCloud
import FaceDetectionRetinaFace
import VerIDCommonTypes
import SpoofDeviceDetection

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var taggedFaces: [TaggedFace]
    @State private var capturedFace: CapturedFace?
    @State private var error: Error?
    @State private var activity: String?
    @State var navigationPath = NavigationPath()
    @StateObject private var settings = Settings()
    
    private let faceRecognition = {
        let apiKey = Bundle.main.object(forInfoDictionaryKey: "FaceRecognitionApiKey") as! String
        let url = Bundle.main.object(forInfoDictionaryKey: "FaceRecognitionUrl") as! String
        return FaceRecognitionArcFace(apiKey: apiKey, url: URL(string: url)!)
    }()
    private var registry: FaceTemplateRegistry<V24,[Float],FaceRecognitionArcFace>?
    
    private var content: some View {
        ZStack {
            Image("selfie", bundle: Bundle.main)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 300, height: 300)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .ignoresSafeArea()
            VStack {
                if let activity = self.activity {
                    ProgressView().progressViewStyle(.circular)
                    Text(activity)
                } else if self.taggedFaces.isEmpty {
                    Button {
                        self.navigationPath.append(Route.register)
                    } label: {
                        Text("Register").font(.title2)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button {
                        self.signIn()
                    } label: {
                        Text("Sign in").font(.title2)
                    }.buttonStyle(.borderedProminent)
                        .padding(.bottom, 16)
                    Button {
                        self.navigationPath.append(Route.register)
                    } label: {
                        Text("Register").font(.title2)
                    }
                }
            }
            .padding(.bottom, 100)
        }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            content
                .navigationTitle("Ver-ID registry demo")
                .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: CapturedFace.self) { capturedFace in
                RegistrationReview(
                    capturedFace: capturedFace,
                    faceTemplateRegistry: self.createFaceTemplateRegistry(),
                    navigationPath: $navigationPath
                )
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .users:
                    UsersView(navigationPath: $navigationPath)
                case .register:
                    RegistrationIntroView {
                        self.register()
                    }
                case .settings:
                    SettingsView(navigationPath: self.$navigationPath)
                        .environmentObject(self.settings)
                case .user(let identifier, let editable):
                    UserView(userName: identifier, editable: editable)
                }
            }
            .alert("Identification", isPresented: .constant(capturedFace != nil), presenting: capturedFace) { face in
                Button(role: .cancel) {} label: {
                    Text("Cancel")
                }
                Button {
                    self.signIn()
                } label: {
                    Text("Try again")
                }
                Button {
                    self.navigationPath.append(face)
                } label: {
                    Text("Register face")
                }
            } message: { face in
                Text("We were unable to identify you.")
            }
            .alert("Error", isPresented: .constant(error != nil), presenting: error) { error in
                Button(role: .cancel) {} label: {
                    Text("Dismiss")
                }
            } message: { error in
                Text(error.localizedDescription)
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        self.navigationPath.append(Route.settings)
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .environmentObject(self.settings)
        }
    }
    
    private func signIn() {
        self.activity = "Signing in"
        Task(priority: .high) {
            do {
                guard let face = try await self.captureFace() else {
                    return
                }
                let registry = await MainActor.run {
                    self.createFaceTemplateRegistry()
                }
                let results = try await registry.identifyFace(face.face, image: face.image)
                await MainActor.run {
                    if let identified = results.first {
                        self.navigationPath.append(Route.user(identified.taggedFaceTemplate.identifier, true))
                    } else {
                        // Nobody identified
                        self.capturedFace = face
                    }
                }
            } catch {
                await MainActor.run {
                    self.error = error
                }
            }
            await MainActor.run {
                self.activity = nil
            }
        }
    }
    
    private func register() {
        Task(priority: .high) {
            do {
                guard let face = try await self.captureFace() else {
                    return
                }
                self.navigationPath.append(face)
            } catch {
                self.error = error
            }
        }
    }
    
    private func captureFace() async throws -> CapturedFace? {
        let result = await FaceCapture.captureFaces(configure: self.settings.configureFaceCapture)
        switch result {
        case .success(capturedFaces: let faces, metadata: _):
            return faces.first!
        case .failure(capturedFaces: _, metadata: _, error: let error):
            throw error
        case .cancelled:
            return nil
        }
    }
    
    private func createFaceTemplateRegistry() -> FaceTemplateRegistry<V24, [Float], FaceRecognitionArcFace> {
        let faces = self.taggedFaces.map { face in
            TaggedFaceTemplate(faceTemplate: face.template, identifier: face.userName)
        }
        return FaceTemplateRegistry(faceRecognition: self.faceRecognition, faceTemplates: faces)
    }
}

enum Route: Hashable {
    case users
    case register
    case settings
    case user(String,Bool)
}

#Preview {
    let container: ModelContainer
    do {
        container = try ModelContainer(for: TaggedFace.self, configurations: .init(isStoredInMemoryOnly: true))
        let context = container.mainContext
        let sample = TaggedFace(template: FaceTemplate(data: [0.5]), userName: "Test", image: .init(systemName: "camera")!, dateAdded: .now)
        context.insert(sample)
    } catch {
        fatalError("Failed to create preview container: \(error)")
    }
    return ContentView()
        .modelContainer(container)
}
