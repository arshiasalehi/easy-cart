//
//  FirebaseService.swift
//  easyCart
//
//  Created by arshia salehi on 2025-03-12.
//
import Foundation

// Product model with necessary fields
struct Product: Identifiable {
    let id: String // Unique identifier for each product
    var name: String // Name of the product
    var price: Double // Price of the product
    var imageUrl: String? // URL of the product image
    var small: Int // Quantity for Small size
    var medium: Int // Quantity for Medium size
    var large: Int // Quantity for Large size


    // Initializer for Product
    init(id: String = UUID().uuidString, name: String, price: Double, imageUrl: String? = nil, small: Int = 0, medium: Int = 0, large: Int = 0) {
        self.id = id
        self.name = name
        self.price = price
        self.imageUrl = imageUrl
        self.small = small
        self.medium = medium
        self.large = large
    }
}

