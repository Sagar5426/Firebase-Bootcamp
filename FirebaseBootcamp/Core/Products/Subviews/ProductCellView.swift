//
//  ProductCellView.swift
//  FirebaseBootcamp
//
//  Created by Sagar Jangra on 08/07/2026.
//

import SwiftUI

struct ProductCellView: View {
    let product: Product
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            
            AsyncImage(url: URL(string: product.thumbnail ?? "")) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 75, height: 75)
                    .cornerRadius(10)
            } placeholder: {
                ProgressView()
            }
            .frame(width: 75, height: 75)
            .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
            
            VStack(alignment: .leading) {
                Text(product.title ?? "n/a")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("Price: $" + String(product.price ?? 0))
                Text("Rating: " + String(product.rating ?? 0))
                Text("Category: " + String(product.category ?? "n/a"))
                Text("Brand: " + String(product.brand ?? "n/a"))
                
            }
            .font(.callout)
            .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ProductCellView(product: Product(id: 1, title: "test", description: "test", price: 400, discountPercentage: 11, rating: 4, stock: 699, brand: "test", category: "test", thumbnail: "test", images: []))
}
