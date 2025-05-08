//
//  FirebaseService.swift
//  easyCart
//
//  Created by arshia salehi on 2025-03-12.
//
import SwiftUI
import PhotosUI
import FirebaseAuth

struct AddProductBox: View {
    @Binding var productName: String
    @Binding var price: Double
    @Binding var small: Int
    @Binding var medium: Int
    @Binding var large: Int
    @Binding var imageUrl: String?
    @Binding var isUploading: Bool

    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var selectedSize: String = "Small"
    @State private var uploadMessage: String = ""

    private var selectedQuantityBinding: Binding<Int> {
        switch selectedSize {
        case "Small": return $small
        case "Medium": return $medium
        case "Large": return $large
        default: return $small
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 15) {
                VStack {
                    if let image = selectedImage {
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
                                Text("Upload\nImage")
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
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    TextField("Price", value: $price, formatter: NumberFormatter())
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                        .frame(width: 150)
                }

                VStack {
                    TextField("Quantity", value: selectedQuantityBinding, formatter: NumberFormatter())
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)

                    Stepper(value: selectedQuantityBinding, in: 0...100) {}
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
                Button(action: addProduct) {
                    if isUploading {
                        ProgressView()
                    } else {
                        Text("Add")
                            .font(.headline)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }

            if !uploadMessage.isEmpty {
                Text(uploadMessage)
                    .font(.caption)
                    .foregroundColor(uploadMessage.contains("✅") ? .green : .red)
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

    private func addProduct() {
        guard let userId = Auth.auth().currentUser?.uid else {
            uploadMessage = "⚠️ User not logged in."
            return
        }
        guard !productName.isEmpty else {
            uploadMessage = "⚠️ Please enter a product name."
            return
        }
        guard price > 0 else {
            uploadMessage = "⚠️ Price must be greater than 0."
            return
        }
        guard small + medium + large > 0 else {
            uploadMessage = "⚠️ Please add quantity to at least one size."
            return
        }

        isUploading = true
        uploadMessage = ""

        let newProduct = Product(
            id: UUID().uuidString,
            name: productName,
            price: price,
            imageUrl: nil,
            small: small,
            medium: medium,
            large: large
        )

        FirebaseProduct.shared.addProduct(product: newProduct, image: selectedImage) { result in
            DispatchQueue.main.async {
                isUploading = false
                switch result {
                case .success:
                    uploadMessage = "✅ Product added successfully!"
                    resetFields()
                case .failure(let error):
                    uploadMessage = "❌ Error: \(error.localizedDescription)"
                }
            }
        }
    }

    private func resetFields() {
        productName = ""
        price = 0.0
        small = 0
        medium = 0
        large = 0
        selectedImage = nil
        selectedItem = nil
    }
}

struct AddProductBox_Previews: PreviewProvider {
    @State static var name = "Sample"
    @State static var price = 5.0
    @State static var s = 1
    @State static var m = 0
    @State static var l = 0
    @State static var url: String? = nil
    @State static var uploading = false

    static var previews: some View {
        AddProductBox(
            productName: $name,
            price: $price,
            small: $s,
            medium: $m,
            large: $l,
            imageUrl: $url,
            isUploading: $uploading
        )
    }
}
