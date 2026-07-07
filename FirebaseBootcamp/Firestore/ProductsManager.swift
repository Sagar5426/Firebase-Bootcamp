//
//  ProductsManager.swift
//  FirebaseBootcamp
//
//  Created by Sagar Jangra on 07/07/2026.
//

import Foundation
import FirebaseFirestore


final class ProductsManager {
    
    static let shared = ProductsManager()
    private init() {}
    
    private let productsCollection = Firestore.firestore().collection("products")
    private func productDocument(productId : String) -> DocumentReference{
        productsCollection.document(productId)
    }
    
    func uploadProduct(product: Product) async throws {
        try productDocument(productId: String(product.id)).setData(from: product, merge: false)
    }
    
    func getProduct(productId: String) async throws -> Product {
        try await productDocument(productId: productId).getDocument(as: Product.self)
    }
    
    func getAllProducts() async throws -> [Product] {
        try await productsCollection.getDocuments(as: Product.self)
    }
    
}

extension Query {
    // A generic func
    func getDocuments<T>(as type: T.Type) async throws -> [T] where T: Decodable {
        let snapshot = try await self.getDocuments()
        return try snapshot.documents.map { document in
            try document.data(as: T.self)
        }
    }
}
