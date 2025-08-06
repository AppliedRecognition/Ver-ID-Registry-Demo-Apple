//
//  UsersView.swift
//  Ver-ID Registry
//
//  Created by Jakub Dolejs on 01/08/2025.
//

import SwiftUI
import SwiftData

struct UsersView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaggedFace.dateAdded, order: .reverse)
    private var taggedFaces: [TaggedFace]
    @Binding var navigationPath: NavigationPath
    private var users: [TaggedFace] {
        var seen: Set<String> = []
        var result: [TaggedFace] = []
        for taggedFace in taggedFaces {
            if seen.contains(taggedFace.userName) {
                continue
            }
            seen.insert(taggedFace.userName)
            result.append(taggedFace)
        }
        return result.sorted {
            $0.userName.localizedStandardCompare($1.userName) == .orderedAscending
        }
    }
    
    var body: some View {
        List {
            ForEach(self.users, id: \.persistentModelID) { user in
                HStack {
                    Image(uiImage: user.image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    Text(user.userName)
                        .padding(.leading, 8)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    self.navigationPath.append(Route.user(user.userName))
                }
            }
            .onDelete(perform: self.deleteUsers)
        }
        .navigationTitle("Registrations")
    }
    
    private func deleteUsers(at offsets: IndexSet) {
        for index in offsets {
            let userName = self.users[index].userName
            try? modelContext.delete(model: TaggedFace.self, where: #Predicate { $0.userName == userName })
        }
        try? modelContext.save()
    }
}

//#Preview {
//    UsersView()
//}
