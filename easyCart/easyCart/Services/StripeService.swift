//
//  FirebaseService.swift
//  easyCart
//
//  Created by arshia salehi on 2025-03-12.
//
import Foundation
import Stripe
import StripePaymentSheet
import UIKit

class StripeService {
    
    static let shared = StripeService()
    private init() {}

    private var paymentSheet: PaymentSheet?

    // MARK: - Step 1: Call Backend and Create PaymentIntent
    func createPaymentIntent(amount: Int, currency: String = "usd", completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "\(stripeBackendURL)/create-payment-intent") else {
            completion(.failure(NSError(domain: "StripeService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid backend URL"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let body: [String: Any] = [
            "amount": amount,
            "currency": currency
        ]

        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "StripeService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data received from server"])))
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let clientSecret = json["clientSecret"] as? String {
                    completion(.success(clientSecret))
                } else {
                    completion(.failure(NSError(domain: "StripeService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    // MARK: - Step 2: Prepare PaymentSheet
    func preparePaymentSheet(amount: Int, completion: @escaping (Error?) -> Void) {
        createPaymentIntent(amount: amount) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let clientSecret):
                    var config = PaymentSheet.Configuration()
                    config.merchantDisplayName = "EasyCart 🍎"
                    config.applePay = .init(merchantId: "your.merchant.id", merchantCountryCode: "CA")
                    self.paymentSheet = PaymentSheet(paymentIntentClientSecret: clientSecret, configuration: config)
                    completion(nil)
                case .failure(let error):
                    completion(error)
                }
            }
        }
    }

    // MARK: - Step 3: Present PaymentSheet
    func presentPaymentSheet(from viewController: UIViewController, completion: @escaping (PaymentSheetResult) -> Void) {
        guard let sheet = self.paymentSheet else {
            print("⚠️ PaymentSheet is not ready.")
            return
        }

        sheet.present(from: viewController, completion: completion)
    }
}
