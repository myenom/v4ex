import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = NotificationsViewModel()

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading && viewModel.notifications.isEmpty {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(0..<5) { _ in
                                NotificationSkeletonView()
                            }
                        }
                        .padding()
                    }
                } else if let error = viewModel.errorMessage {
                    ErrorView(message: error, retryAction: {
                        Task { await viewModel.loadNotifications() }
                    })
                } else if viewModel.notifications.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        Text("No notifications")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text("You're all caught up!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    List {
                        ForEach(viewModel.notifications) { notification in
                            NotificationRowView(notification: notification)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        Task {
                                            await viewModel.deleteNotification(notification)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Notifications")
            .refreshable {
                await viewModel.loadNotifications()
            }
        }
        .onAppear {
            if let token = appState.getToken() {
                viewModel.setToken(token)
                Task { await viewModel.loadNotifications() }
            }
        }
    }
}

class NotificationsViewModel: ObservableObject {
    @Published var notifications: [Notification] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var apiService: V2EXAPIService?

    func setToken(_ token: String) {
        apiService = V2EXAPIService(token: token)
    }

    @MainActor
    func loadNotifications() async {
        guard let apiService = apiService else { return }

        isLoading = true
        errorMessage = nil

        do {
            notifications = try await apiService.fetchNotifications()
        } catch {
            errorMessage = "Failed to load notifications. Please try again."
        }

        isLoading = false
    }

    @MainActor
    func deleteNotification(_ notification: Notification) async {
        guard let apiService = apiService else { return }

        notifications.removeAll { $0.id == notification.id }

        do {
            try await apiService.deleteNotification(id: notification.id)
        } catch {
            await loadNotifications()
        }
    }
}

struct NotificationRowView: View {
    let notification: Notification

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: URL(string: notification.member?.avatar ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(notification.member?.username ?? "Unknown")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Spacer()

                    Text(timeAgo(from: notification.created))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(notification.text)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 8)
    }

    private func timeAgo(from timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct NotificationSkeletonView: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 6) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 12)
                    .cornerRadius(4)

                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 40)
                    .cornerRadius(4)
            }
        }
        .padding()
    }
}
