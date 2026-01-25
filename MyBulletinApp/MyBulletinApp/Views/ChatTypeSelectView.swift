//
//  ChatTypeSelectView.swift
//  MyBulletinApp
//
//  グループチャットとDMの選択画面
//

import SwiftUI

struct ChatTypeSelectView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()
                
                // グループチャットボタン (Apple標準ボタン)
                NavigationLink(destination: GroupListView()) {
                    Label("グループチャット", systemImage: "person.3.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                // DMボタン (Apple標準ボタン)
                NavigationLink(destination: DMListView()) {
                    Label("ダイレクトメッセージ", systemImage: "message.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                
                Spacer()
                Spacer()
            }
            .padding(.horizontal, 24)
            .navigationTitle("チャット")
        }
    }
}

#Preview {
    ChatTypeSelectView()
}
