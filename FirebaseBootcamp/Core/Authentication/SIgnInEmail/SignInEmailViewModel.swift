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
            let authDataResult = try await AuthenticationManager.shared.linkWithEmail(email: email, password: password)
            let user = DbUser(auth: authDataResult)
            try await UserManager.shared.createNewUser(user: user)
        } else {
            let authDataResult = try await AuthenticationManager.shared.createUser(email: email, password: password)
            let user = DbUser(auth: authDataResult)
            try await UserManager.shared.createNewUser(user: user)
        }
    }
    
    func signIn() async throws {
        guard !email.isEmpty, !password.isEmpty else { return }
        try await AuthenticationManager.shared.signInUser(email: email, password: password)
    }
}
