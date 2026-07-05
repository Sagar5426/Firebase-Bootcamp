//
//  LinkEmailView.swift
//  FirebaseBootcamp
//
//  Created by Sagar Jangra on 29/06/2026.
//


import SwiftUI

struct LinkEmailView: View {
    @Binding var isPresented: Bool
    var onLinkCompleted: () -> Void
    
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    
                    SecureField("Password", text: $password)
                } footer: {
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
                
                Button {
                    Task {
                        do {
                            try await AuthenticationManager.shared.linkWithEmail(email: email, password: password)
                            onLinkCompleted()
                            isPresented = false
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                } label: {
                    Text("Link Account")
                        .frame(maxWidth: .infinity)
                        .bold()
                }
                .disabled(email.isEmpty || password.isEmpty)
            }
            .navigationTitle("Link Email")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}