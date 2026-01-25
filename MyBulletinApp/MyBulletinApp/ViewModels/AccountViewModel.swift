//
//  AccountViewModel.swift
//  MyBulletinApp
//
//  Created by 遠藤省吾 on R 8/01/24.
//

import Foundation
import Combine
import FirebaseAuth

class AccountViewModel: ObservableObject {
    
    @Published var userEmail: String = ""
    @Published var alertMessage: String?
    @Published var showAlert: Bool = false
    
    init() {
        fetchUser()
    }
    
    // ユーザー情報を取得してメールアドレスを更新する
    func fetchUser() {
        if let user = Auth.auth().currentUser {
            self.userEmail = user.email ?? "メールアドレスがありません"
        }
    }
    
    // パスワードリセットメールを送信する
    func sendPasswordReset() {
        print("Attempting to send password reset email for: \(userEmail)") // 追加
        guard !userEmail.isEmpty else {
            self.alertMessage = "メールアドレスが取得できませんでした。"
            self.showAlert = true
            print("Error: User email is empty.") // 追加
            return
        }
        
        Auth.auth().sendPasswordReset(withEmail: userEmail) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                self.alertMessage = "エラー: \(error.localizedDescription)"
                print("Failed to send password reset email: \(error.localizedDescription)") // 追加
            } else {
                self.alertMessage = "パスワードリセット用のメールを送信しました。受信箱を確認してください。"
                print("Password reset email sent successfully to: \(self.userEmail)") // 追加
            }
            self.showAlert = true
        }
    }
}
