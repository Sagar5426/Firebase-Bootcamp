//
//  ProductsView.swift
//  FirebaseBootcamp
//
//  Created by Sagar Jangra on 07/07/2026.
//

import SwiftUI
import Combine

@MainActor
final class ProductsViewModel: ObservableObject {
    
    @Published private(set) var products: [Product] = []
    
    func getAllProducts() async throws {
        self.products = try await ProductsManager.shared.getAllProducts()
    }

}

struct ProductsView: View {
    @StateObject private var vm = ProductsViewModel()
    var body: some View {
        List {
            ForEach(vm.products) { product in
                ProductCellView(product: product)
            }
        }
        .navigationTitle("Products")
        .task {
            try? await vm.getAllProducts()
        }
    }
}

#Preview {
    ProductsView()
}
