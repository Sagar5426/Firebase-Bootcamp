//
//  ProductCellViewBuilder.swift
//  FirebaseBootcamp
//
//  Created by Sagar Jangra on 14/07/2026.
//

import SwiftUI

struct ProductCellViewBuilder: View {
    let productId: String
    @State private var product: Product? = nil
    
    var body: some View {
        ZStack {
            if let product {
                ProductCellView(product: product)
            }
        }
        .task {
            self.product = try? await ProductsManager.shared.getProduct(productId: productId)
        }
    }
}

#Preview {
    ProductCellViewBuilder(productId: "1")
}
