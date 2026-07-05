//
//  SignInEmailViewModel.swift
//  FirebaseBootcamp
//
//  Created by Sagar Jangra on 06/07/2026.
//


import SwiftUI
import Combine

@MainActor
final class SignInEmailViewModel : ObservableObject {
    @Published var email = ""
    @Published var password = ""
    
    func signUp() async throws {
        guard !email.isEmpty, !password.isEmpty else { return }
        
        // Context Assessment: Check if linking is required
        if AuthenticationManager.shared.isUserAnonymous() {
            try await AuthenticationManager.shared.linkWithEmail(email: email, password: password)
        } else {
            let authDataResult = try await AuthenticationManager.shared.createUser(email: email, password: password)
            try await UserManager.shared.createNewUser(auth: authDataResult)
        }
    }
    
    func signIn() async throws {
        guard !email.isEmpty, !password.isEmpty else { return }
        try await AuthenticationManager.shared.signInUser(email: email, password: password)
    }
}
