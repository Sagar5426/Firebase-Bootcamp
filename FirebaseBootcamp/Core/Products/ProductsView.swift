//
//  ProductsView.swift
//  FirebaseBootcamp
//
//  Created by Sagar Jangra on 07/07/2026.
//

import SwiftUI
import Combine
import FirebaseFirestore

@MainActor
final class ProductsViewModel: ObservableObject {
    
    @Published private(set) var products: [Product] = []
    @Published var selectedFilter: FilterOption? = nil
    @Published var selectedCategory: CategoryOption? = nil
    private var lastDocument: DocumentSnapshot? = nil
    
//    func getAllProducts() async throws {
//        self.products = try await ProductsManager.shared.getAllProducts()
//    }
    
    // MARK: Filter
    enum FilterOption: String, CaseIterable {
        case noFilter
        case priceHigh
        case priceLow
        
        var priceDescending: Bool? {
            switch self {
            case .noFilter: nil
            case .priceHigh: true
            case .priceLow: false
            }
        }
    }
    
    func filterSelected(option: FilterOption) async throws {
        self.selectedFilter = option
        self.products = []
        self.lastDocument = nil
        self.getProducts()
    }
    
    // MARK: Category
    enum CategoryOption: String, CaseIterable {
        case noCategory
        case furniture
        case beauty
        case fragrances
        case groceries
        
        var categoryKey: String? {
            if self == .noCategory {
                return nil
            }
            return self.rawValue
        }
    }
    
    func categorySelected(option: CategoryOption) async throws {
        self.selectedCategory = option
        self.products = []
        self.lastDocument = nil
        self.getProducts()
    }
    
    func getProducts()  {
        Task {
            let (newProducts, lastDocument) = try await ProductsManager.shared.getAllProducts(priceDescending: selectedFilter?.priceDescending, forCategory: selectedCategory?.categoryKey, count: 10, lastDocument: lastDocument)
            
            self.products.append(contentsOf: newProducts)
            if let lastDocument {
                self.lastDocument = lastDocument
            }
        }
    }
    
    func addUserFavourite(productId: Int) {
        Task {
            let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()
            try? await UserManager.shared.addUserFavouriteProduct(userId: authDataResult.uid, productId: productId)
        }
    }
    
//    func getProductsByRating() {
//        Task {
//            let (newProducts, lastDocument) = try await ProductsManager.shared.getProductsByRating(count: 3, lastDocument: lastDocument)
//            self.products.append(contentsOf: newProducts)
//            self.lastDocument = lastDocument
//        }
//    }
    
    
}

struct ProductsView: View {
    @StateObject private var vm = ProductsViewModel()
    var body: some View {
        List {
            
            ForEach(vm.products) { product in
                ProductCellView(product: product)
                    .contextMenu {
                        Button("Add to favourites") {
                            vm.addUserFavourite(productId: product.id)
                        }
                    }
                
                if product == vm.products.last {
                    ProgressView()
                        .onAppear {
                            vm.getProducts()
                        }
                }
            }
        }
        .navigationTitle("Products")
        .toolbar(content: {
            ToolbarItem(placement: .topBarLeading) {
                Menu("Filter: \(vm.selectedFilter?.rawValue ?? "None")") {
                    ForEach(ProductsViewModel.FilterOption.allCases, id: \.self) { option in
                        Button(option.rawValue) {
                            Task {
                                try? await vm.filterSelected(option: option)
                            }
                        }
                    }
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Menu("Category: \(vm.selectedCategory?.rawValue ?? "None")") {
                    ForEach(ProductsViewModel.CategoryOption.allCases, id: \.self) { option in
                        Button(option.rawValue) {
                            Task {
                                try? await vm.categorySelected(option: option)
                            }
                        }
                    }
                }
            }
        })
        .task {
            vm.getProducts()
        }
    }
}

#Preview {
    NavigationStack {
        ProductsView()
    }
}
