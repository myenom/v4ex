import SwiftUI

struct NodesView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = NodesViewModel()
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                SearchBar(text: $searchText)
                    .padding()

                if viewModel.isLoading && viewModel.nodes.isEmpty {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
                            ForEach(0..<12) { _ in
                                NodeSkeletonView()
                            }
                        }
                        .padding()
                    }
                } else if let error = viewModel.errorMessage {
                    ErrorView(message: error, retryAction: {
                        Task { await viewModel.loadNodes() }
                    })
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
                            ForEach(filteredNodes) { node in
                                NavigationLink(destination: NodeDetailView(node: node)) {
                                    NodeCardView(node: node)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Nodes")
        }
        .onAppear {
            if let token = appState.getToken() {
                viewModel.setToken(token)
                Task { await viewModel.loadNodes() }
            }
        }
    }

    private var filteredNodes: [Node] {
        if searchText.isEmpty {
            return viewModel.nodes
        } else {
            return viewModel.nodes.filter { node in
                node.title.localizedCaseInsensitiveContains(searchText) ||
                node.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

class NodesViewModel: ObservableObject {
    @Published var nodes: [Node] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var apiService: V2EXAPIService?

    func setToken(_ token: String) {
        apiService = V2EXAPIService(token: token)
    }

    @MainActor
    func loadNodes() async {
        guard let apiService = apiService else { return }

        isLoading = true
        errorMessage = nil

        do {
            nodes = try await apiService.fetchAllNodes()
        } catch {
            errorMessage = "Failed to load nodes. Please try again."
        }

        isLoading = false
    }
}

struct NodeCardView: View {
    let node: Node

    var body: some View {
        VStack(spacing: 8) {
            if let avatarURL = node.avatarLarge ?? node.avatar {
                AsyncImage(url: URL(string: "https:" + avatarURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(String(node.title.prefix(1)))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    )
            }

            Text(node.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            if let topics = node.topics {
                Text("\(topics) topics")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct NodeSkeletonView: View {
    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 50)

            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 14)
                .cornerRadius(4)

            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 10)
                .frame(width: 80)
                .cornerRadius(4)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField("Search nodes", text: $text)
                .textFieldStyle(PlainTextFieldStyle())

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}
