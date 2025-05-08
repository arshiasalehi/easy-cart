//
//  ShoppingView.swift
//  easyCart
//
//  Created by arshia salehi on 2025-03-12.
//

import SwiftUI

struct ShoppingView: View {
    @State private var products: [Product] = []
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 0) {
            Text("Shop!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)

            if isLoading {
                ProgressView("Loading...")
                    .padding(.top, 40)
            } else {
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach($products) { $product in
                            ShopProductBox(
                                productName: $product.name,
                                price: $product.price,
                                small: $product.small,
                                medium: $product.medium,
                                large: $product.large,
                                imageUrl: $product.imageUrl,
                                productId: product.id
                            )
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
                .background(Color(.systemGroupedBackground))
            }

            Spacer()
        }
        .onAppear {
            loadProducts()
        }
    }

    private func loadProducts() {
        FirebaseCartManager.shared.fetchProducts { result in
            switch result {
            case .success(let products):
                self.products = products
            case .failure(let error):
                print("Error fetching products: \(error.localizedDescription)")
            }
            self.isLoading = false
        }
    }
}

struct ShoppingView_Previews: PreviewProvider {
    static var previews: some View {
        ShoppingView()
    }
}
