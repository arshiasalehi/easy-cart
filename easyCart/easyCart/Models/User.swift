//
//  User.swift
//  easyCart
//
//  Created by arshia salehi on 2025-03-12.
//

import Foundation

struct User {
    var id: String
    var name: String
    var email: String
    var isAdmin: Bool
    var phonenumber: Int
    var address: String
    var city: String
    var postalCode: String
    
    init(id: String, name: String, email: String, isAdmin: Bool, phonenumber: Int, address: String, city: String, postalCode: String) {
        self.id = id
        self.name = name
        self.email = email
        self.isAdmin = isAdmin
        self.phonenumber = phonenumber
        self.address = address
        self.city = city
        self.postalCode = postalCode
    }
}
