//
//  UserView.swift
//  Ver-ID Registry
//
//  Created by Jakub Dolejs on 01/08/2025.
//

import SwiftUI
import SwiftData

struct UserView: View {

    let userName: String
    @Environment(\.modelContext) private var modelContext
    private let dateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    @Query private var taggedFaces: [TaggedFace]
    
    init(userName: String) {
        self.userName = userName
        self._taggedFaces = Query(
            filter: #Predicate<TaggedFace> { $0.userName == userName },
            sort: [SortDescriptor(\.dateAdded, order: .reverse)]
        )
    }
    
    var body: some View {
        List {
            ForEach(self.taggedFaces, id: \.persistentModelID) { face in
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
            .onDelete(perform: self.deleteFaces)
        }
        .navigationTitle(self.userName)
    }
    
    private func deleteFaces(at indices: IndexSet) {
        let toDelete = indices.map({ self.taggedFaces[$0] })
        for face in toDelete {
            modelContext.delete(face)
        }
        try? modelContext.save()
    }
}

#Preview {
    NavigationStack {
        
    }
}
