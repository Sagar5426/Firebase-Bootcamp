//
//  SettingsViewModel.swift
//  FirebaseBootcamp
//
//  Created by Sagar Jangra on 06/07/2026.
//


import SwiftUI
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    
    @Published var authProviders: [AuthProviderOption] = []
    @Published var linkedProviders: [String] = []
        
        func loadAuthProviders() {
            self.linkedProviders = AuthenticationManager.shared.getLinkedProviders()
        }
        
        func linkGoogleAccount() async throws {
            let helper = SignInWithGoogleHelper()
            let tokens = try await helper.signIn()
            try await AuthenticationManager.shared.linkGoogle(tokens: tokens)
            self.loadAuthProviders() // Refresh UI after successful link
        }
        
        func linkAppleAccount() async throws {
            let helper = SignInWithAppleHelper()
            let tokens = try await helper.signIn()
            try await AuthenticationManager.shared.linkApple(tokens: tokens)
            self.loadAuthProviders() // Refresh UI after successful link
        }
    
    func signOut() throws {
        try AuthenticationManager.shared.signOut()
    }
    
    func deleteAccount() async throws {
        try await AuthenticationManager.shared.deleteUser()
    }
    
    func resetPassword() async throws {
        let authUser = try AuthenticationManager.shared.getAuthenticatedUser()
        guard let email = authUser.email else {
            throw URLError(.fileDoesNotExist)
        }
        try await AuthenticationManager.shared.resetPassword(email: email)
    }
    
    
    func updateEmail() async throws {
        let email = "hello123@gmail.com"
        try await AuthenticationManager.shared.updateEmail(email: email)
    }
    
    func updatePassword() async throws {
        let password = "Hello123!"
        try await AuthenticationManager.shared.updatePassword(password: password)
    }
}
