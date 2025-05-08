//
//  FirebaseService.swift
//  easyCart
//
//  Created by arshia salehi on 2025-03-12.
//
import Foundation

struct Order {
    var id: String
    var userId: String
    var items: [CartItem]
    var totalAmount: Double
    var timestamp: Date
    
    init(id: String, userId: String, items: [CartItem], totalAmount: Double, timestamp: Date) {
        self.id = id
        self.userId = userId
        self.items = items
        self.totalAmount = totalAmount
        self.timestamp = timestamp
    }
    
    

}
