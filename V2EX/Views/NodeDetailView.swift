import SwiftUI

struct NodeDetailView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel: NodeDetailViewModel
    @State private var isSubscribed = false

    init(node: Node) {
        _viewModel = StateObject(wrappedValue: NodeDetailViewModel(node: node))
    }

    var body: some View {
        VStack(spacing: 0) {
            NodeHeaderView(node: viewModel.node)
                .padding()

            Divider()

            if viewModel.isLoading && viewModel.topics.isEmpty {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(0..<5) { _ in
                            TopicSkeletonView()
                        }
                    }
                    .padding()
                }
            } else if let error = viewModel.errorMessage {
                ErrorView(message: error, retryAction: {
                    Task { await viewModel.loadTopics() }
                })
            } else if viewModel.topics.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)

                    Text("No topics in this node yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.topics) { topic in
                            NavigationLink(destination: TopicDetailView(topic: topic)) {
                                TopicRowView(topic: topic)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }

                        if viewModel.hasMorePages {
                            Button(action: {
                                Task { await viewModel.loadMoreTopics() }
                            }) {
                                if viewModel.isLoadingMore {
                                    ProgressView()
                                } else {
                                    Text("Load More")
                                        .fontWeight(.medium)
                                }
                            }
                            .frame(height: 44)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    Task { await viewModel.toggleSubscription() }
                }) {
                    Image(systemName: viewModel.isSubscribed ? "star.fill" : "star")
                        .foregroundColor(viewModel.isSubscribed ? .yellow : .gray)
                }
            }
        }
        .onAppear {
            if let token = appState.getToken() {
                viewModel.setToken(token, userId: appState.currentUser?.username ?? "")
                Task {
                    await viewModel.loadTopics()
                    await viewModel.checkSubscriptionStatus()
                }
            }
        }
    }
}

class NodeDetailViewModel: ObservableObject {
    @Published var node: Node
    @Published var topics: [Topic] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    @Published var isSubscribed = false
    @Published var currentPage = 1
    @Published var hasMorePages = true

    private var apiService: V2EXAPIService?
    private var supabaseService = SupabaseService()
    private var userId: String?

    init(node: Node) {
        self.node = node
    }

    func setToken(_ token: String, userId: String) {
        apiService = V2EXAPIService(token: token)
        self.userId = userId
    }

    @MainActor
    func loadTopics() async {
        guard let apiService = apiService else { return }

        isLoading = true
        errorMessage = nil
        currentPage = 1

        do {
            topics = try await apiService.fetchNodeTopics(name: node.name, page: currentPage)
            hasMorePages = topics.count >= 20
        } catch {
            errorMessage = "Failed to load topics. Please try again."
        }

        isLoading = false
    }

    @MainActor
    func loadMoreTopics() async {
        guard let apiService = apiService, !isLoadingMore else { return }

        isLoadingMore = true
        currentPage += 1

        do {
            let newTopics = try await apiService.fetchNodeTopics(name: node.name, page: currentPage)
            topics.append(contentsOf: newTopics)
            hasMorePages = newTopics.count >= 20
        } catch {
            currentPage -= 1
        }

        isLoadingMore = false
    }

    @MainActor
    func checkSubscriptionStatus() async {
        guard let userId = userId else { return }

        do {
            let subscriptions = try await supabaseService.getNodeSubscriptions(userId: userId)
            isSubscribed = subscriptions.contains { $0.nodeId == node.id }
        } catch {
            print("Error checking subscription: \(error)")
        }
    }

    @MainActor
    func toggleSubscription() async {
        guard let userId = userId else { return }

        do {
            if isSubscribed {
                try await supabaseService.unsubscribeFromNode(userId: userId, nodeId: node.id)
                isSubscribed = false
            } else {
                try await supabaseService.subscribeToNode(userId: userId, node: node)
                isSubscribed = true
            }
        } catch {
            print("Error toggling subscription: \(error)")
        }
    }
}

struct NodeHeaderView: View {
    let node: Node

    var body: some View {
        HStack(spacing: 15) {
            if let avatarURL = node.avatarLarge ?? node.avatar {
                AsyncImage(url: URL(string: "https:" + avatarURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(String(node.title.prefix(1)))
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    )
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(node.title)
                    .font(.title3)
                    .fontWeight(.bold)

                Text(node.name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let topics = node.topics {
                    Text("\(topics) topics")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
    }
}
