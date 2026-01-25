//
//  ChatView.swift
//  MyBulletinApp
//
//  Created by 遠藤省吾 on R 8/01/17.
//

import SwiftUI
import FirebaseAuth

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var messageText = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        ScrollView {
            // Header
            HStack {
                Text("Chat Room")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
                Button(action: {
                    viewModel.signOut()
                }) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding()

            // Message List
            ScrollViewReader { proxy in
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.messages) { message in
                        MessageRow(message: message)
                            .id(message.id)
                    }
                }
                .padding(.horizontal)
                .onChange(of: viewModel.messages.count) { _ in
                    DispatchQueue.main.async {
                        scrollToBottom(proxy: proxy)
                    }
                }
                .onAppear {
                    DispatchQueue.main.async {
                        scrollToBottom(proxy: proxy, animated: false)
                    }
                }
            }

            // Error Message
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .onTapGesture {
            // 画面タップでキーボードを閉じる
            isTextFieldFocused = false
        }
        // Apple公式の「安全領域への挿入」を使う
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                // 上部の区切り線
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .gray.opacity(0.2), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 0.5)
                
                HStack(alignment: .center, spacing: 12) {
                    // +ボタン（将来の機能用プレースホルダー）
                    Button(action: {
                        // Firebase Storage使用不可のため無効化
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.gray.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                    .disabled(true)
                    
                    // メッセージ入力フィールド
                    TextField("メッセージを入力...", text: $messageText, axis: .vertical)
                        .font(.body)
                        .lineLimit(1...5)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .focused($isTextFieldFocused)
                        .background(
                            RoundedRectangle(cornerRadius: 22)
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 1)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(Color.gray.opacity(0.15), lineWidth: 0.5)
                        )
                    
                    // 送信ボタン
                    Button(action: sendMessage) {
                        ZStack {
                            Circle()
                                .fill(!messageText.isEmpty ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: 36, height: 36)
                                .shadow(
                                    color: !messageText.isEmpty ? .blue.opacity(0.3) : .clear,
                                    radius: 4,
                                    x: 0,
                                    y: 2
                                )
                            
                            Image(systemName: "arrow.up")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(messageText.isEmpty)
                    .animation(.easeInOut(duration: 0.2), value: messageText.isEmpty)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .background(.ultraThinMaterial)
            // スワイプジェスチャー: 上スワイプでキーボード表示、下スワイプで閉じる
            .gesture(
                DragGesture(minimumDistance: 20, coordinateSpace: .local)
                    .onEnded { value in
                        let verticalMovement = value.translation.height
                        if verticalMovement < -30 {
                            // 上にスワイプ → キーボードを開く
                            isTextFieldFocused = true
                        } else if verticalMovement > 30 {
                            // 下にスワイプ → キーボードを閉じる
                            isTextFieldFocused = false
                        }
                    }
            )
        }
    }

    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        viewModel.sendMessage(text: messageText)
        messageText = ""
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool = true) {
        guard let lastMessage = viewModel.messages.last, let id = lastMessage.id else { return }
        if animated {
            withAnimation {
                proxy.scrollTo(id, anchor: .bottom)
            }
        } else {
            proxy.scrollTo(id, anchor: .bottom)
        }
    }
}

struct MessageRow: View {
    let message: Message
    private var isCurrentUser: Bool {
        return Auth.auth().currentUser?.uid == message.userId
    }

    var body: some View {
        HStack {
            if isCurrentUser {
                Spacer()
            }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.userName)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                // テキスト表示
                if !message.text.isEmpty {
                    Text(message.text)
                        .padding(10)
                        .background(isCurrentUser ? Color.blue : Color(.secondarySystemBackground))
                        .foregroundColor(isCurrentUser ? .white : .primary)
                        .cornerRadius(10)
                }
            }
            
            if !isCurrentUser {
                Spacer()
            }
        }
    }
}

#Preview {
    ChatView()
}
