//
//  SettingsView.swift
//  FirebaseBootcamp
//
//  Created by Sagar Jangra on 24/06/2026.
//

import SwiftUI
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    
    @Published var authProviders: [AuthProviderOption] = []
    
    func loadAuthProviders() {
        if let providers = try? AuthenticationManager.shared.getProvider() {
            authProviders = providers
        }
    }
    
    func signOut() throws {
        try AuthenticationManager.shared.signOut()
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

struct SettingsView: View {
    @StateObject private var vm = SettingsViewModel()
    @Binding var showSignInView: Bool
    var body: some View {
        List {
            Button("Log out") {
                Task {
                    do {
                        try vm.signOut()
                        showSignInView = true
                    } catch {
                        print("Error: \(error)")
                    }
                }
            }
            if vm.authProviders.contains(.email) {
                emailSection
            }
            
        }
        .onAppear {
            vm.loadAuthProviders()
        }
        .navigationTitle("SettingsView")
    }
}

#Preview {
    SettingsView(showSignInView: .constant(false))
}

extension SettingsView {
    
    private var emailSection: some View {
        Section {
            Button("Reset Password") {
                Task {
                    do {
                        try await vm.resetPassword()
                        print("Password Reset!")
                        showSignInView = true
                    } catch {
                        print("Error: \(error)")
                    }
                }
            }
            
            Button("Update Password") {
                Task {
                    do {
                        try await vm.updatePassword()
                        print("Password Reset!")
                    } catch {
                        print("Error: \(error)")
                    }
                }
            }
            
            Button("Update Email") {
                Task {
                    do {
                        try await vm.updateEmail()
                        print("Password Reset!")
                    } catch {
                        print("Error: \(error)")
                    }
                }
            }
        } header: {
            Text("Email functions")
        }
    }
}
