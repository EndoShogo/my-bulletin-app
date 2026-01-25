//
//  MyBulletinAppApp.swift
//  MyBulletinApp
//
//  Created by 遠藤省吾 on R 8/01/17.
//

import SwiftUI
import FirebaseCore
import UIKit // UIKitフレームワークをインポート

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    // UITabBarの外観をカスタマイズ
    let tabBarAppearance = UITabBarAppearance()
    tabBarAppearance.configureWithTransparentBackground() // 背景を透明に設定
    // 好みに応じてマテリアル効果を変更
    tabBarAppearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial) // 薄いぼかし効果
    // tabBarAppearance.backgroundColor = UIColor(white: 1, alpha: 0.1) // わずかに色を付けて視認性を上げることも可能

    // スクロール時のタブバーの見た目を標準と同じにする (重要)
    UITabBar.appearance().standardAppearance = tabBarAppearance
    // iOS 15から導入された新しいプロパティ for non-scrollable content
    UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance

    return true
  }
}

@main
struct MyBulletinAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // initブロックは不要になりましたが、もし将来的にSwiftUIでのみ可能な
    // グローバルな設定をする場合はここに記述します。
    init() {
        // ここでTabViewのItemの色などを設定することも可能です
        // 例えば、選択時の色:
        // UITabBar.appearance().tintColor = UIColor.blue
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
