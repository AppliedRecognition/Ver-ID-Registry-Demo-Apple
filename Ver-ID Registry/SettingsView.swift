//
//  SettingsView.swift
//  Ver-ID Registry
//
//  Created by Jakub Dolejs on 05/08/2025.
//

import SwiftUI
import FaceTemplateRegistry
import SwiftData

struct SettingsView: View {
    
    @EnvironmentObject var settings: Settings
    @Environment(\.modelContext) private var modelContext
    @Query private var taggedFaces: [TaggedFace]
    @Binding var navigationPath: NavigationPath
    private var userCount: Int {
        Set(self.taggedFaces.map { $0.userName }).count
    }
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    Text("This app shows how to use Ver\u{2011}ID SDK to build a biometric sign-in system.")
                    Text("The app captures a face and registers it under a user's name. Once registered, the user can sign in to the app using their face.")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } header: {
                Text("About the app")
            }
            Section {
                HStack {
                    if userCount == 1 {
                        Text("1 registered user")
                    } else if userCount == 0 {
                        Text("No registered users")
                    } else {
                        Text("\(userCount) registered users")
                    }
                    Spacer()
                    if self.userCount > 0 {
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if self.userCount > 0 {
                        self.navigationPath.append(Route.users)
                    }
                }
            } header: {
                Text("Registration")
            }
            Section {
                Toggle(isOn: $settings.useBackCamera) {
                    Text("Use back camera")
                }
                Toggle(isOn: $settings.enableSpoofDetection) {
                    Text("Enable spoof detection")
                }
            } header: {
                Text("Face capture")
            }
            Section {
                Stepper(value: $settings.identificationThreshold, in: 0.1...0.9, step: 0.1) {
                    HStack {
                        Text("Identification threshold")
                        Spacer()
                        Text(String(format: "%0.1f", settings.identificationThreshold))
                    }
                }
            } header: {
                Text("Face recognition")
            } footer: {
                Text("The threshold will be used when comparing faces. Higher threshold makes the comparison stricter.")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if self.userCount > 0 {
                    Menu {
                        Text("This will also delete all registered face templates")
                        Button("Proceed anyway", role: .destructive) {
                            do {
                                try self.modelContext.delete(model: TaggedFace.self)
                                try self.modelContext.save()
                                self.settings.reset()
                            } catch {
                                
                            }
                        }
                    } label: {
                        Text("Reset")
                    }
                } else {
                    Button {
                        self.settings.reset()
                    } label: {
                        Text("Reset")
                    }
                }
            }
        }
        .onChange(of: settings.identificationThreshold, initial: false) { _, newValue in
            if newValue < 0.1 {
                settings.identificationThreshold = 0.1
            } else if newValue > 0.9 {
                settings.identificationThreshold = 0.9
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView(navigationPath: .constant(NavigationPath()))
            .modelContainer(for: TaggedFace.self)
            .environmentObject(Settings())
    }
}
