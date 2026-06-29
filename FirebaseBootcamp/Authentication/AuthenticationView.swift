//
//  AuthenticationView.swift
//  FirebaseBootcamp
//
//  Created by Sagar Jangra on 22/06/2026.
//

import SwiftUI
import Combine
import GoogleSignIn
import GoogleSignInSwift
import FirebaseAuth
import AuthenticationServices

struct SignInWithAppleButtonViewRepresentable: UIViewRepresentable {
    
    let type: ASAuthorizationAppleIDButton.ButtonType
    let style: ASAuthorizationAppleIDButton.Style
    
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        ASAuthorizationAppleIDButton(type: type, style: style)
    }
    
    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}
}



@MainActor
final class AuthenticationViewModel: ObservableObject {
    
    @Published var didSignedInWithApple: Bool = false
    
    func signInGoogle() async throws {
        let helper = SignInWithGoogleHelper()
        let tokens = try await helper.signIn()
        try await AuthenticationManager.shared.signInWithGoogle(tokens: tokens)
    }
    
    func signInApple() async throws {
        // CLEANED UP: Instantiating our isolated Apple Helper
        let helper = SignInWithAppleHelper()
        let tokens = try await helper.signIn()
        try await AuthenticationManager.shared.signInWithApple(tokens: tokens)
        
        // Triggers UI Dismissal
        self.didSignedInWithApple = true
    }
}

struct AuthenticationView: View {
    @StateObject private var vm = AuthenticationViewModel()
    @Binding var showSignInView: Bool
    
    var body: some View {
        ZStack {
            // 1. Subtle Background Gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.15), Color.purple.opacity(0.15)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                // 2. Welcoming Header Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Welcome")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Sign in to access your planner and sync your data across devices.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 40)
                
                Spacer()
                
                // 3. Button Container with Native Glass Effect
                VStack(spacing: 16) {
                    NavigationLink {
                        SignInEmailView(showSignInView: $showSignInView)
                    } label: {
                        HStack {
                            Image(systemName: "envelope.fill")
                            Text("Continue with Email")
                                .font(.headline)
                        }
                        .foregroundStyle(.white)
                        .frame(height: 55)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    
                    GoogleSignInButton(viewModel: GoogleSignInButtonViewModel(scheme: .dark, style: .wide, state: .normal)) {
                        Task {
                            do {
                                try await vm.signInGoogle()
                                showSignInView = false
                            } catch {
                                print("Error: \(error)")
                            }
                        }
                    }
                    
                    Button {
                        Task {
                            do {
                                try await vm.signInApple()
                            } catch {
                                print("Error: \(error)")
                            }
                        }
                    } label: {
                        SignInWithAppleButtonViewRepresentable(type: .continue, style: .white)
                            .allowsHitTesting(false)
                            .frame(maxWidth: .infinity)
                            .frame(height: 55)
                    }
                    .frame(height: 55)
                    .onChange(of: vm.didSignedInWithApple) { oldValue, newValue in
                        if newValue == true {
                            showSignInView = false
                        }
                    }
                }
                .padding(24)
                .background(.regularMaterial) // Native Apple glass effect
                .cornerRadius(24)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
        }
        // Hide the default nav bar so our custom title layout takes over smoothly
        .navigationBarHidden(true)
    }
}

#Preview {
    NavigationStack {
        AuthenticationView(showSignInView: .constant(false))
    }
}
