//
//  ChatViewModel.swift
//  MyBulletinApp
//
//  Created by 遠藤省吾 on R 8/01/17.
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

class ChatViewModel: ObservableObject {
    @Published var messages = [Message]()
    @Published var errorMessage: String?
    
    private var db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?

    init() {
        fetchMessages()
    }

    deinit {
        listenerRegistration?.remove()
    }

    func fetchMessages() {
        listenerRegistration = db.collection("messages")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { [weak self] (querySnapshot, error) in
                guard let self = self else { return }
                if let error = error {
                    self.errorMessage = "Failed to fetch messages: \(error.localizedDescription)"
                    return
                }

                guard let documents = querySnapshot?.documents else {
                    self.errorMessage = "No messages found."
                    return
                }

                self.messages = documents.compactMap { document -> Message? in
                    let data = document.data()
                    let id = document.documentID
                    let text = data["text"] as? String ?? ""
                    let userId = data["userId"] as? String ?? ""
                    let userName = data["userName"] as? String ?? ""
                    let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()

                    return Message(id: id, text: text, userId: userId, userName: userName, createdAt: createdAt, mediaUrl: nil, mediaType: nil)
                }
            }
    }

    func sendMessage(text: String) {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "You must be logged in to send a message."
            return
        }

        let data: [String: Any] = [
            "text": text,
            "userId": user.uid,
            "userName": user.email ?? "Anonymous",
            "createdAt": FieldValue.serverTimestamp()
        ]

        db.collection("messages").addDocument(data: data) { error in
            if let error = error {
                self.errorMessage = "Failed to send message: \(error.localizedDescription)"
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            self.errorMessage = "Failed to sign out: \(error.localizedDescription)"
        }
    }
}
