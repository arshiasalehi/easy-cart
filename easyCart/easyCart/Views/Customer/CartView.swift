//
//  FirebaseService.swift
//  easyCart
//
//  Created by arshia salehi on 2025-03-12.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Stripe

struct CartView: View {
    @State private var cartItems: [CartItem] = []
    @State private var isLoading: Bool = true
    @State private var successMessage: String? = nil

    private var totalAmount: Double {
        cartItems.reduce(0) { $0 + ($1.price * Double($1.quantity)) }
    }

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(cartItems) { cartItem in
                            CheckoutProductBox(
                                cartItemId: .constant(cartItem.id),
                                productName: .constant(cartItem.productName),
                                price: .constant(cartItem.price),
                                size: .constant(cartItem.size),
                                quantity: .constant(cartItem.quantity),
                                imageUrl: .constant(cartItem.imageUrl)
                            )
                        }

                        // ✅ Total Section
                        HStack {
                            Text("Total:")
                                .font(.headline)
                            Spacer()
                            Text("$\(totalAmount, specifier: "%.2f")")
                                .font(.headline)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 2)

                        // ✅ Checkout Button
                        Button(action: handleCheckout) {
                            Text("Checkout")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.top, 10)

                        // ✅ Success Feedback
                        if let message = successMessage {
                            Text(message)
                                .foregroundColor(.green)
                                .font(.caption)
                                .padding(.top, 4)
                                .transition(.opacity)
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            loadCartItems()
        }
    }

    private func handleCheckout() {
        print("🛒 Checkout tapped with total $\(totalAmount)")
        let totalInCents = Int(totalAmount * 100)

        StripeService.shared.preparePaymentSheet(amount: totalInCents) { error in
            if let error = error {
                print("❌ Failed to prepare payment: \(error.localizedDescription)")
            } else if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let rootVC = windowScene.windows.first?.rootViewController {
                StripeService.shared.presentPaymentSheet(from: rootVC) { result in
                    switch result {
                    case .completed:
                        print("✅ Payment successful!")
                        FirebaseCartManager.shared.saveOrder(items: cartItems, totalAmount: totalAmount) { result in
                            switch result {
                            case .success(let message):
                                print(message)
                                successMessage = "✅ Payment successful! Order saved."
                                cartItems = [] // Clear the cart visually
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    successMessage = nil
                                }
                            case .failure(let error):
                                print("❌ Failed to save order: \(error.localizedDescription)")
                            }
                        }
                    case .canceled:
                        print("❌ Payment canceled.")
                    case .failed(let error):
                        print("💥 Payment failed: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    private func loadCartItems() {
        FirebaseCartManager.shared.fetchCartItems { result in
            switch result {
            case .success(let items):
                cartItems = items
            case .failure(let error):
                print("❌ Error fetching cart items: \(error.localizedDescription)")
            }
            isLoading = false
        }
    }
}

struct CartView_Previews: PreviewProvider {
    static var previews: some View {
        CartView()
    }
}
