//
//  DMListView.swift
//  MyBulletinApp
//
//  DM一覧画面
//

import SwiftUI
import Combine
import FirebaseAuth

struct DMListView: View {
    @StateObject private var viewModel = ChatListViewModel()
    @State private var showNewDMSheet = false
    @State private var navigateToChat: Chat?
    
    var body: some View {
        List {
            ForEach(viewModel.dms) { dm in
                NavigationLink(destination: ChatRoomView(chat: dm)) {
                    HStack {
                        Image(systemName: "message.fill")
                            .foregroundColor(.purple)
                            .frame(width: 30)
                        
                        VStack(alignment: .leading) {
                            Text(otherEmail(for: dm))
                                .font(.headline)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("ダイレクトメッセージ")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showNewDMSheet = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            }
        }
        .onAppear {
            viewModel.fetchDMs()
        }
        .sheet(isPresented: $showNewDMSheet) {
            NewDMSheet(viewModel: viewModel, isPresented: $showNewDMSheet, navigateToChat: $navigateToChat)
        }
        .background(
            NavigationLink(
                destination: Group {
                    if let chat = navigateToChat {
                        ChatRoomView(chat: chat)
                    }
                },
                isActive: Binding(
                    get: { navigateToChat != nil },
                    set: { if !$0 { navigateToChat = nil } }
                )
            ) { EmptyView() }
        )
        .alert("お知らせ", isPresented: $viewModel.showAlert) {
            Button("OK") {}
        } message: {
            Text(viewModel.alertMessage ?? "")
        }
    }
    
    private func otherEmail(for dm: Chat) -> String {
        let myEmail = Auth.auth().currentUser?.email?.lowercased() ?? ""
        return dm.memberEmails?.first(where: { $0 != myEmail }) ?? "不明"
    }
}

struct NewDMSheet: View {
    @ObservedObject var viewModel: ChatListViewModel
    @Binding var isPresented: Bool
    @Binding var navigateToChat: Chat?
    @State private var email = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("相手のメールアドレス")) {
                    TextField("example@email.com", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                }
            }
            .navigationTitle("新規DM")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("開始") {
                        viewModel.startDM(email: email) { chat in
                            isPresented = false
                            if let chat = chat {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    navigateToChat = chat
                                }
                            }
                        }
                    }
                    .disabled(email.isEmpty || !email.contains("@"))
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        DMListView()
    }
}
