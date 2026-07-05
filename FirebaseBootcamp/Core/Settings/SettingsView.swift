//
//  SettingsView.swift
//  FirebaseBootcamp
//
//  Created by Sagar Jangra on 24/06/2026.
//

import SwiftUI
import Combine


struct SettingsView: View {
    @StateObject private var vm = SettingsViewModel()
    @Binding var showSignInView: Bool
    
    @State private var showLinkEmailSheet: Bool = false
    
    var body: some View {
        List {
            Section("Linked Accounts") {
                
                // 1. Email Provider Check
                if vm.linkedProviders.contains("password") {
                    Text("Email: Connected")
                        .foregroundStyle(.gray)
                } else {
                    Button("Link Email Account") {
                        showLinkEmailSheet = true
                    }
                }
                
                // 2. Google Provider Check
                if vm.linkedProviders.contains("google.com") {
                    Text("Google: Connected")
                        .foregroundStyle(.gray)
                } else {
                    Button("Link Google Account") {
                        Task {
                            do {
                                try await vm.linkGoogleAccount()
                            } catch {
                                print("Failed to link Google: \(error)")
                            }
                        }
                    }
                }
                
                // 3. Apple Provider Check
                if vm.linkedProviders.contains("apple.com") {
                    Text("Apple: Connected")
                        .foregroundStyle(.gray)
                } else {
                    Button("Link Apple Account") {
                        Task {
                            do {
                                try await vm.linkAppleAccount()
                            } catch {
                                print("Failed to link Apple: \(error)")
                            }
                        }
                    }
                }
            }
            
            Section {
                Button("Log out") {
                    Task {
                        do {
                            try vm.signOut()
                            showSignInView = true
                        } catch {
                            print("Error signing out: \(error)")
                        }
                    }
                }
                .foregroundStyle(.red)
                
                Button(role: .destructive) {
                                    Task {
                                        do {
                                            try await vm.deleteAccount()
                                            showSignInView = true
                                        } catch {
                                            print("Error deleting user: \(error)")
                                        }
                                    }
                                } label: {
                                    Text("Delete Account")
                                }
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            vm.loadAuthProviders()
        }
        .sheet(isPresented: $showLinkEmailSheet) {
            LinkEmailView(isPresented: $showLinkEmailSheet) {
                // Refresh the list once the email is successfully linked
                vm.loadAuthProviders()
            }
        }
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
