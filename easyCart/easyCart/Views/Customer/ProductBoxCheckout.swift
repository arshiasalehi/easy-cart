//
//  FirebaseService.swift
//  easyCart
//
//  Created by arshia salehi on 2025-03-12.
//
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct CheckoutProductBox: View {
    @Binding var cartItemId: String
    @Binding var productName: String
    @Binding var price: Double
    @Binding var size: String
    @Binding var quantity: Int
    @Binding var imageUrl: String?

    @State private var quantityText: String = ""

    private var itemTotalPrice: Double {
        price * Double(quantity)
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 15) {
                // Product Image
                VStack {
                    if let imageUrl = imageUrl, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 70, height: 70)
                                    .cornerRadius(10)
                            case .failure:
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 70, height: 70)
                                    .cornerRadius(10)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 70, height: 70)
                            .cornerRadius(10)
                    }
                }

                // Product Info
                VStack(alignment: .leading, spacing: 10) {
                    Text(productName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Size: \(size)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("$\(price, specifier: "%.2f")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Quantity Update
                VStack {
                    TextField("Quantity", text: $quantityText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .frame(width: 60)
                        .padding(.bottom, 5)

                    Button(action: {
                        if let newQuantity = Int(quantityText), newQuantity > 0 {
                            print("🔁 Update button tapped. New quantity: \(newQuantity) for \(productName) (\(size))")
                            FirebaseCartManager.shared.updateQuantityInCart(cartItemId: cartItemId, newQuantity: newQuantity)
                            quantity = newQuantity
                        } else {
                            print("❌ Invalid quantity entered: \(quantityText)")
                        }
                    }) {
                        Text("Update")
                            .font(.caption)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                }
            }

            // Total + Delete
            HStack {
                VStack {
                    Text("$\(itemTotalPrice, specifier: "%.2f")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack {
                    Button(action: {
                        print("🗑 Delete tapped for \(cartItemId)")
                        deleteProductFromCart()
                    }) {
                        Text("Delete")
                            .font(.headline)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top, 10)
                }
            }
        }
        .frame(width: 330, height: 150)
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
        .onAppear {
            quantityText = String(quantity)
        }
    }

    private func deleteProductFromCart() {
        FirebaseCartManager.shared.deleteFromCart(cartItemId: cartItemId) { result in
            switch result {
            case .success(let message):
                print(message)
            case .failure(let error):
                print("❌ Error deleting product: \(error.localizedDescription)")
            }
        }
    }
}

// ✅ Working Preview
struct CheckoutProductView: View {
    @State private var cartItemId = "12345_Medium"
    @State private var productName = "Sample Product"
    @State private var price: Double = 19.99
    @State private var size = "Medium"
    @State private var quantity = 1
    @State private var imageUrl: String? = "https://via.placeholder.com/150"

    var body: some View {
        CheckoutProductBox(
            cartItemId: $cartItemId,
            productName: $productName,
            price: $price,
            size: $size,
            quantity: $quantity,
            imageUrl: $imageUrl
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

struct CheckoutProductBox_Previews: PreviewProvider {
    static var previews: some View {
        CheckoutProductView()
    }
}
