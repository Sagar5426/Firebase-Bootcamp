import SwiftUI
import FirebaseAuth

struct RootView: View {
    @State private var showSignInView: Bool = true
    
    var body: some View {
        ZStack {
            if !showSignInView {
                NavigationStack {
                    SettingsView(showSignInView: $showSignInView)
                }
            }
        }
        .onAppear {
            let currentUser = Auth.auth().currentUser
            
            if currentUser == nil {
                // 1. No user exists: Create a background anonymous ID
                Task {
                    try? await AuthenticationManager.shared.signInAnonymously()
                }
                self.showSignInView = true
                
            } else if currentUser?.isAnonymous == true {
                // 2. User exists but is anonymous: Show login screen to force linking
                self.showSignInView = true
                
            } else {
                // 3. User is fully authenticated: Proceed to the planner
                self.showSignInView = false
            }
        }
        .fullScreenCover(isPresented: $showSignInView) {
            NavigationStack {
                AuthenticationView(showSignInView: $showSignInView)
            }
        }
    }
}

#Preview {
    RootView()
}
