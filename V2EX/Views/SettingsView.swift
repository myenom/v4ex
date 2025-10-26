import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var useSystemTheme: Bool
    @State private var isDarkMode: Bool

    init() {
        let appState = AppState()
        _useSystemTheme = State(initialValue: appState.useSystemTheme)
        _isDarkMode = State(initialValue: appState.isDarkMode)
    }

    var body: some View {
        Form {
            Section(header: Text("Appearance")) {
                Toggle("Use System Theme", isOn: $useSystemTheme)
                    .onChange(of: useSystemTheme) { newValue in
                        appState.saveThemePreference(useSystem: newValue, isDark: isDarkMode)
                    }

                if !useSystemTheme {
                    Toggle("Dark Mode", isOn: $isDarkMode)
                        .onChange(of: isDarkMode) { newValue in
                            appState.saveThemePreference(useSystem: useSystemTheme, isDark: newValue)
                        }
                }
            }

            Section(header: Text("About")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }

                Link(destination: URL(string: "https://v2ex.com")!) {
                    HStack {
                        Text("V2EX Website")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundColor(.blue)
                    }
                }

                Link(destination: URL(string: "https://v2ex.com/help/api")!) {
                    HStack {
                        Text("API Documentation")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundColor(.blue)
                    }
                }
            }

            Section(header: Text("Token Management")) {
                Link(destination: URL(string: "https://v2ex.com/settings/tokens")!) {
                    HStack {
                        Text("Manage Tokens")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundColor(.blue)
                    }
                }

                Button(action: {
                    appState.logout()
                }) {
                    HStack {
                        Text("Remove Token & Logout")
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            useSystemTheme = appState.useSystemTheme
            isDarkMode = appState.isDarkMode
        }
    }
}
