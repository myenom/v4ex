import SwiftUI

struct TopicDetailView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel: TopicDetailViewModel
    @State private var showShareSheet = false

    init(topic: Topic) {
        _viewModel = StateObject(wrappedValue: TopicDetailViewModel(topic: topic))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                TopicHeaderView(
                    topic: viewModel.topic,
                    isFavorite: viewModel.isFavorite,
                    onFavoriteToggle: {
                        Task { await viewModel.toggleFavorite() }
                    }
                )
                .padding()

                Divider()

                if let content = viewModel.topic.contentRendered {
                    Text(content.htmlToString())
                        .font(.body)
                        .padding()
                }

                Divider()
                    .padding(.top, 10)

                HStack {
                    Text("Replies")
                        .font(.headline)
                    if let count = viewModel.topic.replies {
                        Text("(\(count))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 10)

                if viewModel.isLoadingReplies && viewModel.replies.isEmpty {
                    ForEach(0..<3) { _ in
                        ReplySkeletonView()
                    }
                } else if viewModel.replies.isEmpty {
                    Text("No replies yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.replies) { reply in
                            ReplyRowView(reply: reply)
                            Divider()
                        }
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showShareSheet = true }) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = URL(string: viewModel.topic.url) {
                ShareSheet(items: [url])
            }
        }
        .onAppear {
            if let token = appState.getToken() {
                viewModel.setToken(token, userId: appState.currentUser?.username ?? "")
                Task {
                    await viewModel.loadReplies()
                    await viewModel.checkFavoriteStatus()
                    await viewModel.addToReadingHistory()
                }
            }
        }
    }
}

class TopicDetailViewModel: ObservableObject {
    @Published var topic: Topic
    @Published var replies: [Reply] = []
    @Published var isLoadingReplies = false
    @Published var isFavorite = false

    private var apiService: V2EXAPIService?
    private var supabaseService = SupabaseService()
    private var userId: String?

    init(topic: Topic) {
        self.topic = topic
    }

    func setToken(_ token: String, userId: String) {
        apiService = V2EXAPIService(token: token)
        self.userId = userId
    }

    @MainActor
    func loadReplies() async {
        guard let apiService = apiService else { return }

        isLoadingReplies = true

        do {
            replies = try await apiService.fetchTopicReplies(id: topic.id)
        } catch {
            print("Error loading replies: \(error)")
        }

        isLoadingReplies = false
    }

    @MainActor
    func checkFavoriteStatus() async {
        guard let userId = userId else { return }

        do {
            isFavorite = try await supabaseService.isFavorite(userId: userId, topicId: topic.id)
        } catch {
            print("Error checking favorite status: \(error)")
        }
    }

    @MainActor
    func toggleFavorite() async {
        guard let userId = userId else { return }

        do {
            if isFavorite {
                try await supabaseService.removeFavorite(userId: userId, topicId: topic.id)
                isFavorite = false
            } else {
                try await supabaseService.addFavorite(userId: userId, topic: topic)
                isFavorite = true
            }
        } catch {
            print("Error toggling favorite: \(error)")
        }
    }

    @MainActor
    func addToReadingHistory() async {
        guard let userId = userId else { return }

        do {
            try await supabaseService.addToReadingHistory(userId: userId, topic: topic)
        } catch {
            print("Error adding to reading history: \(error)")
        }
    }
}

struct TopicHeaderView: View {
    let topic: Topic
    let isFavorite: Bool
    let onFavoriteToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(topic.title)
                .font(.title2)
                .fontWeight(.bold)

            HStack(spacing: 12) {
                AsyncImage(url: URL(string: topic.member?.avatar ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 36, height: 36)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(topic.member?.username ?? "Unknown")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    HStack(spacing: 6) {
                        if let nodeTitle = topic.node?.title {
                            Text(nodeTitle)
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

                Button(action: onFavoriteToggle) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .foregroundColor(isFavorite ? .yellow : .gray)
                        .font(.system(size: 20))
                }
            }
        }
    }

    private func timeAgo(from timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct ReplyRowView: View {
    let reply: Reply

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: URL(string: reply.member?.avatar ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(reply.member?.username ?? "Unknown")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    Text(timeAgo(from: reply.created))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(reply.contentRendered?.htmlToString() ?? reply.content)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
        }
        .padding()
    }

    private func timeAgo(from timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct ReplySkeletonView: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 6) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 12)
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

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

extension String {
    func htmlToString() -> String {
        guard let data = self.data(using: .utf8) else { return self }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        guard let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil) else {
            return self
        }
        return attributedString.string
    }
}
