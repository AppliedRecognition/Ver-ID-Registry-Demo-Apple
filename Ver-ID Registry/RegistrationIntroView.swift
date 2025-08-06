//
//  RegistrationIntroView.swift
//  Ver-ID Registry
//
//  Created by Jakub Dolejs on 05/08/2025.
//

import SwiftUI

struct RegistrationIntroView: View {
    
    let onStartCapture: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("The app will capture your face and generate a biometric face template.")
                Text("The face template will then be used to sign you in to the app.")
                Button(action: onStartCapture) {
                    Image(systemName: "camera.fill")
                    Text("Capture face")
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle("Registration")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        RegistrationIntroView(onStartCapture: {})
    }
}
