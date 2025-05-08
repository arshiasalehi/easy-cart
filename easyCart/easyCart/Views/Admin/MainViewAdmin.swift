//
//  MainViewAdmin.swift
//  easyCart
//
//  Created by arshia salehi on 2025-03-17.
//
import SwiftUI

struct MainViewAdmin: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ProductView()
                .tabItem {
                    Image(systemName: "archivebox.fill")
                    Text("Products")
                }
                .tag(0)

            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(1)
        }
        .accentColor(.blue) // Optional: to match your primary color
    }
}

struct MainViewAdmin_Previews: PreviewProvider {
    static var previews: some View {
        MainViewAdmin()
    }
}


