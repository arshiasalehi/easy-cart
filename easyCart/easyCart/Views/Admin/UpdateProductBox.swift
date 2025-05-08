//
//  FirebaseService.swift
//  easyCart
//
//  Created by arshia salehi on 2025-03-12.
//
import SwiftUI
import PhotosUI

struct UpdateProductView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var productName: String = ""
    @State private var price: String = ""
    @State private var selectedQuantity: Int = 0
    @State private var selectedSize: String = "Small"
    @State private var productId: String = ""
    @State private var imageUrl: String?
    @State private var updateMessage: String = ""

    let firebaseProduct = FirebaseProduct()

    init(productId: String, productName: String, price: String, selectedQuantity: Int, imageUrl: String?) {
        _productId = State(initialValue: productId)
        _productName = State(initialValue: productName)
        _price = State(initialValue: price)
        _selectedQuantity = State(initialValue: selectedQuantity)
        _imageUrl = State(initialValue: imageUrl)
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 15) {
                VStack {
                    if let imageUrl = imageUrl, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView().frame(width: 70, height: 70)
                            case .success(let image):
                                image.resizable()
                                    .scaledToFill()
                                    .frame(width: 70, height: 70)
                                    .cornerRadius(10)
                            case .failure:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 70, height: 70)
                                    .cornerRadius(10)
                                    .overlay(Text("Image").foregroundColor(.black))
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 70, height: 70)
                            .cornerRadius(10)
                    } else {
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            ZStack {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 70, height: 70)
                                    .cornerRadius(10)
                                Text("Image")
                                    .font(.caption)
                                    .foregroundColor(.black)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .onChange(of: selectedItem) { _ in loadSelectedImage() }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    TextField("Product Name", text: $productName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 150)

                    TextField("Price", text: $price)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                        .frame(width: 150)
                }

                VStack {
                    TextField("Quantity", value: $selectedQuantity, formatter: NumberFormatter())
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)

                    Stepper(value: $selectedQuantity, in: 0...100) {
                        Text("")
                    }
                }
            }

            HStack(spacing: 10) {
                ForEach(["Small", "Medium", "Large"], id: \.self) { size in
                    Button {
                        selectedSize = size
                    } label: {
                        Text(size.prefix(1))
                            .font(.headline)
                            .foregroundColor(selectedSize == size ? .white : .black)
                            .frame(width: 40, height: 40)
                            .background(selectedSize == size ? Color.blue : Color.gray.opacity(0.3))
                            .clipShape(Circle())
                    }
                }
            }

            HStack {
                Button(action: updateProduct) {
                    Text("Update")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Button(action: deleteProduct) {
                    Text("Delete")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }

            if !updateMessage.isEmpty {
                Text(updateMessage)
                    .font(.caption)
                    .foregroundColor(updateMessage.contains("✅") || updateMessage.contains("🗑") ? .green : .red)
            }
        }
        .frame(width: 330, height: 230)
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
    }

    private func loadSelectedImage() {
        Task {
            if let data = try? await selectedItem?.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                selectedImage = uiImage
            }
        }
    }

    private func updateProduct() {
        guard !productName.isEmpty else {
            updateMessage = "⚠️ Product name is required."
            return
        }

        guard let doublePrice = Double(price), doublePrice > 0 else {
            updateMessage = "⚠️ Enter a valid price."
            return
        }

        guard selectedQuantity > 0 else {
            updateMessage = "⚠️ Quantity must be greater than 0."
            return
        }

        let updatedData: [String: Any] = [
            "name": productName,
            "price": doublePrice,
            selectedSize.lowercased(): selectedQuantity
        ]

        firebaseProduct.updateProduct(productId: productId, updatedData: updatedData, newImage: selectedImage) { result in
            switch result {
            case .success:
                updateMessage = "✅ Product updated."
            case .failure(let error):
                updateMessage = "❌ Update failed: \(error.localizedDescription)"
            }
        }
    }

    private func deleteProduct() {
        firebaseProduct.deleteProduct(productId: productId, imageUrl: imageUrl) { result in
            switch result {
            case .success:
                updateMessage = "🗑 Product deleted."
            case .failure(let error):
                updateMessage = "❌ Delete failed: \(error.localizedDescription)"
            }
        }
    }
}

// ✅ Preview for testing
struct UpdateProductView_Previews: PreviewProvider {
    static var previews: some View {
        UpdateProductView(
            productId: "preview-id",
            productName: "Preview Product",
            price: "19.99",
            selectedQuantity: 3,
            imageUrl: nil
        )
        .previewLayout(.sizeThatFits)
    }
}
