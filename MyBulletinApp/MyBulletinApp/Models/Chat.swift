//
//  Chat.swift
//  MyBulletinApp
//
//  グループチャットとDMのモデル
//

import Foundation
import FirebaseFirestore

struct Chat: Identifiable, Codable {
    @DocumentID var id: String?
    var type: String           // "group" または "dm"
    var name: String           // グループ名 or 相手のメール
    var code: String?          // グループ参加コード（10文字、groupのみ）
    var members: [String]      // メンバーのUID配列
    var memberEmails: [String]? // DMの場合のメールアドレス配列
    var createdBy: String      // 作成者のUID
    var createdAt: Date?
    
    var isGroup: Bool {
        return type == "group"
    }
}
