//
//  UserProfile.swift
//  MyBulletinApp
//
//  ユーザープロフィール管理
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

class UserProfileManager: ObservableObject {
    static let shared = UserProfileManager()
    
    @Published var displayName: String = ""
    @Published var nicknames: [String: String] = [:]  // email/chatId -> nickname
    @Published var chatBackgrounds: [String: String] = [:]  // chatId -> background name
    @Published var chatBackgroundImages: [String: String] = [:]  // chatId -> image path
    @Published var displayNames: [String: String] = [:]  // email -> displayName (cache)
    
    private var db = Firestore.firestore()
    
    init() {
        fetchProfile()
    }
    
    func fetchProfile() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            if let data = snapshot?.data() {
                self?.displayName = data["displayName"] as? String ?? ""
                self?.nicknames = data["nicknames"] as? [String: String] ?? [:]
                self?.chatBackgrounds = data["chatBackgrounds"] as? [String: String] ?? [:]
                self?.chatBackgroundImages = data["chatBackgroundImages"] as? [String: String] ?? [:]
            }
        }
    }
    
    func saveDisplayName(_ name: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).setData([
            "displayName": name,
            "email": Auth.auth().currentUser?.email ?? ""
        ], merge: true)
        
        displayName = name
    }
    
    func setNickname(for key: String, nickname: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        if nickname.isEmpty {
            nicknames.removeValue(forKey: key)
        } else {
            nicknames[key] = nickname
        }
        
        db.collection("users").document(userId).setData([
            "nicknames": nicknames
        ], merge: true)
    }
    
    func getNickname(for key: String) -> String? {
        return nicknames[key]
    }
    
    // チャット背景を設定
    func setChatBackground(for chatId: String, background: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        chatBackgrounds[chatId] = background
        
        db.collection("users").document(userId).setData([
            "chatBackgrounds": chatBackgrounds
        ], merge: true)
    }
    
    func getChatBackground(for chatId: String) -> String? {
        return chatBackgrounds[chatId]
    }
    
    // チャット背景画像を設定
    func setChatBackgroundImage(for chatId: String, imagePath: String?) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        if let path = imagePath {
            chatBackgroundImages[chatId] = path
        } else {
            chatBackgroundImages.removeValue(forKey: chatId)
        }
        
        db.collection("users").document(userId).setData([
            "chatBackgroundImages": chatBackgroundImages
        ], merge: true)
    }
    
    func getChatBackgroundImage(for chatId: String) -> String? {
        return chatBackgroundImages[chatId]
    }
    
    // メールアドレスから表示名を取得（キャッシュ付き）
    func getDisplayName(for email: String, completion: @escaping (String) -> Void) {
        let emailLower = email.lowercased()
        
        // まずニックネームをチェック
        if let nickname = nicknames[emailLower], !nickname.isEmpty {
            completion(nickname)
            return
        }
        
        // キャッシュをチェック
        if let cached = displayNames[emailLower], !cached.isEmpty {
            completion(cached)
            return
        }
        
        // Firestoreから取得
        db.collection("users")
            .whereField("email", isEqualTo: emailLower)
            .limit(to: 1)
            .getDocuments { [weak self] snapshot, error in
                if let doc = snapshot?.documents.first,
                   let name = doc.data()["displayName"] as? String,
                   !name.isEmpty {
                    self?.displayNames[emailLower] = name
                    completion(name)
                } else {
                    let shortName = email.components(separatedBy: "@").first ?? email
                    completion(shortName)
                }
            }
    }
    
    // 同期的に表示名を取得（キャッシュのみ）
    func getDisplayNameSync(for email: String) -> String {
        let emailLower = email.lowercased()
        
        if let nickname = nicknames[emailLower], !nickname.isEmpty {
            return nickname
        }
        if let cached = displayNames[emailLower], !cached.isEmpty {
            return cached
        }
        return email.components(separatedBy: "@").first ?? email
    }
    
    // 自分の表示名を取得
    func getMyDisplayName() -> String {
        if !displayName.isEmpty {
            return displayName
        }
        return Auth.auth().currentUser?.email?.components(separatedBy: "@").first ?? "ゲスト"
    }
}

// 背景オプション
struct ChatBackgroundOption: Identifiable {
    let id: String
    let name: String
    let color: String?
    let imageName: String?
    
    static let options: [ChatBackgroundOption] = [
        ChatBackgroundOption(id: "default", name: "デフォルト", color: nil, imageName: nil),
        ChatBackgroundOption(id: "blue", name: "ブルー", color: "blue", imageName: nil),
        ChatBackgroundOption(id: "purple", name: "パープル", color: "purple", imageName: nil),
        ChatBackgroundOption(id: "green", name: "グリーン", color: "green", imageName: nil),
        ChatBackgroundOption(id: "orange", name: "オレンジ", color: "orange", imageName: nil),
        ChatBackgroundOption(id: "pink", name: "ピンク", color: "pink", imageName: nil),
        ChatBackgroundOption(id: "gray", name: "グレー", color: "gray", imageName: nil),
        ChatBackgroundOption(id: "image", name: "カスタム画像", color: nil, imageName: nil),
    ]
}
