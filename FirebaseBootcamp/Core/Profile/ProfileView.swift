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
}

struct ProfileView: View {
    @StateObject private var vm = ProfileViewModel()
    @Binding var showSignInView: Bool
    
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
