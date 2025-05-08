//
//  FirebaseService.swift
//  easyCart
//
//  Created by arshia salehi on 2025-03-12.
//
import Foundation

struct CartItem: Identifiable {
    let id: String                  // Firestore document ID = cartItemId
    var cartItemId: String          // Also store cartItemId in Firestore field
    var productName: String
    var price: Double
    var size: String
    var quantity: Int
    var imageUrl: String?
    var timestamp: Date?
    
    init(id: String = UUID().uuidString,
         cartItemId: String,
         productName: String,
         price: Double,
         size: String,
         quantity: Int,
         imageUrl: String? = nil,
         timestamp: Date? = nil) {
        
        self.id = id
        self.cartItemId = cartItemId
        self.productName = productName
        self.price = price
        self.size = size
        self.quantity = quantity
        self.imageUrl = imageUrl
        self.timestamp = timestamp
    }
}
