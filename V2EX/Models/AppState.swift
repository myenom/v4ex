import Foundation
import Combine

class AppState: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: Member?
    @Published var isDarkMode: Bool = false
    @Published var useSystemTheme: Bool = true

    private let tokenKey = "v2ex_access_token"

    init() {
        loadAuthenticationState()
        loadThemePreference()
    }

    func saveToken(_ token: String) {
        KeychainHelper.save(token, forKey: tokenKey)
        isAuthenticated = true
    }

    func loadAuthenticationState() {
        if let token = KeychainHelper.load(forKey: tokenKey), !token.isEmpty {
            isAuthenticated = true
        }
    }

    func getToken() -> String? {
        return KeychainHelper.load(forKey: tokenKey)
    }

    func logout() {
        KeychainHelper.delete(forKey: tokenKey)
        isAuthenticated = false
        currentUser = nil
    }

    func loadThemePreference() {
        if let useSystem = UserDefaults.standard.object(forKey: "useSystemTheme") as? Bool {
            useSystemTheme = useSystem
        }
        if let isDark = UserDefaults.standard.object(forKey: "isDarkMode") as? Bool {
            isDarkMode = isDark
        }
    }

    func saveThemePreference(useSystem: Bool, isDark: Bool) {
        useSystemTheme = useSystem
        isDarkMode = isDark
        UserDefaults.standard.set(useSystem, forKey: "useSystemTheme")
        UserDefaults.standard.set(isDark, forKey: "isDarkMode")
    }
}
