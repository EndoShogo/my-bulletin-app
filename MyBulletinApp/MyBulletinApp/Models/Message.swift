//
//  Message.swift
//  MyBulletinApp
//
//  Created by 遠藤省吾 on R 8/01/17.
//

import Foundation
import FirebaseFirestore

struct Message: Identifiable, Codable {
    var id: String?
    var text: String
    var userId: String
    var userName: String
    var createdAt: Date?
    var mediaUrl: String?    // 画像/動画のダウンロードURL
    var mediaType: String?   // "image" または "video"
}
