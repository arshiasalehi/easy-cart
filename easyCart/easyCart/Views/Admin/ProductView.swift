//
//  FirebaseService.swift
//  easyCart
//
//  Created by arshia salehi on 2025-03-12.
//
import SwiftUI

struct ProductView: View {
    @State private var productName = ""
    @State private var price: Double = 0.0
    @State private var small = 0
    @State private var medium = 0
    @State private var large = 0
    @State private var imageUrl: String? = nil
    @State private var isUploading = false
    @State private var products: [Product] = []
    @State private var isLoading = true

    let firebaseProduct = FirebaseProduct()

    var body: some View {
        VStack {
            AddProductBox(
                productName: $productName,
                price: $price,
                small: $small,
                medium: $medium,
                large: $large,
                imageUrl: $imageUrl,
                isUploading: $isUploading
            )
            .padding(.top)

            Divider()
                .padding(.horizontal)

            if isLoading {
                ProgressView("Loading products...")
                    .padding()
            } else if products.isEmpty {
                Text("No products found.")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(products, id: \.id) { product in
                            UpdateProductView(
                                productId: product.id,
                                productName: product.name,
                                price: String(product.price),
                                selectedQuantity: product.small, // Default to small
                                imageUrl: product.imageUrl
                            )
                        }
                    }
                    .padding(.bottom)
                }
            }
        }
        .onAppear {
            fetchProducts()
        }
    }

    private func fetchProducts() {
        print("[ProductView] Starting product fetch...")
        isLoading = true
        firebaseProduct.fetchProducts { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let products):
                    self.products = products
                    print("[ProductView] Products fetched: \(products.count)")
                case .failure(let error):
                    print("❌ [ProductView] Error: \(error.localizedDescription)")
                }
                isLoading = false
            }
        }
    }
}

struct ProductView_Previews: PreviewProvider {
    static var previews: some View {
        ProductView()
    }
}
