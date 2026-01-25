//
//  ChatRoomView.swift
//  MyBulletinApp
//
//  チャットルーム画面（グループ・DM共通）
//

import SwiftUI
import Combine
import PhotosUI
import FirebaseAuth
import FirebaseFirestore

struct ChatRoomView: View {
    let chat: Chat
    @StateObject private var viewModel = ChatRoomViewModel()
    @State private var messageText = ""
    @State private var showEditSheet = false
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.dismiss) private var dismiss
    
    private var profileManager: UserProfileManager { UserProfileManager.shared }
    
    private var backgroundImage: UIImage? {
        guard let chatId = chat.id,
              let imagePath = profileManager.getChatBackgroundImage(for: chatId) else {
            return nil
        }
        let url = URL(fileURLWithPath: imagePath)
        return UIImage(contentsOfFile: url.path)
    }
    
    private var backgroundColor: Color {
        guard let chatId = chat.id,
              let bg = profileManager.getChatBackground(for: chatId) else {
            return Color(.systemBackground)
        }
        
        // テーマに依存しない固定色
        switch bg {
        case "blue": return Color(red: 0.91, green: 0.93, blue: 0.99)
        case "purple": return Color(red: 0.94, green: 0.91, blue: 0.96)
        case "green": return Color(red: 0.91, green: 0.96, blue: 0.91)
        case "orange": return Color(red: 1.0, green: 0.95, blue: 0.88)
        case "pink": return Color(red: 0.99, green: 0.89, blue: 0.93)
        case "gray": return Color(red: 0.96, green: 0.96, blue: 0.96)
        default: return Color(.systemBackground)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Message List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                .background {
                    if let image = backgroundImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .opacity(0.3)
                    } else {
                        backgroundColor
                    }
                }
                .onChange(of: viewModel.messages.count) { _ in
                    scrollToBottom(proxy: proxy)
                }
                .onAppear {
                    scrollToBottom(proxy: proxy, animated: false)
                }
            }
            
            // Input Bar - Apple純正 Liquid Glass Design with Swipe
            HStack(alignment: .bottom, spacing: 0) {
                // テキスト入力エリア
                TextField("メッセージを入力...", text: $messageText, axis: .vertical)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .lineLimit(1...5)
                    .focused($isTextFieldFocused)
                    .frame(minHeight: 44)
                
                // 送信ボタン（入力欄の中に配置、常に表示）
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(messageText.isEmpty ? .gray.opacity(0.5) : .white, 
                                       messageText.isEmpty ? .gray.opacity(0.2) : .blue)
                        .symbolEffect(.bounce, value: messageText)
                }
                .disabled(messageText.isEmpty)
                .padding(.trailing, 8)
                .padding(.bottom, 6)
            }
            .background(.regularMaterial) // 全体をすりガラスに
            .clipShape(Capsule()) // 全体をカプセル型に
            .contentShape(Rectangle()) // 透明部分も含めてタップ/スワイプ判定
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .padding(.bottom, 4)
            // スワイプジェスチャー
            .highPriorityGesture(
                DragGesture(minimumDistance: 10, coordinateSpace: .local)
                    .onEnded { value in
                        let verticalMovement = value.translation.height
                        // 感度を上げてスワイプ検知しやすくする
                        if verticalMovement < -20 {
                            isTextFieldFocused = true
                        } else if verticalMovement > 20 {
                            isTextFieldFocused = false
                        }
                    }
            )
        }
    .navigationTitle(chat.name)
    .navigationBarTitleDisplayMode(.inline)
    // 標準の戻るボタンとスワイプバックを使用するため、BackButtonHiddenを削除
    .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showEditSheet = true }) {
                    Image(systemName: "line.3.horizontal")
                        .font(.title3)
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            ChatEditSheet(chat: chat)
        }
        .onAppear {
            if let chatId = chat.id {
                viewModel.fetchMessages(chatId: chatId)
            }
        }
        .onDisappear {
            viewModel.stopListening()
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty, let chatId = chat.id else { return }
        
        let userName = profileManager.displayName.isEmpty
            ? (Auth.auth().currentUser?.email ?? "Anonymous")
            : profileManager.displayName
        
        viewModel.sendMessage(chatId: chatId, text: messageText, userName: userName)
        messageText = ""
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool = true) {
        guard let lastMessage = viewModel.messages.last, let id = lastMessage.id else { return }
        if animated {
            withAnimation { proxy.scrollTo(id, anchor: .bottom) }
        } else {
            proxy.scrollTo(id, anchor: .bottom)
        }
    }
}

// メッセージバブル
struct MessageBubble: View {
    let message: Message
    
    private var profileManager: UserProfileManager { UserProfileManager.shared }
    
    private var isCurrentUser: Bool {
        Auth.auth().currentUser?.uid == message.userId
    }
    
    private var displayName: String {
        // 自分のメッセージの場合は自分の表示名を使用
        if isCurrentUser {
            return profileManager.displayName.isEmpty
                ? message.userName.components(separatedBy: "@").first ?? message.userName
                : profileManager.displayName
        }
        // 他のユーザーの場合はニックネームまたは表示名
        return profileManager.getDisplayNameSync(for: message.userName)
    }
    
    var body: some View {
        HStack {
            if isCurrentUser { Spacer() }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(displayName)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                if !message.text.isEmpty {
                    Text(message.text)
                        .padding(10)
                        .background(isCurrentUser ? Color.blue : Color(.secondarySystemBackground))
                        .foregroundColor(isCurrentUser ? .white : .primary)
                        .cornerRadius(16)
                }
            }
            
            if !isCurrentUser { Spacer() }
        }
    }
}

// チャット編集シート
struct ChatEditSheet: View {
    let chat: Chat
    @Environment(\.dismiss) var dismiss
    @State var editingNickname = ""
    @State var showNicknameEdit = false
    @State var selectedBackground = "default"
    @State var currentCode: String = ""
    @State var showCodeRegenAlert = false
    @State var showImagePicker = false
    @State var selectedImage: PhotosPickerItem?
    
    var profileManager: UserProfileManager { UserProfileManager.shared }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("チャット情報")) {
                    HStack {
                        Text("名前")
                        Spacer()
                        Text(chat.name)
                            .foregroundColor(.gray)
                    }
                    
                    if chat.isGroup {
                        HStack {
                            Text("参加コード")
                            Spacer()
                            Text(currentCode)
                                .foregroundColor(.gray)
                                .font(.system(.body, design: .monospaced))
                            
                            Button(action: { showCodeRegenAlert = true }) {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                
                if chat.isGroup {
                    Section(header: Text("メンバー")) {
                        Text("\(chat.members.count) 人")
                    }
                }
                
                // 背景設定
                Section(header: Text("背景"), footer: Text("自分だけに表示される背景")) {
                    Picker("背景色", selection: $selectedBackground) {
                        ForEach(ChatBackgroundOption.options) { option in
                            Text(option.name).tag(option.id)
                        }
                    }
                    .onChange(of: selectedBackground) { newValue in
                        if let chatId = chat.id {
                            profileManager.setChatBackground(for: chatId, background: newValue)
                            // 色を選んだら画像をクリア
                            if newValue != "image" {
                                profileManager.setChatBackgroundImage(for: chatId, imagePath: nil)
                            }
                        }
                    }
                    
                    PhotosPicker(selection: $selectedImage, matching: .images) {
                        Label("画像を選択", systemImage: "photo")
                    }
                    .onChange(of: selectedImage) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let chatId = chat.id {
                                saveBackgroundImage(data: data, chatId: chatId)
                            }
                        }
                    }
                    
                    if let chatId = chat.id,
                       profileManager.getChatBackgroundImage(for: chatId) != nil {
                        Button("背景画像をリセット", role: .destructive) {
                            profileManager.setChatBackgroundImage(for: chatId, imagePath: nil)
                        }
                    }
                }
                
                // ニックネーム編集
                Section(header: Text("ニックネーム"), footer: Text("自分だけに表示される相手の名前")) {
                    let targetKey = chat.isGroup ? (chat.id ?? "") : chat.name.lowercased()
                    let currentNickname = profileManager.getNickname(for: targetKey)
                    
                    HStack {
                        Text("ニックネーム")
                        Spacer()
                        Text(currentNickname ?? "未設定")
                            .foregroundColor(.gray)
                        
                        Button(action: {
                            editingNickname = currentNickname ?? ""
                            showNicknameEdit = true
                        }) {
                            Image(systemName: "pencil")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if let nick = currentNickname, !nick.isEmpty {
                        Button("ニックネームをリセット") {
                            profileManager.setNickname(for: targetKey, nickname: "")
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("チャット設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") { dismiss() }
                }
            }
            .sheet(isPresented: $showNicknameEdit) {
                EditNicknameSheet(
                    nickname: $editingNickname,
                    isPresented: $showNicknameEdit,
                    onSave: { nickname in
                        let targetKey = chat.isGroup ? (chat.id ?? "") : chat.name.lowercased()
                        profileManager.setNickname(for: targetKey, nickname: nickname)
                    }
                )
            }
            .alert("招待コードを再発行", isPresented: $showCodeRegenAlert) {
                Button("キャンセル", role: .cancel) {}
                Button("再発行", role: .destructive) { regenerateCode() }
            } message: {
                Text("現在のコードは使用できなくなります。新しいコードを発行しますか？")
            }
            .onAppear {
                currentCode = chat.code ?? ""
                if let chatId = chat.id {
                    selectedBackground = profileManager.getChatBackground(for: chatId) ?? "default"
                }
            }
        }
    }
    
    func regenerateCode() {
        guard let chatId = chat.id else { return }
        
        let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let newCode = String((0..<10).map { _ in chars.randomElement()! })
        
        Firestore.firestore().collection("chats").document(chatId).updateData([
            "code": newCode
        ]) { error in
            if error == nil { currentCode = newCode }
        }
    }
    
    func saveBackgroundImage(data: Data, chatId: String) {
        let fileName = "\(chatId)_bg.jpg"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filePath = documentsPath.appendingPathComponent(fileName)
        
        do {
            try data.write(to: filePath)
            profileManager.setChatBackgroundImage(for: chatId, imagePath: filePath.path)
            selectedBackground = "image"
        } catch {
            print("Failed to save image: \(error)")
        }
    }
}

// ニックネーム編集シート
struct EditNicknameSheet: View {
    @Binding var nickname: String
    @Binding var isPresented: Bool
    let onSave: (String) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("ニックネーム")) {
                    TextField("ニックネームを入力", text: $nickname)
                }
            }
            .navigationTitle("ニックネームを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(nickname)
                        isPresented = false
                    }
                }
            }
        }
    }
}

// ChatRoomViewModel
class ChatRoomViewModel: ObservableObject {
    @Published var messages: [Message] = []
    
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    func fetchMessages(chatId: String) {
        listener = db.collection("chats").document(chatId).collection("messages")
            .order(by: "createdAt")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                self?.messages = documents.compactMap { doc in
                    let data = doc.data()
                    return Message(
                        id: doc.documentID,
                        text: data["text"] as? String ?? "",
                        userId: data["userId"] as? String ?? "",
                        userName: data["userName"] as? String ?? "",
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue(),
                        mediaUrl: nil,
                        mediaType: nil
                    )
                }
            }
    }
    
    func sendMessage(chatId: String, text: String, userName: String? = nil) {
        guard let user = Auth.auth().currentUser else { return }
        
        let name = userName ?? user.email ?? "Anonymous"
        
        let data: [String: Any] = [
            "text": text,
            "userId": user.uid,
            "userName": name,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        db.collection("chats").document(chatId).collection("messages").addDocument(data: data)
    }
    
    func stopListening() {
        listener?.remove()
    }
}

#Preview {
    NavigationView {
        ChatRoomView(chat: Chat(id: "test", type: "group", name: "Test Group", code: "ABC123", members: [], createdBy: ""))
    }
}
