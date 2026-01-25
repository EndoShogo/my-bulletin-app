//
//  ThemeManager.swift
//  MyBulletinApp
//
//  テーマ管理（ライト/ダークモード）
//

import SwiftUI
import Combine

class ThemeManager: ObservableObject {
    @AppStorage("appTheme") var appTheme: String = "system"
    
    var colorScheme: ColorScheme? {
        switch appTheme {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil  // システム設定に従う
        }
    }
}
