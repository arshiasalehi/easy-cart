//
//  ProfileView.swift
//  easyCart
//
//  Created by Arshia Salehi on 2025-03-12.
//

import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("isAuthenticated") private var isAuthenticated = true

    @State private var fullName: String = ""
    @State private var phoneNumber: String = ""
    @State private var address: String = ""
    @State private var city: String = ""
    @State private var postalCode: String = ""
    @State private var errorMessage: String?
    @State private var successMessage: String?

    var body: some View {
        VStack(spacing: 15) {
            Group {
                Text("Full Name")
                    .frame(maxWidth: .infinity, alignment: .leading)
                TextField("Ali Salehi", text: $fullName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Text("Phone Number")
                    .frame(maxWidth: .infinity, alignment: .leading)
                TextField("123 456 7890", text: $phoneNumber)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)

                Text("Address")
                    .frame(maxWidth: .infinity, alignment: .leading)
                TextField("1234 Street Name", text: $address)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Text("City")
                    .frame(maxWidth: .infinity, alignment: .leading)
                TextField("Montreal", text: $city)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Text("Postal Code")
                    .frame(maxWidth: .infinity, alignment: .leading)
                TextField("X1X 2X3", text: $postalCode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            if let success = successMessage {
                Text(success)
                    .foregroundColor(.green)
                    .font(.caption)
            }

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Button(action: saveChanges) {
                Text("Save Changes")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(20)
            }.padding(.top, 10)

            Button(action: logOut) {
                Text("Log Out")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(20)
            }
            .padding(.top, 5)
        }
        .padding(40)
        .onAppear(perform: fetchUserData)
    }

    private func fetchUserData() {
        FirebaseUserInfo.shared.fetchUserData { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self.fullName = data["name"] as? String ?? ""
                    self.phoneNumber = "\(data["phonenumber"] ?? "")"
                    self.address = data["address"] as? String ?? ""
                    self.city = data["city"] as? String ?? ""
                    self.postalCode = data["postalCode"] as? String ?? ""
                case .failure(let error):
                    self.errorMessage = "❌ Failed to fetch profile: \(error.localizedDescription)"
                }
            }
        }
    }

    private func saveChanges() {
        let updatedData: [String: Any] = [
            "name": fullName,
            "phonenumber": phoneNumber,
            "address": address,
            "city": city,
            "postalCode": postalCode
        ]

        FirebaseUserInfo.shared.updateUserData(updatedData) { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.successMessage = nil
                    self.errorMessage = "❌ Failed to save: \(error.localizedDescription)"
                } else {
                    self.errorMessage = nil
                    self.successMessage = "✅ Profile updated successfully!"
                }
            }
        }
    }

    private func logOut() {
        FirebaseAuthService.shared.signOut { error in
            DispatchQueue.main.async {
                if let error = error {
                    errorMessage = "Logout failed: \(error.localizedDescription)"
                } else {
                    isAuthenticated = false
                    print("User logged out successfully.")
                }
            }
        }
    }
}

#Preview {
    ProfileView()
}

