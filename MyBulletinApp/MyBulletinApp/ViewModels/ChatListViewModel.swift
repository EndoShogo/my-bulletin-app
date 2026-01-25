//
//  ChatListViewModel.swift
//  MyBulletinApp
//
//  チャット一覧の取得・作成・参加機能
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

class ChatListViewModel: ObservableObject {
    @Published var groups: [Chat] = []
    @Published var dms: [Chat] = []
    @Published var errorMessage: String?
    @Published var alertMessage: String?
    @Published var showAlert = false
    
    private var db = Firestore.firestore()
    
    // ランダムコード生成
    func generateCode(length: Int = 10) -> String {
        let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in chars.randomElement()! })
    }
    
    // グループ一覧取得
    func fetchGroups() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("chats")
            .whereField("type", isEqualTo: "group")
            .whereField("members", arrayContains: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                self?.groups = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: Chat.self)
                } ?? []
            }
    }
    
    // DM一覧取得
    func fetchDMs() {
        guard let email = Auth.auth().currentUser?.email?.lowercased() else { return }
        
        db.collection("chats")
            .whereField("type", isEqualTo: "dm")
            .whereField("memberEmails", arrayContains: email)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                self?.dms = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: Chat.self)
                } ?? []
            }
    }
    
    // グループ作成
    func createGroup(name: String, completion: @escaping (String?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(nil)
            return
        }
        
        let code = generateCode()
        let chatData: [String: Any] = [
            "type": "group",
            "name": name,
            "code": code,
            "members": [user.uid],
            "createdBy": user.uid,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        db.collection("chats").addDocument(data: chatData) { [weak self] error in
            if let error = error {
                self?.alertMessage = "エラー: \(error.localizedDescription)"
                self?.showAlert = true
                completion(nil)
            } else {
                self?.alertMessage = "グループを作成しました！\n参加コード: \(code)"
                self?.showAlert = true
                completion(code)
            }
        }
    }
    
    // グループ参加
    func joinGroup(code: String, completion: @escaping (Bool) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        
        db.collection("chats")
            .whereField("code", isEqualTo: code.uppercased())
            .whereField("type", isEqualTo: "group")
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    self?.alertMessage = "エラー: \(error.localizedDescription)"
                    self?.showAlert = true
                    completion(false)
                    return
                }
                
                guard let doc = snapshot?.documents.first else {
                    self?.alertMessage = "グループが見つかりません"
                    self?.showAlert = true
                    completion(false)
                    return
                }
                
                doc.reference.updateData([
                    "members": FieldValue.arrayUnion([userId])
                ]) { error in
                    if let error = error {
                        self?.alertMessage = "エラー: \(error.localizedDescription)"
                    } else {
                        self?.alertMessage = "グループに参加しました！"
                    }
                    self?.showAlert = true
                    completion(error == nil)
                }
            }
    }
    
    // DM開始
    func startDM(email: String, completion: @escaping (Chat?) -> Void) {
        guard let user = Auth.auth().currentUser,
              let myEmail = user.email?.lowercased() else {
            completion(nil)
            return
        }
        
        let targetEmail = email.lowercased()
        
        if targetEmail == myEmail {
            alertMessage = "自分自身にはDMできません"
            showAlert = true
            completion(nil)
            return
        }
        
        // 既存のDMをチェック
        db.collection("chats")
            .whereField("type", isEqualTo: "dm")
            .whereField("memberEmails", arrayContains: myEmail)
            .getDocuments { [weak self] snapshot, error in
                if let existingDM = snapshot?.documents.first(where: { doc in
                    let emails = doc.data()["memberEmails"] as? [String] ?? []
                    return emails.contains(targetEmail)
                }) {
                    let chat = try? existingDM.data(as: Chat.self)
                    completion(chat)
                    return
                }
                
                // 新規DM作成
                let chatData: [String: Any] = [
                    "type": "dm",
                    "name": targetEmail,
                    "memberEmails": [myEmail, targetEmail],
                    "members": [user.uid],
                    "createdBy": user.uid,
                    "createdAt": FieldValue.serverTimestamp()
                ]
                
                self?.db.collection("chats").addDocument(data: chatData) { error in
                    if let error = error {
                        self?.alertMessage = "エラー: \(error.localizedDescription)"
                        self?.showAlert = true
                        completion(nil)
                    } else {
                        self?.fetchDMs()
                        // 作成したDMを取得
                        self?.db.collection("chats")
                            .whereField("type", isEqualTo: "dm")
                            .whereField("memberEmails", arrayContains: myEmail)
                            .getDocuments { snapshot, _ in
                                let newDM = snapshot?.documents.first(where: { doc in
                                    let emails = doc.data()["memberEmails"] as? [String] ?? []
                                    return emails.contains(targetEmail)
                                })
                                let chat = try? newDM?.data(as: Chat.self)
                                completion(chat)
                            }
                    }
                }
            }
    }
}
