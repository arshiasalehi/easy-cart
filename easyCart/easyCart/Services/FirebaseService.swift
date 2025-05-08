//
//  FirebaseService.swift
//  easyCart
//
//  Created by arshia salehi on 2025-03-12.
//
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import UIKit

class FirebaseAuthService {
    
    static let shared = FirebaseAuthService()
    let db = Firestore.firestore()
    
    private init() {}

    // Sign Up Function
    func signUp(email: String, password: String, isAdmin: Bool, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
            } else if let user = result?.user {
                let newUser = User(id: user.uid, name: "", email: email, isAdmin: isAdmin, phonenumber: 0, address: "", city: "", postalCode: "")
                
                self.db.collection("users").document(user.uid).setData([
                    "name": newUser.name,
                    "email": newUser.email,
                    "isAdmin": newUser.isAdmin,
                    "phonenumber": newUser.phonenumber,
                    "address": newUser.address,
                    "city": newUser.city,
                    "postalCode": newUser.postalCode
                ]) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(newUser))
                    }
                }
            }
        }
    }
    
    // Login Function
    func login(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
            } else if let user = result?.user {
                self.db.collection("users").document(user.uid).getDocument { snapshot, error in
                    if let error = error {
                        completion(.failure(error))
                    } else if let data = snapshot?.data() {
                        let fetchedUser = User(
                            id: user.uid,
                            name: data["name"] as? String ?? "",
                            email: data["email"] as? String ?? "",
                            isAdmin: data["isAdmin"] as? Bool ?? false,
                            phonenumber: data["phonenumber"] as? Int ?? 0,
                            address: data["address"] as? String ?? "",
                            city: data["city"] as? String ?? "",
                            postalCode: data["postalCode"] as? String ?? ""
                        )
                        completion(.success(fetchedUser))
                    } else {
                        completion(.failure(NSError(domain: "UserNotFound", code: 404, userInfo: nil)))
                    }
                }
            }
        }
    }

    // Reset Password
    func resetPassword(email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    // Sign Out
    func signOut(completion: @escaping (Error?) -> Void) {
        do {
            try Auth.auth().signOut()
            completion(nil)
            
        } catch let error {
            completion(error)
        }
    }
    
}

class FirebaseUserInfo {
    
    static let shared = FirebaseUserInfo()
    private let db = Firestore.firestore()

    private init() {}

    func fetchUserData(completion: @escaping (Result<[String: Any], Error>) -> Void) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userID).getDocument { document, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = document?.data() {
                completion(.success(data))
            } else {
                completion(.failure(NSError(domain: "UserNotFound", code: 404, userInfo: nil)))
            }
        }
    }

    func updateUserData(_ data: [String: Any], completion: @escaping (Error?) -> Void) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userID).updateData(data) { error in
            completion(error)
        }
    }
}
    
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

class FirebaseProduct {
    private let firestore = Firestore.firestore()
    private let storage = Storage.storage().reference()
    private let auth = Auth.auth()

    static let shared = FirebaseProduct()

    // Function to add a new product
    func addProduct(product: Product, image: UIImage?, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = auth.currentUser?.uid else {
            completion(.failure(NSError(domain: "FirebaseAuth", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }

        let userProductRef = firestore.collection("users").document(userId).collection("products").document(product.id)
        let globalProductRef = firestore.collection("products").document(product.id)

        if let image = image {
            uploadProductImage(userId: userId, productId: product.id, image: image) { result in
                switch result {
                case .success(let imageUrl):
                    var newProduct = product
                    newProduct.imageUrl = imageUrl
                    self.saveProductData(userProductRef: userProductRef, globalProductRef: globalProductRef, userId: userId, product: newProduct, completion: completion)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } else {
        
            saveProductData(userProductRef: userProductRef, globalProductRef: globalProductRef, userId: userId, product: product, completion: completion)
        }
    }

    // Uploads product image to Firebase Storage
    private func uploadProductImage(userId: String, productId: String, image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "ImageError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image"])))
            return
        }

        let imageRef = storage.child("users/\(userId)/products/\(productId).jpg")
        imageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                completion(.failure(error))
                return
            }


            imageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                } else if let url = url {
                    completion(.success(url.absoluteString))
                }
            }
        }
    }
    
    // Saves product data to Firestore in two locations
    private func saveProductData(userProductRef: DocumentReference, globalProductRef: DocumentReference, userId: String, product: Product, completion: @escaping (Result<Void, Error>) -> Void) {
        let productData: [String: Any] = [
            "id": product.id, // Storing ID to track products
            "name": product.name,
            "price": product.price,
            "small": product.small,
            "medium": product.medium,
            "large": product.large,
            "imageUrl": product.imageUrl ?? "",
            "userId": userId, // Track which user owns this product
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]

        let userProductData: [String: Any] = [
            "id": product.id // Only store the product ID in the user's collection
        ]

        let batch = firestore.batch()
        batch.setData(userProductData, forDocument: userProductRef)
        batch.setData(productData, forDocument: globalProductRef)

        batch.commit { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

}
extension FirebaseProduct {

    // Fetch Products from Firestore
    func fetchProducts(completion: @escaping (Result<[Product], Error>) -> Void) {
        guard let userId = auth.currentUser?.uid else {
            completion(.failure(NSError(domain: "FirebaseAuth", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }

        let userProductsRef = firestore.collection("users").document(userId).collection("products")

        userProductsRef.getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            var products: [Product] = []
            let group = DispatchGroup()

            for document in snapshot?.documents ?? [] {
                let productId = document.documentID
                let productRef = self.firestore.collection("products").document(productId)

                group.enter()
                productRef.getDocument { productDoc, error in
                    defer { group.leave() }

                    if let error = error {
                        print("[fetchProducts] Error fetching product details: \(error.localizedDescription)")
                        return
                    }

                    if let productData = productDoc?.data() {
                        let product = Product(
                            id: productData["id"] as? String ?? "",
                            name: productData["name"] as? String ?? "",
                            price: productData["price"] as? Double ?? 0.0,
                            imageUrl: productData["imageUrl"] as? String,
                            small: productData["small"] as? Int ?? 0,
                            medium: productData["medium"] as? Int ?? 0,
                            large: productData["large"] as? Int ?? 0
                        )
                        products.append(product)
                        print("[fetchProducts] Fetched product: \(product.name)")  // Debugging print statement
                    }
                }
            }

            group.notify(queue: .main) {
                print("[fetchProducts] Total products fetched: \(products.count)")  // Debugging print statement
                completion(.success(products))
            }
        }
    }

    // Update Product with Optional Image
    func updateProduct(productId: String, updatedData: [String: Any], newImage: UIImage?, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = auth.currentUser?.uid else {
            completion(.failure(NSError(domain: "FirebaseAuth", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }

        let userProductRef = firestore.collection("users").document(userId).collection("products").document(productId)
        let globalProductRef = firestore.collection("products").document(productId)

        if let newImage = newImage {
            // Upload the new image to Firebase Storage and update the product's image URL
            uploadProductImage(userId: userId, productId: productId, image: newImage) { result in
                switch result {
                case .success(let imageUrl):
                    var updatedDataWithImage = updatedData
                    updatedDataWithImage["imageUrl"] = imageUrl

                    let batch = self.firestore.batch()
                    batch.updateData(updatedDataWithImage, forDocument: globalProductRef)

                    batch.commit { error in
                        if let error = error {
                            print("❌ Error updating product: \(error.localizedDescription)")
                            completion(.failure(error))
                        } else {
                            print("✅ Product \(productId) updated successfully.")
                            completion(.success(()))
                        }
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } else {
            let batch = firestore.batch()
            batch.updateData(updatedData, forDocument: globalProductRef)

            batch.commit { error in
                if let error = error {
                    print("❌ Error updating product: \(error.localizedDescription)")
                    completion(.failure(error))
                } else {
                    print("✅ Product \(productId) updated successfully.")
                    completion(.success(()))
                }
            }
        }
    }

    // Delete Product and its Image
    func deleteProduct(productId: String, imageUrl: String?, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = auth.currentUser?.uid else {
            completion(.failure(NSError(domain: "FirebaseAuth", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }

        let userProductRef = firestore.collection("users").document(userId).collection("products").document(productId)
        let globalProductRef = firestore.collection("products").document(productId)

        let batch = firestore.batch()
        batch.deleteDocument(userProductRef)
        batch.deleteDocument(globalProductRef)

        batch.commit { error in
            if let error = error {
                print("❌ Error deleting product: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            print("✅ Product \(productId) deleted successfully.")

            // If the product has an associated image URL, delete the image from Firebase Storage
            if let imageUrl = imageUrl {
                let storageRef = Storage.storage().reference(forURL: imageUrl)
                storageRef.delete { imageError in
                    if let imageError = imageError {
                        print("⚠️ Image deletion failed: \(imageError.localizedDescription)")
                    } else {
                        print("🗑 Image deleted successfully.")
                    }
                }
            }

            completion(.success(()))
        }
    }
}
import Foundation
import FirebaseFirestore
import FirebaseAuth

class FirebaseCartManager {
    
    static let shared = FirebaseCartManager()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // Add to cart function
    func addToCart(productId: String,
                   productName: String,
                   price: Double,
                   selectedSize: String,
                   quantity: Int = 1,
                   imageUrl: String? = nil,
                   completion: @escaping (Result<String, Error>) -> Void) {
        
        let cartItemId = "\(productId)_\(selectedSize)"
        
        print("🛒 Adding product to Firestore: \(productName) (Size: \(selectedSize))")
        
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in."])))
            return
        }
        
        print("✅ User ID for cart: \(userId)")
        print("📦 Document ID used for cart: \(cartItemId)")
        
        let cartRef = db.collection("users")
            .document(userId)
            .collection("cart")
            .document(cartItemId)
        
        var cartData: [String: Any] = [
            "cartItemId": cartItemId,
            "productName": productName,
            "price": price,
            "size": selectedSize,
            "quantity": quantity,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        if let imageUrl = imageUrl {
            cartData["imageUrl"] = imageUrl
        }
        
        cartRef.setData(cartData, merge: true) { error in
            if let error = error {
                print("❌ Error adding to cart in Firestore: \(error.localizedDescription)")
                completion(.failure(error))
            } else {
                print("✅ Product successfully added to cart at path: users/\(userId)/cart/\(cartItemId)")
                completion(.success("✅ \(productName) (\(selectedSize)) added to cart!"))
            }
        }
    }
    
    func fetchProducts(completion: @escaping (Result<[Product], Error>) -> Void) {
        let db = Firestore.firestore()
        db.collection("products").getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            var products: [Product] = []
            for document in snapshot?.documents ?? [] {
                let data = document.data()
                let product = Product(
                    id: document.documentID,
                    name: data["name"] as? String ?? "",
                    price: data["price"] as? Double ?? 0.0,
                    imageUrl: data["imageUrl"] as? String,
                    small: data["small"] as? Int ?? 0,
                    medium: data["medium"] as? Int ?? 0,
                    large: data["large"] as? Int ?? 0
                )
                products.append(product)
            }
            
            completion(.success(products))
        }
    }
    
   
    func fetchCartItems(completion: @escaping (Result<[CartItem], Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in."])))
            return
        }

        let cartRef = db.collection("users")
            .document(userId)
            .collection("cart")

        cartRef.getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            var cartItems: [CartItem] = []

            for document in snapshot?.documents ?? [] {
                let data = document.data()
                let docId = document.documentID

                if let productName = data["productName"] as? String,
                   let price = data["price"] as? Double,
                   let size = data["size"] as? String,
                   let quantity = data["quantity"] as? Int,
                   let cartItemId = data["cartItemId"] as? String,
                   let timestamp = data["timestamp"] as? Timestamp {
                    
                    let cartItem = CartItem(
                        id: docId,
                        cartItemId: cartItemId,
                        productName: productName,
                        price: price,
                        size: size,
                        quantity: quantity,
                        imageUrl: data["imageUrl"] as? String,
                        timestamp: timestamp.dateValue()
                    )
                    
                    cartItems.append(cartItem)
                }
            }

            completion(.success(cartItems))
        }
    }
    
    func deleteFromCart(cartItemId: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in."])))
            return
        }

        let cartRef = db.collection("users")
            .document(userId)
            .collection("cart")
            .document(cartItemId)

        cartRef.delete { error in
            if let error = error {
                print("❌ Error deleting product from cart: \(error.localizedDescription)")
                completion(.failure(error))
            } else {
                print("✅ Product successfully deleted from cart with ID: \(cartItemId)")
                completion(.success("✅ Product deleted from cart!"))
            }
        }
    }
    func updateQuantityInCart(cartItemId: String, newQuantity: Int, completion: ((Result<String, Error>) -> Void)? = nil) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion?(.failure(NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in."])))
            return
        }

        let cartRef = db.collection("users")
            .document(userId)
            .collection("cart")
            .document(cartItemId)

        cartRef.updateData(["quantity": newQuantity]) { error in
            if let error = error {
                print("❌ Failed to update quantity for \(cartItemId): \(error.localizedDescription)")
                completion?(.failure(error))
            } else {
                print("✅ Quantity updated to \(newQuantity) for \(cartItemId)")
                completion?(.success("Quantity updated"))
            }
        }
    }
    func saveOrder(items: [CartItem], totalAmount: Double, completion: @escaping (Result<String, Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in."])))
            return
        }

        let orderId = UUID().uuidString
        let db = Firestore.firestore()

        let orderRef = db.collection("users")
            .document(userId)
            .collection("orders")
            .document(orderId)

        let orderData: [String: Any] = [
            "userId": userId,
            "totalAmount": totalAmount,
            "timestamp": Timestamp(date: Date()),
            "items": items.map { item in
                return [
                    "productName": item.productName,
                    "price": item.price,
                    "size": item.size,
                    "quantity": item.quantity,
                    "imageUrl": item.imageUrl ?? ""
                ]
            }
        ]

        // Save the order
        orderRef.setData(orderData) { error in
            if let error = error {
                completion(.failure(error))
                return
            }

            let batch = db.batch()

            // 🔁 Step 1: Update stock for each product
            for item in items {
                let productRef = db.collection("products").document(item.id) // item.id = productId_size
                let productId = item.id.components(separatedBy: "_").first ?? item.id

                let stockRef = db.collection("products").document(productId)
                batch.updateData([
                    item.size.lowercased(): FieldValue.increment(Int64(-item.quantity))
                ], forDocument: stockRef)
            }

            // 🧹 Step 2: Delete all cart items
            let cartRef = db.collection("users")
                .document(userId)
                .collection("cart")

            cartRef.getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                snapshot?.documents.forEach { doc in
                    batch.deleteDocument(doc.reference)
                }

                batch.commit { batchError in
                    if let batchError = batchError {
                        completion(.failure(batchError))
                    } else {
                        completion(.success("✅ Order saved, stock updated, and cart cleared!"))
                    }
                }
            }
        }
    }
}
