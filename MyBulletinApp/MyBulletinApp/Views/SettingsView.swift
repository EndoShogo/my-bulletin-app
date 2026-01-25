//
//  SettingsView.swift
//  MyBulletinApp
//
//  設定画面（テーマ変更など）
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("テーマ")) {
                    Picker("カラーテーマ", selection: $themeManager.appTheme) {
                        Text("システム設定").tag("system")
                        Text("ライト（白）").tag("light")
                        Text("ダーク（黒）").tag("dark")
                    }
                    .pickerStyle(.inline)
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(ThemeManager())
}
