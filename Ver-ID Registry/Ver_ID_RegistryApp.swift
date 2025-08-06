//
//  Ver_ID_RegistryApp.swift
//  Ver-ID Registry
//
//  Created by Jakub Dolejs on 31/07/2025.
//

import SwiftUI
import SwiftData

@main
struct Ver_ID_RegistryApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TaggedFace.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
