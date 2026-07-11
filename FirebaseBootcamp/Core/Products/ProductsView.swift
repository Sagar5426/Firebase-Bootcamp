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
    @Published var selectedFilter: FilterOption? = nil
    @Published var selectedCategory: CategoryOption? = nil
    
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
        try await self.getProducts()
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
        try await self.getProducts()
    }
    
    func getProducts() async throws {
        self.products = try await ProductsManager.shared.getAllProducts(priceDescending: selectedFilter?.priceDescending, forCategory: selectedCategory?.categoryKey)
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
            try? await vm.getProducts()
        }
    }
}

#Preview {
    NavigationStack {
        ProductsView()
    }
}
