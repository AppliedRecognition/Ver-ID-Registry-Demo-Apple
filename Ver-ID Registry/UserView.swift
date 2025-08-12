//
//  UserView.swift
//  Ver-ID Registry
//
//  Created by Jakub Dolejs on 01/08/2025.
//

import SwiftUI
import SwiftData
import VerIDCommonTypes
import FaceCapture
import FaceTemplateRegistry
import FaceRecognitionArcFaceCloud

struct UserView: View {

    let userName: String
    let editable: Bool
    @Environment(\.modelContext) private var modelContext
    private let dateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    @Query private var userFaces: [TaggedFace]
    @Query private var taggedFaces: [TaggedFace]
    @StateObject private var settings = Settings()
    @State private var error: Error?
    private let faceRecognition = {
        let apiKey = Bundle.main.object(forInfoDictionaryKey: "FaceRecognitionApiKey") as! String
        let url = Bundle.main.object(forInfoDictionaryKey: "FaceRecognitionUrl") as! String
        return FaceRecognitionArcFace(apiKey: apiKey, url: URL(string: url)!)
    }()
    @State private var registering: Bool = false
    @State private var capturedFaceImage: UIImage?
    
    init(userName: String, editable: Bool = true) {
        self.userName = userName
        self.editable = editable
        self._userFaces = Query(
            filter: #Predicate<TaggedFace> { $0.userName == userName },
            sort: [SortDescriptor(\.dateAdded, order: .reverse)]
        )
    }
    
    var body: some View {
        Group {
            if self.registering {
                VStack(alignment: .center, spacing: 8) {
                    ProgressView().progressViewStyle(.circular)
                    Text("Registering")
                }
            } else {
                List {
                    if let face = self.userFaces.first {
                        Image(uiImage: face.image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .listRowSeparator(.hidden)
                            .background {
                                Color.teal
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.vertical, 8)
                    }
                    ForEach(self.userFaces, id: \.persistentModelID) { face in
                        HStack {
                            Image(uiImage: face.image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 64, height: 64)
                                .clipShape(Circle())
                            Text("Face added on \(dateFormatter.string(from: face.dateAdded))")
                                .padding(.leading, 8)
                            Spacer()
                        }
                    }
                    .if(self.editable) { view in
                        view.onDelete(perform: self.deleteFaces)
                    }
                }
            }
        }
        .navigationTitle(self.userName)
        .toolbar {
            if self.editable {
                ToolbarItem {
                    Button {
                        self.captureAndRegisterFace()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .registrationErrorAlert(userName: self.userName, isPresented: Binding(get: { self.error != nil }, set: { if !$0 { self.error = nil }}), presenting: self.error) { template, userName in
            Task(priority: .high) {
                do {
                    try await MainActor.run {
                        guard let faceImage = self.capturedFaceImage else {
                            throw NSError()
                        }
                        let taggedFace = TaggedFace(template: template, userName: userName, image: faceImage, dateAdded: .now)
                        self.modelContext.insert(taggedFace)
                        try self.modelContext.save()
                        self.capturedFaceImage = nil
                    }
                } catch {
                    await MainActor.run {
                        self.error = error
                    }
                }
            }
        }
    }
    
    private func deleteFaces(at indices: IndexSet) {
        let toDelete = indices.map({ self.userFaces[$0] })
        for face in toDelete {
            modelContext.delete(face)
        }
        try? modelContext.save()
    }
    
    private func captureAndRegisterFace() {
        self.registering = true
        Task(priority: .high) {
            do {
                self.capturedFaceImage = nil
                let result = await FaceCapture.captureFaces(configure: self.settings.configureFaceCapture)
                switch result {
                case .success(capturedFaces: let faces, metadata: _):
                    let capturedFace = faces.first!
                    var config = FaceTemplateRegistryConfiguration()
                    config.identificationThreshold = self.settings.identificationThreshold
                    let registry = FaceTemplateRegistry(faceRecognition: self.faceRecognition, faceTemplates: self.taggedFaces.map { TaggedFaceTemplate(faceTemplate: $0.template, identifier: $0.userName) }, configuration: config)
                    let registeredFace = try await registry.registerFace(capturedFace.face, image: capturedFace.image, identifier: self.userName)
                    guard let faceImage = ImageUtils.faceImageFromCapture(capturedFace) else {
                        throw NSError()
                    }
                    self.capturedFaceImage = faceImage
                    try await MainActor.run {
                        let taggedFace = TaggedFace(template: registeredFace, userName: self.userName, image: faceImage, dateAdded: .now)
                        self.modelContext.insert(taggedFace)
                        try self.modelContext.save()
                        self.registering = false
                    }
                case .failure(capturedFaces: _, metadata: _, error: let error):
                    throw error
                case .cancelled:
                    self.registering = false
                }
            } catch {
                await MainActor.run {
                    self.registering = false
                    self.error = error
                }
            }
        }
    }
}

#Preview {
    let container: ModelContainer
    do {
        container = try ModelContainer(for: TaggedFace.self, configurations: .init(isStoredInMemoryOnly: true))
        let context = container.mainContext
        let sample1 = TaggedFace(template: FaceTemplate(data: [0.5]), userName: "Curious Koala", image: .init(systemName: "camera")!, dateAdded: .now)
        let sample2 = TaggedFace(template: FaceTemplate(data: [0.6]), userName: "Curious Koala", image: .init(systemName: "camera")!, dateAdded: .now)
        context.insert(sample1)
        context.insert(sample2)
    } catch {
        fatalError("Failed to create preview container: \(error)")
    }
    return NavigationStack {
        UserView(userName: "Curious Koala")
            .modelContainer(container)
    }
}

fileprivate extension View {
    @ViewBuilder
    func `if`<Content: View>(
        _ condition: Bool,
        transform: (Self) -> Content
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
