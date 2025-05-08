//
//  AuthView.swift
//  easyCart
//
//  Created by arshia salehi on 2025-03-12.
//
import SwiftUI

struct AuthView: View {
    @AppStorage("isAuthenticated") private var isAuthenticated = false
    @State private var isAdmin = false
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        if isAuthenticated {
            if isAdmin {
                MainViewAdmin()
            } else {
                MainViewCostomer()
            }
        } else {
            authForm
        }
    }

    var authForm: some View {
        VStack {
            Toggle(isOn: $isAdmin) {
                Text(isAdmin ? "Seller" : "Customer")
                    .font(.headline)
                    .foregroundColor(isAdmin ? .red : .blue)
            }
            .padding()

            VStack(spacing: 15) {
                Text("Email")
                    .frame(maxWidth: .infinity, alignment: .leading)
                TextField("Enter your email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)

                Text("Password")
                    .frame(maxWidth: .infinity, alignment: .leading)
                SecureField("Enter your password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button(action: authenticateUser) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("signin/signup")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .disabled(isLoading)

                Button(action: resetPassword) {
                    Text("Forgot Password?")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.black)
                        .cornerRadius(8)
                }

                if let message = errorMessage {
                    Text(message)
                        .foregroundColor(message.contains("✅") ? .green : .red)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding()
        }
        .frame(maxWidth: 350)
        .padding()
    }

    // MARK: - Authentication Flow
    private func authenticateUser() {
        errorMessage = nil

        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "⚠️ Please enter email and password."
            return
        }

        guard email.contains("@"), email.contains(".") else {
            errorMessage = "⚠️ Enter a valid email address."
            return
        }

        guard password.count >= 6 else {
            errorMessage = "⚠️ Password must be at least 6 characters."
            return
        }

        isLoading = true

        FirebaseAuthService.shared.login(email: email, password: password) { result in
            switch result {
            case .success(let user):
                print("✅ Logged in: \(user.email)")
                isAuthenticated = true
            case .failure:
                print("👤 User not found, trying to create...")
                FirebaseAuthService.shared.signUp(email: email, password: password, isAdmin: isAdmin) { result in
                    switch result {
                    case .success(let user):
                        print("✅ Created account for \(user.email)")
                        errorMessage = "✅ Account created successfully!"
                        isAuthenticated = true
                    case .failure(let error):
                        errorMessage = "❌ \(error.localizedDescription)"
                    }
                }
            }
            isLoading = false
        }
    }

    private func resetPassword() {
        errorMessage = nil

        guard !email.isEmpty else {
            errorMessage = "⚠️ Please enter your email first."
            return
        }

        isLoading = true

        FirebaseAuthService.shared.resetPassword(email: email) { result in
            isLoading = false
            switch result {
            case .success:
                errorMessage = "✅ Password reset email sent!"
            case .failure(let error):
                errorMessage = "❌ \(error.localizedDescription)"
            }
        }
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
    }
}

