//
//  easyCartApp.swift
//  easyCart
//
//  Created by arshia salehi on 2025-03-12.
//

import SwiftUI
import FirebaseCore
import StripeCore
class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
      
    STPAPIClient.shared.publishableKey = "pk_test_51RCrDsD3fAEAvQ6KIoo9H7fgoGotVPaDhhCUw2IFj39tOklL04GXgiV9jQtzXCmInXTQHTfa5m1YwCk5unn23kf400C6JWmzGV"
    
    if FirebaseApp.app() != nil {
        print("🔥 Firebase is successfully connected!")
    } else {
        print("❌ Firebase connection failed.")
    }
    
    return true
  }
}

@main
struct easyCartApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        WindowGroup {
            AuthView()
        }
    }
}
