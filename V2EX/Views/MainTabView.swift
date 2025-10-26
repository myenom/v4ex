import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0
    @State private var notificationCount = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            NodesView()
                .tabItem {
                    Label("Nodes", systemImage: "square.grid.2x2.fill")
                }
                .tag(1)

            NotificationsView()
                .tabItem {
                    Label("Notifications", systemImage: "bell.fill")
                }
                .badge(notificationCount > 0 ? notificationCount : nil)
                .tag(2)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
        }
        .preferredColorScheme(appState.useSystemTheme ? nil : (appState.isDarkMode ? .dark : .light))
    }
}
