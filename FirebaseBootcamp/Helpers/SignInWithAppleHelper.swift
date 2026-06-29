
//
//  SignInWithAppleHelper.swift
//  FirebaseBootcamp
//
//  Created by Sagar Jangra on 29/06/2026.
//

import Foundation
import AuthenticationServices
import CryptoKit

struct SignInWithAppleResult {
    let token: String
    let nonce: String
    let name: String?
    let email: String?
}


@MainActor
final class SignInWithAppleHelper: NSObject {
    
    private var currentNonce: String?
    private var continuation: CheckedContinuation<SignInWithAppleResult, Error>?
    
    func signIn() async throws -> SignInWithAppleResult {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            
            let nonce = randomNonceString()
            self.currentNonce = nonce
            
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = sha256(nonce)
            
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()
        }
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        return String(nonce)
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

extension SignInWithAppleHelper: ASAuthorizationControllerDelegate {
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard
            let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let appleIDToken = appleIDCredential.identityToken,
            let idTokenString = String(data: appleIDToken, encoding: .utf8),
            let nonce = currentNonce else {
            continuation?.resume(throwing: URLError(.badServerResponse))
            return
        }
        
        let name = appleIDCredential.fullName?.givenName
        let email = appleIDCredential.email
        
        let tokens = SignInWithAppleResult(token: idTokenString, nonce: nonce, name: name, email: email)
        continuation?.resume(returning: tokens)
        continuation = nil
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}

extension SignInWithAppleHelper: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let window = Utilities.shared.topViewController()?.view.window ?? Utilities.shared.topWindow else {
            fatalError("Could not find a valid window to present Apple Sign In")
        }
        return window
    }
}
