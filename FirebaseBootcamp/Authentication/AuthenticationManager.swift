//
//  AuthenticationManager.swift
//  FirebaseBootcamp
//
//  Created by Sagar Jangra on 23/06/2026.
//

import SwiftUI
import FirebaseAuth

struct AuthDataResultModel  {
    let uid: String
    let email: String?
    let photoUrl: String?
    
    init(user: User) {
        self.uid = user.uid
        self.email = user.email
        self.photoUrl = user.photoURL?.absoluteString
    }
}

enum AuthProviderOption: String {
    case email = "password"
    case google = "google.com"
    case apple = "apple.com"
}

final class AuthenticationManager {
    static let shared = AuthenticationManager()
    private init () {}
    
    func getAuthenticatedUser() throws -> AuthDataResultModel {
        guard let user = Auth.auth().currentUser else {
            throw URLError(.badServerResponse)
        }
        
        return AuthDataResultModel(user: user)
    }
    
    func getProvider() throws -> [AuthProviderOption] {
        guard let providerData = Auth.auth().currentUser?.providerData else {
            throw URLError(.badURL)
        }
        
        var providers: [AuthProviderOption] = []
        for provider in providerData {
            if let option = AuthProviderOption(rawValue: provider.providerID) {
                providers.append(option)
            } else {
                assertionFailure("Provider option not found: \(provider.providerID)")
            }
        }
        
        return providers
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
    }
    
    func deleteUser() async throws {
            guard let user = Auth.auth().currentUser else {
                print("No active user found to delete.")
                return
            }
            
            try await user.delete()
        }
}

// MARK: Sign in Email
extension AuthenticationManager {
    @discardableResult
    func createUser(email: String, password: String) async throws -> AuthDataResultModel {
        let authDataResult = try await Auth.auth().createUser(withEmail: email, password: password)
        return AuthDataResultModel(user: authDataResult.user)
    }
    
    @discardableResult
    func signInUser(email: String, password: String) async throws -> AuthDataResultModel {
        let authDataResult = try await Auth.auth().signIn(withEmail: email, password: password)
        return AuthDataResultModel(user: authDataResult.user)
    }
    
    func resetPassword(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
    
    func updatePassword(password: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw URLError(.badServerResponse)
        }
        try await user.updatePassword(to: password)
    }
    
    func updateEmail(email: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw URLError(.badServerResponse)
        }
        try await user.sendEmailVerification(beforeUpdatingEmail: email)
    }
}

// MARK: Sign in SSO
extension AuthenticationManager {
    
    @discardableResult
    func signInWithGoogle(tokens: GoogleSignInResultModel) async throws -> AuthDataResultModel {
        let credential = GoogleAuthProvider.credential(withIDToken: tokens.idToken, accessToken: tokens.accessToken)
        return try await signIn(credential: credential)
    }
    
    @discardableResult
    func signInWithApple(tokens: SignInWithAppleResult) async throws -> AuthDataResultModel {
        let credential = OAuthProvider.appleCredential(
            withIDToken: tokens.token,
            rawNonce: tokens.nonce,
            fullName: nil
        )
        return try await signIn(credential: credential)
    }
    
    func signIn(credential: AuthCredential) async throws -> AuthDataResultModel {
        let authDataResult = try await Auth.auth().signIn(with: credential)
        return AuthDataResultModel(user: authDataResult.user)
    }
}

// MARK: Anonymous Sign In & Linking
extension AuthenticationManager {
    
    @discardableResult
    func signInAnonymously() async throws -> AuthDataResultModel {
        let authDataResult = try await Auth.auth().signInAnonymously()
        return AuthDataResultModel(user: authDataResult.user)
    }
    
    func isUserAnonymous() -> Bool {
        return Auth.auth().currentUser?.isAnonymous ?? false
    }
    
    // 2. LINK OR SIGN IN
        func connectCredential(credential: AuthCredential) async throws -> AuthDataResultModel {
            if let user = Auth.auth().currentUser, user.isAnonymous {
                do {
                    // Attempt to link anonymous data to the new credential
                    let authDataResult = try await user.link(with: credential)
                    return AuthDataResultModel(user: authDataResult.user)
                } catch let error as NSError {
                    
                    if error.domain == AuthErrorDomain, let errorCode = AuthErrorCode(rawValue: error.code) {
                        if errorCode == .credentialAlreadyInUse {
                            
                            // FIREBASE MAGIC: Extract the updated, un-burned credential from the error
                            if let updatedCredential = error.userInfo[AuthErrorUserInfoUpdatedCredentialKey] as? AuthCredential {
                                
                                // Safely sign in using the updated credential Firebase provided
                                let authDataResult = try await Auth.auth().signIn(with: updatedCredential)
                                return AuthDataResultModel(user: authDataResult.user)
                                
                            } else {
                                // Fallback for Google (whose tokens usually survive)
                                let authDataResult = try await Auth.auth().signIn(with: credential)
                                return AuthDataResultModel(user: authDataResult.user)
                            }
                        }
                    }
                    throw error
                }
            } else {
                // Standard sign in if not anonymous
                return try await signIn(credential: credential)
            }
        }
    
    
    // Update existing SSO workflows to route through the linking logic
    @discardableResult
    func linkOrSignInWithGoogle(tokens: GoogleSignInResultModel) async throws -> AuthDataResultModel {
        let credential = GoogleAuthProvider.credential(withIDToken: tokens.idToken, accessToken: tokens.accessToken)
        return try await connectCredential(credential: credential)
    }
    
    @discardableResult
    func linkOrSignInWithApple(tokens: SignInWithAppleResult) async throws -> AuthDataResultModel {
        let credential = OAuthProvider.appleCredential(
            withIDToken: tokens.token,
            rawNonce: tokens.nonce,
            fullName: nil
        )
        return try await connectCredential(credential: credential)
    }
    
    @discardableResult
    func linkWithEmail(email: String, password: String) async throws -> AuthDataResultModel {
        guard let user = Auth.auth().currentUser else {
            throw URLError(.badServerResponse)
        }
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        let authDataResult = try await user.link(with: credential)
        return AuthDataResultModel(user: authDataResult.user)
    }
}


extension AuthenticationManager {
    
    // Returns an array of provider IDs (e.g., ["password", "google.com", "apple.com"])
    func getLinkedProviders() -> [String] {
        guard let providerData = Auth.auth().currentUser?.providerData else { return [] }
        return providerData.map { $0.providerID }
    }
    
    @discardableResult
    func linkGoogle(tokens: GoogleSignInResultModel) async throws -> AuthDataResultModel {
        guard let user = Auth.auth().currentUser else { throw URLError(.badServerResponse) }
        let credential = GoogleAuthProvider.credential(withIDToken: tokens.idToken, accessToken: tokens.accessToken)
        let authDataResult = try await user.link(with: credential)
        return AuthDataResultModel(user: authDataResult.user)
    }
    
    @discardableResult
    func linkApple(tokens: SignInWithAppleResult) async throws -> AuthDataResultModel {
        guard let user = Auth.auth().currentUser else { throw URLError(.badServerResponse) }
        let credential = OAuthProvider.appleCredential(withIDToken: tokens.token, rawNonce: tokens.nonce, fullName: nil)
        let authDataResult = try await user.link(with: credential)
        return AuthDataResultModel(user: authDataResult.user)
    }
}
