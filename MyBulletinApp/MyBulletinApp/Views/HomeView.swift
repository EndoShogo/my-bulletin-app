//
//  HomeView.swift
//  MyBulletinApp
//
//  ホーム画面（最近のチャット表示）
//

import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseAuth

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showSettings = false
    @State private var decorationColor: Color = .orange
    
    // ダークモード時は明るい色、ライトモード時は暗い色
    private var randomColors: [Color] {
        if themeManager.colorScheme == .dark {
            return [.cyan, .mint, .yellow, .pink, .orange, .green]
        } else {
            return [.indigo, .purple, .blue, .brown, .teal, .red]
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // ウェルカムセクション with 装飾
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("おかえりなさい")
                                .font(.title2)
                                .foregroundColor(.gray)
                            Text(UserProfileManager.shared.getMyDisplayName())
                                .font(.title)
                                .fontWeight(.bold)
                        }
                        
                        Spacer()
                        
                        // ガラスエフェクト装飾（iOS 26+）
                        GlassEffectContainer(spacing: 24) {
                            HStack(spacing: 0) {
                                Image(systemName: "eyes.inverse")
                                    .imageScale(.large)
                                    .padding()
                                    .rotationEffect(.degrees(10))
                                    .transformEffect(.init(translationX: -3, y: -7))
                                    .glassEffect(.clear.tint(decorationColor.opacity(0.7)))
                                    .foregroundStyle(.white)
                                    .padding(.trailing, -3)
                                
                                Image(systemName: "eyes.inverse")
                                    .imageScale(.large)
                                    .padding()
                                    .rotationEffect(.degrees(10))
                                    .transformEffect(.init(translationX: 0, y: -10))
                                    .glassEffect(.clear.tint(decorationColor.opacity(0.7)))
                                    .foregroundStyle(.white)
                                    .padding(.trailing, 3)
                                
                                Image(systemName: "eyes.inverse")
                                    .imageScale(.large)
                                    .padding()
                                    .rotationEffect(.degrees(8))
                                    .transformEffect(.init(translationX: -5, y: -6))
                                    .glassEffect(.clear.tint(decorationColor.opacity(0.7)))
                                    .foregroundStyle(.white)
                            }
                        }
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                decorationColor = randomColors.randomElement() ?? .orange
                            }
                        }
                        .offset(y: 10)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // 最近のチャット
                    VStack(alignment: .leading, spacing: 12) {
                        Text("最近のチャット")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                        
                        if viewModel.recentChats.isEmpty {
                            Text("まだチャットがありません")
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                        } else {
                            ForEach(viewModel.recentChats) { chatData in
                                NavigationLink(destination: ChatRoomView(chat: chatData.chat)) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Label(chatData.chat.name, systemImage: chatData.chat.isGroup ? "person.3.fill" : "message.fill")
                                        
                                        if !chatData.lastMessage.isEmpty {
                                            Text(chatData.lastMessage)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.large)
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("ホーム")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(themeManager)
            }
            .onAppear {
                viewModel.fetchRecentChats()
            }
        }
    }
}

// 最近のチャットデータ
struct RecentChatData: Identifiable {
    var id: String { chat.id ?? UUID().uuidString }
    let chat: Chat
    let lastMessage: String
}

// HomeViewModel
class HomeViewModel: ObservableObject {
    @Published var recentChats: [RecentChatData] = []
    
    private var db = Firestore.firestore()
    
    func fetchRecentChats() {
        guard let user = Auth.auth().currentUser else { return }
        let userId = user.uid
        let email = user.email?.lowercased() ?? ""
        
        // グループチャットを取得
        db.collection("chats")
            .whereField("members", arrayContains: userId)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                var chats: [Chat] = []
                
                if let documents = snapshot?.documents {
                    chats.append(contentsOf: documents.compactMap { try? $0.data(as: Chat.self) })
                }
                
                // DMも取得
                self.db.collection("chats")
                    .whereField("type", isEqualTo: "dm")
                    .whereField("memberEmails", arrayContains: email)
                    .getDocuments { snapshot, error in
                        if let documents = snapshot?.documents {
                            let dmChats = documents.compactMap { try? $0.data(as: Chat.self) }
                            for dm in dmChats {
                                if !chats.contains(where: { $0.id == dm.id }) {
                                    chats.append(dm)
                                }
                            }
                        }
                        
                        // 最新5件に制限して、最新メッセージを取得
                        let limitedChats = Array(chats.prefix(5))
                        self.fetchLastMessages(for: limitedChats)
                    }
            }
    }
    
    private func fetchLastMessages(for chats: [Chat]) {
        let group = DispatchGroup()
        var chatDataList: [RecentChatData] = []
        
        for chat in chats {
            guard let chatId = chat.id else { continue }
            group.enter()
            
            db.collection("chats").document(chatId).collection("messages")
                .order(by: "createdAt", descending: true)
                .limit(to: 1)
                .getDocuments { snapshot, error in
                    let lastMessage = snapshot?.documents.first?["text"] as? String ?? ""
                    chatDataList.append(RecentChatData(chat: chat, lastMessage: lastMessage))
                    group.leave()
                }
        }
        
        group.notify(queue: .main) {
            self.recentChats = chatDataList
        }
    }
}

#Preview {
    HomeView()
}
