import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var appState: AppState
    @State private var token: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()

                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)

                Text("V2EX")
                    .font(.system(size: 48, weight: .bold))

                Text("Connect with the community")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                VStack(alignment: .leading, spacing: 15) {
                    Text("Personal Access Token")
                        .font(.headline)

                    SecureField("Enter your V2EX token", text: $token)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    Link("Get your token from V2EX Settings", destination: URL(string: "https://v2ex.com/settings/tokens")!)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 30)

                Button(action: authenticate) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Sign In")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(token.isEmpty ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.horizontal, 30)
                .disabled(token.isEmpty || isLoading)

                VStack(spacing: 8) {
                    Text("New to V2EX?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Link("Create an account", destination: URL(string: "https://v2ex.com/signup")!)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Spacer()
            }
            .navigationBarHidden(true)
            .alert("Authentication Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Failed to authenticate. Please check your token.")
            }
        }
    }

    private func authenticate() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let apiService = V2EXAPIService(token: token)
                let member = try await apiService.fetchMember()

                await MainActor.run {
                    appState.saveToken(token)
                    appState.currentUser = member
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isLoading = false
                }
            }
        }
    }
}
