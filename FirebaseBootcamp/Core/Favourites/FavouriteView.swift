//
//  FavouriteView.swift
//  FirebaseBootcamp
//
//  Created by Sagar Jangra on 13/07/2026.
//

import SwiftUI
import Combine
import FirebaseFirestore

@MainActor final class FavouriteViewModel: ObservableObject{
    @Published private(set) var userFavoriteProducts: [UserFavouriteProduct] = []
    
    func getFavourites() {
        Task {
            let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()
            self.userFavoriteProducts = try await UserManager.shared.getAllUserFavouriteProducts(userId: authDataResult.uid)
            
        }
    }
    
    func removeFromFavourites(favouriteProductId: String) {
        Task {
            let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()
            try await UserManager.shared.removeUserFavouriteProduct(userId: authDataResult.uid, favouriteProductId: favouriteProductId)
            getFavourites()
        }
    }
}

struct FavouriteView: View {
    @StateObject private var vm = FavouriteViewModel()
    
    var body: some View {
        List {
            ForEach(vm.userFavoriteProducts, id: \.id.self) { item in
                ProductCellViewBuilder(productId: String(item.productId))
                    .contextMenu {
                        Button("Remove from favourites") {
                            vm.removeFromFavourites(favouriteProductId: item.id)
                        }
                    }
            }
        }
        .navigationTitle("Favourites")
        .onAppear {
            vm.getFavourites()
        }
    }
}

#Preview {
    NavigationStack {
        FavouriteView()
    }
}
