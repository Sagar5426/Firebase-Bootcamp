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

@MainActor
final class AuthenticationViewModel: ObservableObject {
    
    @Published var didSignedInWithApple: Bool = false
    
    func signInAnonymous() async throws {
        try await AuthenticationManager.shared.signInAnonymously()
    }
    
    func signInGoogle() async throws {
        let helper = SignInWithGoogleHelper()
        let tokens = try await helper.signIn()
        let authDataResult = try await AuthenticationManager.shared.linkOrSignInWithGoogle(tokens: tokens)
        let user = DbUser(auth: authDataResult)
        try await UserManager.shared.createNewUser(user: user)
    }
    
    func signInApple() async throws {
        let helper = SignInWithAppleHelper()
        let tokens = try await helper.signIn()
        let authDataResult = try await AuthenticationManager.shared.linkOrSignInWithApple(tokens: tokens)
        let user = DbUser(auth: authDataResult)
        try await UserManager.shared.createNewUser(user: user)
        
        self.didSignedInWithApple = true
    }
}

struct AuthenticationView: View {
    
    @StateObject private var vm = AuthenticationViewModel()
    @Binding var showSignInView: Bool
    
    var body: some View {
        ZStack {
            // 1. Sleek Dark Background
            LinearGradient(
                colors: [Color(red: 0.1, green: 0.1, blue: 0.12), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Subtle dark mode ambient glow
            GeometryReader { proxy in
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .blur(radius: 100)
                    .frame(width: 300, height: 300)
                    .offset(x: -50, y: -50)
                
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .blur(radius: 100)
                    .frame(width: 300, height: 300)
                    .offset(x: proxy.size.width - 150, y: proxy.size.height - 200)
            }
            .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // 2. Minimalist Header
                VStack(spacing: 16) {
                    Image(systemName: "flame.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 75, height: 75)
                        .foregroundStyle(
                            LinearGradient(colors: [.orange, .red], startPoint: .top, endPoint: .bottom)
                        )
                        .shadow(color: .red.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    Text("Welcome")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("Sign in to sync your data and continue your progress.")
                        .font(.callout)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.gray)
                        .padding(.horizontal, 40)
                }
                .padding(.bottom, 50)
                
                // 3. Frosted Glass Authentication Card
                VStack(spacing: 20) {
                    
                    // Custom Email Button
                    NavigationLink {
                        SignInEmailView(showSignInView: $showSignInView)
                    } label: {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .font(.title3)
                            Text("Continue with Email")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.white)
                        .frame(height: 55)
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                    
                    // Subtle Divider
                    HStack {
                        VStack { Divider().background(Color.gray.opacity(0.5)) }
                        Text("or")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                        VStack { Divider().background(Color.gray.opacity(0.5)) }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    
                    // SSO Providers
                    VStack(spacing: 16) {
                        GoogleSignInButton(viewModel: GoogleSignInButtonViewModel(scheme: .dark, style: .wide, state: .normal)) {
                            Task {
                                do {
                                    try await vm.signInGoogle()
                                    showSignInView = false
                                } catch {
                                    print("Error linking/signing with Google: \(error)")
                                }
                            }
                        }
                        .frame(height: 55)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        
                        Button {
                            Task {
                                do {
                                    try await vm.signInApple()
                                } catch {
                                    print("Error processing Apple Sign In context: \(error)")
                                }
                            }
                        } label: {
                            // Switched to .whiteOutline for better contrast against dark mode
                            SignInWithAppleButtonViewRepresentable(type: .continue, style: .whiteOutline)
                                .allowsHitTesting(false)
                        }
                        .frame(height: 55)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .onChange(of: vm.didSignedInWithApple) { oldValue, newValue in
                            if newValue == true {
                                showSignInView = false
                            }
                        }
                    }
                }
                .padding(30)
                // Combining a slight black tint with ultraThinMaterial creates a great dark glass effect
                .background(Color.black.opacity(0.4))
                .background(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .padding(.horizontal, 24)
                
                Spacer()
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    NavigationStack {
        AuthenticationView(showSignInView: .constant(false))
    }
}
