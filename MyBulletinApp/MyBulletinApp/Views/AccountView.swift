//
//  AccountView.swift
//  MyBulletinApp
//
//  Created by 遠藤省吾 on R 8/01/24.
//

import SwiftUI
import FirebaseAuth

struct AccountView: View {
    @StateObject private var viewModel = AccountViewModel()
    @StateObject private var profileManager = UserProfileManager()
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showSettings = false
    @State private var showEditName = false
    @State private var editingName = ""
    
    var body: some View {
        NavigationView {
            Form {
                // ユーザー情報セクション
                Section(header: Text("ユーザー情報")) {
                    HStack {
                        Text("メールアドレス")
                        Spacer()
                        Text(viewModel.userEmail)
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("表示名")
                        Spacer()
                        Text(profileManager.displayName.isEmpty ? "未設定" : profileManager.displayName)
                            .foregroundColor(.gray)
                        
                        Button(action: {
                            editingName = profileManager.displayName
                            showEditName = true
                        }) {
                            Image(systemName: "pencil")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                // アクションセクション
                Section(header: Text("アカウント操作")) {
                    Button("パスワードをリセットする") {
                        viewModel.sendPasswordReset()
                    }
                    .foregroundColor(.blue)
                }
                
                // ログアウトボタン
                Section {
                    Button(action: {
                        do {
                            try Auth.auth().signOut()
                        } catch {
                            print("Sign out error: \(error.localizedDescription)")
                        }
                    }) {
                        Text("ログアウト")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("アカウント")
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
            .sheet(isPresented: $showEditName) {
                EditDisplayNameSheet(
                    displayName: $editingName,
                    isPresented: $showEditName,
                    onSave: { name in
                        profileManager.saveDisplayName(name)
                    }
                )
            }
            .onAppear {
                viewModel.fetchUser()
                profileManager.fetchProfile()
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(
                    title: Text("お知らせ"),
                    message: Text(viewModel.alertMessage ?? ""),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

struct EditDisplayNameSheet: View {
    @Binding var displayName: String
    @Binding var isPresented: Bool
    let onSave: (String) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("表示名"), footer: Text("チャットで表示される名前です")) {
                    TextField("表示名を入力", text: $displayName)
                }
            }
            .navigationTitle("表示名を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(displayName)
                        isPresented = false
                    }
                }
            }
        }
    }
}

#Preview {
    AccountView()
        .environmentObject(ThemeManager())
}
