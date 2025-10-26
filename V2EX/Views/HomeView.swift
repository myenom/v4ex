import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    Picker("Feed Type", selection: $viewModel.selectedFeed) {
                        Text("Latest").tag(0)
                        Text("Hot").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()

                    if viewModel.isLoading && viewModel.topics.isEmpty {
                        VStack(spacing: 20) {
                            ForEach(0..<5) { _ in
                                TopicSkeletonView()
                            }
                        }
                        .padding(.horizontal)
                    } else if let error = viewModel.errorMessage {
                        ErrorView(message: error, retryAction: {
                            Task { await viewModel.loadTopics() }
                        })
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.topics) { topic in
                                NavigationLink(destination: TopicDetailView(topic: topic)) {
                                    TopicRowView(topic: topic)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("V2EX")
            .refreshable {
                await viewModel.loadTopics()
            }
        }
        .onAppear {
            if let token = appState.getToken() {
                viewModel.setToken(token)
                Task { await viewModel.loadTopics() }
            }
        }
        .onChange(of: viewModel.selectedFeed) { _ in
            Task { await viewModel.loadTopics() }
        }
    }
}

class HomeViewModel: ObservableObject {
    @Published var topics: [Topic] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedFeed = 0

    private var apiService: V2EXAPIService?

    func setToken(_ token: String) {
        apiService = V2EXAPIService(token: token)
    }

    @MainActor
    func loadTopics() async {
        guard let apiService = apiService else { return }

        isLoading = true
        errorMessage = nil

        do {
            if selectedFeed == 0 {
                topics = try await apiService.fetchLatestTopics()
            } else {
                topics = try await apiService.fetchHotTopics()
            }
        } catch {
            errorMessage = "Failed to load topics. Please try again."
        }

        isLoading = false
    }
}

struct TopicRowView: View {
    let topic: Topic

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: topic.member?.avatar ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(topic.member?.username ?? "Unknown")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        if let nodeName = topic.node?.title {
                            Text(nodeName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(timeAgo(from: topic.created))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if let replies = topic.replies, replies > 0 {
                    VStack {
                        Text("\(replies)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    .frame(minWidth: 30)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
            }

            Text(topic.title)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(3)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    private func timeAgo(from timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct TopicSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 100, height: 12)
                        .cornerRadius(4)

                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 150, height: 10)
                        .cornerRadius(4)
                }

                Spacer()
            }

            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 16)
                .cornerRadius(4)

            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 16)
                .frame(maxWidth: .infinity)
                .cornerRadius(4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct ErrorView: View {
    let message: String
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: retryAction) {
                Text("Retry")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 120, height: 40)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}
