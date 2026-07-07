//
//  ProfileView.swift
//  FirebaseBootcamp
//
//  Created by Sagar Jangra on 06/07/2026.
//

import SwiftUI
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published private(set) var user: DbUser? = nil
    
    func loadCurrentUser() async throws {
        let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()
        self.user = try await UserManager.shared.getUser(userId: authDataResult.uid)
    }
    
    func togglePremiumStatus() {
        guard let user  = user else {return}
        let currentPremiumStatus = user.isPremium ?? false
        
        Task {
            try await UserManager.shared.updateUserPremiumStatus(userId: user.userId, isPremium: !currentPremiumStatus)
            self.user = try await UserManager.shared.getUser(userId: user.userId)
        }
    }
    
    func addUserPreference(text: String) {
        guard let user  = user else {return}
        
        Task {
            try await UserManager.shared.addUserPreference(userId: user.userId, preferences: text)
            self.user = try await UserManager.shared.getUser(userId: user.userId)
        }
    }
    
    func removeUserPreference(text: String) {
        guard let user  = user else {return}
        
        Task {
            try await UserManager.shared.removeUserPreference(userId: user.userId, preferences: text)
            self.user = try await UserManager.shared.getUser(userId: user.userId)
        }
    }
    
    func addFavouriteMovie() {
            guard let user  = user else {return}
            let movie = Movie(id: "1", name: "Doomsday", isPopular: true)
            Task {
                do {
                    try await UserManager.shared.addFavMovie(userId: user.userId, movie: movie)
                    self.user = try await UserManager.shared.getUser(userId: user.userId)
                } catch {
                    print("Error adding favorite movie: \(error)")
                }
            }
        }
    
    func removeFavoriteMovie() {
            guard let user = user else { return }
            
            Task {
                do {
                    try await UserManager.shared.removeFavMovie(userId: user.userId)
                    self.user = try await UserManager.shared.getUser(userId: user.userId)
                    
                } catch {
                    print("Error removing favorite movie: \(error.localizedDescription)")
                }
            }
        }
    
}

struct ProfileView: View {
    @StateObject private var vm = ProfileViewModel()
    @Binding var showSignInView: Bool
    
    let preferencesOption = ["Books", "Movies", "Sports"]
    private func preferenceIsSelected(text: String) -> Bool {
        vm.user?.preferences?.contains(text) == true
    }
    
    var body: some View {
        List {
            if let user = vm.user {
                Text("User id: \(user.userId)")
                
                if let email = user.email {
                    Text("Email: \(email)")
                }
                if let date = user.date_created {
                    Text("Date Created: \(date)")
                }
                
                Button {
                    vm.togglePremiumStatus()
                } label: {
                    Text("User is premium: \((user.isPremium ?? false).description.capitalized)")
                }
                
                VStack {
                    HStack {
                        ForEach(preferencesOption, id: \.self) { string in
                            Button(string) {
                                if preferenceIsSelected(text: string) {
                                    vm.removeUserPreference(text: string)
                                } else {
                                    vm.addUserPreference(text: string)
                                }
                            }
                            .font(.headline)
                            .buttonStyle(.borderedProminent)
                            .tint(preferenceIsSelected(text: string) ? .green: .red)
                        }
                    }
                    
                    Text("User preferences: \((user.preferences ?? []).joined(separator: ", "))")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Button {
                    if user.favouriteMovie == nil {
                        vm.addFavouriteMovie()
                    } else {
                        vm.removeFavoriteMovie()
                    }
                } label: {
                    Text("Favorite Movie: \(user.favouriteMovie?.name ?? "" )")
                }
            }
            
        }
        .task {
            try? await vm.loadCurrentUser()
        }
        .navigationTitle("Profile")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink  {
                    SettingsView(showSignInView: $showSignInView)
                } label: {
                    Image(systemName: "gear")
                        .font(.headline)
                }
            }
        }
    }
}



#Preview {
    NavigationStack {
        ProfileView(showSignInView: .constant(true))
    }
}
