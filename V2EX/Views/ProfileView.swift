import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showLogoutAlert = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    if let user = appState.currentUser {
                        VStack(spacing: 15) {
                            AsyncImage(url: URL(string: user.avatar ?? "")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                            }
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())

                            Text(user.username)
                                .font(.title2)
                                .fontWeight(.bold)

                            if let bio = user.bio, !bio.isEmpty {
                                Text(bio)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }

                            HStack(spacing: 20) {
                                if let website = user.website, !website.isEmpty {
                                    Label(website, systemImage: "link")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }

                                if let location = user.location, !location.isEmpty {
                                    Label(location, systemImage: "location")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding()
                    }

                    Divider()

                    VStack(spacing: 0) {
                        NavigationLink(destination: FavoritesView()) {
                            ProfileMenuRow(icon: "star.fill", title: "Favorites", iconColor: .yellow)
                        }

                        Divider()
                            .padding(.leading, 60)

                        NavigationLink(destination: ReadingHistoryView()) {
                            ProfileMenuRow(icon: "clock.fill", title: "Reading History", iconColor: .blue)
                        }

                        Divider()
                            .padding(.leading, 60)

                        NavigationLink(destination: SubscriptionsView()) {
                            ProfileMenuRow(icon: "bookmark.fill", title: "Subscribed Nodes", iconColor: .green)
                        }

                        Divider()
                            .padding(.leading, 60)

                        NavigationLink(destination: SettingsView()) {
                            ProfileMenuRow(icon: "gear", title: "Settings", iconColor: .gray)
                        }
                    }
                    .padding(.vertical)

                    Button(action: { showLogoutAlert = true }) {
                        HStack {
                            Image(systemName: "arrow.right.square")
                                .foregroundColor(.red)
                                .frame(width: 30)

                            Text("Logout")
                                .foregroundColor(.red)

                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemBackground))
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Profile")
            .alert("Logout", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Logout", role: .destructive) {
                    appState.logout()
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
        }
        .onAppear {
            if let token = appState.getToken() {
                viewModel.setToken(token)
            }
        }
    }
}

class ProfileViewModel: ObservableObject {
    private var apiService: V2EXAPIService?

    func setToken(_ token: String) {
        apiService = V2EXAPIService(token: token)
    }
}

struct ProfileMenuRow: View {
    let icon: String
    let title: String
    let iconColor: Color

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 30)

            Text(title)
                .foregroundColor(.primary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

struct FavoritesView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = FavoritesViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.favorites.isEmpty {
                ProgressView()
            } else if viewModel.favorites.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "star")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)

                    Text("No favorites yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            } else {
                List(viewModel.favorites, id: \.topicId) { favorite in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(favorite.topicTitle)
                            .font(.body)
                            .fontWeight(.medium)

                        if let nodeName = favorite.nodeName {
                            Text(nodeName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Favorites")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let userId = appState.currentUser?.username {
                viewModel.setUserId(userId)
                Task { await viewModel.loadFavorites() }
            }
        }
    }
}

class FavoritesViewModel: ObservableObject {
    @Published var favorites: [FavoriteRecord] = []
    @Published var isLoading = false

    private var supabaseService = SupabaseService()
    private var userId: String?

    func setUserId(_ userId: String) {
        self.userId = userId
    }

    @MainActor
    func loadFavorites() async {
        guard let userId = userId else { return }

        isLoading = true

        do {
            favorites = try await supabaseService.getFavorites(userId: userId)
        } catch {
            print("Error loading favorites: \(error)")
        }

        isLoading = false
    }
}

struct ReadingHistoryView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = ReadingHistoryViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.history.isEmpty {
                ProgressView()
            } else if viewModel.history.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "clock")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)

                    Text("No reading history")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            } else {
                List(viewModel.history, id: \.topicId) { history in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(history.topicTitle)
                            .font(.body)
                            .fontWeight(.medium)

                        if let lastRead = history.lastReadAt {
                            Text(lastRead)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Reading History")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let userId = appState.currentUser?.username {
                viewModel.setUserId(userId)
                Task { await viewModel.loadHistory() }
            }
        }
    }
}

class ReadingHistoryViewModel: ObservableObject {
    @Published var history: [ReadingHistoryRecord] = []
    @Published var isLoading = false

    private var supabaseService = SupabaseService()
    private var userId: String?

    func setUserId(_ userId: String) {
        self.userId = userId
    }

    @MainActor
    func loadHistory() async {
        guard let userId = userId else { return }

        isLoading = true

        do {
            history = try await supabaseService.getReadingHistory(userId: userId)
        } catch {
            print("Error loading history: \(error)")
        }

        isLoading = false
    }
}

struct SubscriptionsView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = SubscriptionsViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.subscriptions.isEmpty {
                ProgressView()
            } else if viewModel.subscriptions.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "bookmark")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)

                    Text("No subscriptions yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            } else {
                List(viewModel.subscriptions, id: \.nodeId) { subscription in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(subscription.nodeTitle)
                            .font(.body)
                            .fontWeight(.medium)

                        Text(subscription.nodeName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Subscribed Nodes")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let userId = appState.currentUser?.username {
                viewModel.setUserId(userId)
                Task { await viewModel.loadSubscriptions() }
            }
        }
    }
}

class SubscriptionsViewModel: ObservableObject {
    @Published var subscriptions: [NodeSubscriptionRecord] = []
    @Published var isLoading = false

    private var supabaseService = SupabaseService()
    private var userId: String?

    func setUserId(_ userId: String) {
        self.userId = userId
    }

    @MainActor
    func loadSubscriptions() async {
        guard let userId = userId else { return }

        isLoading = true

        do {
            subscriptions = try await supabaseService.getNodeSubscriptions(userId: userId)
        } catch {
            print("Error loading subscriptions: \(error)")
        }

        isLoading = false
    }
}
