import SwiftUI

struct TabBarView: View {
    @Binding var showSignInView: Bool

    var body: some View {
        TabView {

            NavigationStack {
                ProductsView()
            }
            .tabItem {
                Label("Products", systemImage: "cart")
            }

            NavigationStack {
                FavouriteView()
            }
            .tabItem {
                Label("Favourites", systemImage: "star")
            }

            NavigationStack {
                ProfileView(showSignInView: $showSignInView)
            }
            .tabItem {
                Label("Profile", systemImage: "person")
            }
        }
    }
}

#Preview {
    TabBarView(showSignInView: .constant(false))
}
