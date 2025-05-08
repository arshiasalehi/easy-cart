//
//  FirebaseService.swift
//  easyCart
//
//  Created by arshia salehi on 2025-03-12.
//
import SwiftUI

struct ShopProductBox: View {
    @Binding var productName: String
    @Binding var price: Double
    @Binding var small: Int
    @Binding var medium: Int
    @Binding var large: Int
    @Binding var imageUrl: String?
    
    @State private var selectedSize: String = "Small"
    var productId: String

    private var selectedQuantity: Int {
        switch selectedSize {
        case "Small": return small
        case "Medium": return medium
        case "Large": return large
        default: return small
        }
    }

    private var isOutOfStock: Bool {
        small + medium + large == 0
    }

    var body: some View {
        VStack(spacing: 10) {
            VStack {
                if let imageUrl = imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image.resizable()
                                .scaledToFill()
                                .frame(width: 250, height: 180)
                                .cornerRadius(30)
                        case .failure:
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 250, height: 180)
                                .cornerRadius(30)
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 250, height: 180)
                        .cornerRadius(30)
                }
            }

            HStack(spacing: 15) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(productName)
                        .font(.headline)

                    Text("$\(price, specifier: "%.2f")")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }

            Text("Selected Size: \(selectedSize)")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 10) {
                ForEach(["Small", "Medium", "Large"], id: \.self) { size in
                    Button(action: {
                        selectedSize = size
                        print("🔲 Size selected: \(size)")
                    }) {
                        Text(size.prefix(1))
                            .font(.headline)
                            .foregroundColor(selectedSize == size ? .white : .black)
                            .frame(width: 40, height: 40)
                            .background(selectedSize == size ? Color.blue : Color.gray.opacity(0.3))
                            .clipShape(Circle())
                    }
                    .disabled(quantityFor(size: size) == 0)
                    .opacity(quantityFor(size: size) == 0 ? 0.5 : 1.0)
                }
            }

            Button {
                addToCart()
            } label: {
                Text("Add to Cart")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isOutOfStock ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(isOutOfStock)
        }
        .frame(width: 350, height: 370)
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
    }

    private func addToCart() {
        print("🛒 Added \(productName) (Size: \(selectedSize)) to cart")
        FirebaseCartManager.shared.addToCart(
            productId: productId,
            productName: productName,
            price: price,
            selectedSize: selectedSize,
            quantity: 1,
            imageUrl: imageUrl
        ) { result in
            switch result {
            case .success(let message):
                print(message)
            case .failure(let error):
                print("❌ Failed to add product to cart: \(error.localizedDescription)")
            }
        }
    }

    private func quantityFor(size: String) -> Int {
        switch size {
        case "Small": return small
        case "Medium": return medium
        case "Large": return large
        default: return 0
        }
    }
}

// ✅ Working Preview
struct ShopProductBoxView: View {
    @State private var productName = "Sample Product"
    @State private var price: Double = 12.99
    @State private var small = 0
    @State private var medium = 0
    @State private var large = 0
    @State private var imageUrl: String? = "https://via.placeholder.com/150"
    @State private var productId = "123456789"

    var body: some View {
        ShopProductBox(
            productName: $productName,
            price: $price,
            small: $small,
            medium: $medium,
            large: $large,
            imageUrl: $imageUrl,
            productId: productId
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

struct ShopProductBoxView_Previews: PreviewProvider {
    static var previews: some View {
        ShopProductBoxView()
    }
}
