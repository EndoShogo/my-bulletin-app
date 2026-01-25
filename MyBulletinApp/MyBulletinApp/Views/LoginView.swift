//
//  LoginView.swift
//  MyBulletinApp
//
//  Created by 遠藤省吾 on R 8/01/17.
//

import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    
    @State private var isRegistering = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                
                Text(isRegistering ? "Create Account" : "Welcome Back")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)

                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }

                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Button(action: {
                        isRegistering ? register() : login()
                    }) {
                        Text(isRegistering ? "Register" : "Login")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                
                Button(action: {
                    isRegistering.toggle()
                    errorMessage = nil
                }) {
                    Text(isRegistering ? "Have an account? Login" : "Don't have an account? Register")
                        .font(.subheadline)
                }

                Spacer()
            }
            .padding()
            .navigationTitle(isRegistering ? "Register" : "Login")
            .navigationBarHidden(true)
        }
    }

    private func login() {
        isLoading = true
        errorMessage = nil
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            isLoading = false
            if let error = error {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func register() {
        isLoading = true
        errorMessage = nil
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            isLoading = false
            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                // Registration successful, maybe automatically log in or prompt user to log in.
                isRegistering = false // Switch back to login view
            }
        }
    }
}

#Preview {
    LoginView()
}
