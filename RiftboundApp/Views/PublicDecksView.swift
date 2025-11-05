import SwiftUI

struct PublicDecksView: View {
    @StateObject private var viewModel = PublicDecksViewModel()
    @State private var sortOption: PublicDeckSort = .trending

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.decks.isEmpty {
                    ProgressView("Loading public decks...")
                } else if viewModel.decks.isEmpty {
                    emptyStateView
                } else {
                    deckListView
                }
            }
            .navigationTitle("Public Decks")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Picker("Sort By", selection: $sortOption) {
                            ForEach(PublicDeckSort.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                    }
                }
            }
            .task {
                await viewModel.loadPublicDecks()
            }
            .refreshable {
                await viewModel.loadPublicDecks()
            }
            .onChange(of: sortOption) { _, newSort in
                viewModel.sortDecks(by: newSort)
            }
        }
    }

    private var deckListView: some View {
        List(viewModel.sortedDecks) { deckWithVotes in
            NavigationLink(destination: PublicDeckDetailView(deck: deckWithVotes.deck, votes: deckWithVotes.voteCount)) {
                PublicDeckRowView(
                    deck: deckWithVotes.deck,
                    voteCount: deckWithVotes.voteCount,
                    hasUserVoted: deckWithVotes.hasUserVoted,
                    onVote: {
                        Task {
                            await viewModel.toggleVote(for: deckWithVotes.deck)
                        }
                    }
                )
            }
        }
        .listStyle(.plain)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "globe")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Public Decks")
                .font(.headline)

            Text("Be the first to publish a deck!")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Public Deck Row

struct PublicDeckRowView: View {
    let deck: RBDeck
    let voteCount: Int
    let hasUserVoted: Bool
    let onVote: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(deck.title)
                    .font(.headline)

                Text(deck.legendChampionTag)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    Label("\(deck.countMain)", systemImage: "rectangle.stack")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("•")
                        .foregroundStyle(.secondary)

                    if let description = deck.description, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            Button(action: onVote) {
                VStack(spacing: 2) {
                    Image(systemName: hasUserVoted ? "arrow.up.circle.fill" : "arrow.up.circle")
                        .font(.title3)
                        .foregroundStyle(hasUserVoted ? .blue : .secondary)

                    Text("\(voteCount)")
                        .font(.caption.bold())
                        .foregroundStyle(hasUserVoted ? .blue : .secondary)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Public Deck Detail

struct PublicDeckDetailView: View {
    let deck: RBDeck
    let votes: Int

    @StateObject private var viewModel: DeckDetailViewModel
    @State private var showingImport = false

    init(deck: RBDeck, votes: Int) {
        self.deck = deck
        self.votes = votes
        _viewModel = StateObject(wrappedValue: DeckDetailViewModel(deckID: deck.id))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Deck Info Header
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(deck.title)
                            .font(.title2.bold())

                        Text("by \(deck.ownerUserRef.recordID.recordName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(spacing: 2) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                        Text("\(votes)")
                            .font(.caption.bold())
                    }
                }

                Text(deck.legendChampionTag)
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)

                if let description = deck.description {
                    Text(description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Label("Main: \(deck.countMain)", systemImage: "rectangle.stack")
                    Label("Side: \(deck.countSide)", systemImage: "rectangle.on.rectangle")
                    Label("Runes: \(deck.countRunes)", systemImage: "diamond")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.systemGroupedBackground))

            Divider()

            // Deck List (Read-Only)
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    Section("Main Deck") {
                        ForEach(viewModel.itemsForSection(.main)) { item in
                            DeckCardRowView(item: item, card: viewModel.cardForItem(item))
                        }
                    }

                    if !viewModel.itemsForSection(.side).isEmpty {
                        Section("Sideboard") {
                            ForEach(viewModel.itemsForSection(.side)) { item in
                                DeckCardRowView(item: item, card: viewModel.cardForItem(item))
                            }
                        }
                    }

                    Section("Runes") {
                        ForEach(viewModel.itemsForSection(.rune)) { item in
                            DeckCardRowView(item: item, card: viewModel.cardForItem(item))
                        }
                    }
                }
                .listStyle(.grouped)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingImport = true
                } label: {
                    Label("Import Copy", systemImage: "square.and.arrow.down")
                }
            }
        }
        .task {
            await viewModel.loadDeck()
        }
        .alert("Import Deck", isPresented: $showingImport) {
            Button("Cancel", role: .cancel) { }
            Button("Import") {
                // TODO: Create a copy in user's private decks
            }
        } message: {
            Text("Create a copy of this deck in your collection?")
        }
    }
}

#Preview {
    PublicDecksView()
        .environmentObject(AppState())
}
