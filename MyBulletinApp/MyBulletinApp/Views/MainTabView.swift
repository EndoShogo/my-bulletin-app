import SwiftUI

struct MainTabView: View {
    @StateObject private var themeManager = ThemeManager()
    
    var body: some View {
        TabView {
            // --- ホームタブ ---
            HomeView()
                .environmentObject(themeManager)
                .tabItem {
                    Label("ホーム", systemImage: "house.fill")
                }
            
            // --- グループチャットタブ ---
            NavigationView {
                GroupListView()
            }
            .tabItem {
                Label("グループ", systemImage: "person.3.fill")
            }
            
            // --- DMタブ ---
            NavigationView {
                DMListView()
            }
            .tabItem {
                Label("DM", systemImage: "message.fill")
            }

            // --- アカウントタブ ---
            AccountView()
                .environmentObject(themeManager)
                .tabItem {
                    Label("アカウント", systemImage: "person.fill")
                }
        }
        .preferredColorScheme(themeManager.colorScheme)
    }
}

#Preview {
    MainTabView()
}
