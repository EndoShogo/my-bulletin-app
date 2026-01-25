//
//  ContentView.swift
//  MyBulletinApp
//
//  Created by 遠藤省吾 on R 8/01/17.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @State private var isAuthenticated = false
    @State private var authStateListenerHandle: AuthStateDidChangeListenerHandle?


    var body: some View {
        Group {
            if isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .onAppear(perform: setupAuthListener)
        .onDisappear(perform: removeAuthListener)
    }

    private func setupAuthListener() {
        // リスナーが重複して追加されないようにする
        if authStateListenerHandle == nil {
            authStateListenerHandle = Auth.auth().addStateDidChangeListener { auth, user in
                self.isAuthenticated = (user != nil)
            }
        }
    }
    
    private func removeAuthListener() {
        if let handle = authStateListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}


#Preview {
    ContentView()
}
