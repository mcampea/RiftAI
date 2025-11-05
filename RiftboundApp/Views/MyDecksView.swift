import SwiftUI
import SwiftData

struct MyDecksView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = MyDecksViewModel()

    @State private var showingCreateDeck = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading decks...")
                } else if viewModel.decks.isEmpty {
                    emptyStateView
                } else {
                    deckListView
                }
            }
            .navigationTitle("My Decks")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreateDeck = true
                    } label: {
                        Label("New Deck", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateDeck) {
                CreateDeckView { newDeck in
                    await viewModel.createDeck(newDeck)
                }
            }
            .task {
                await viewModel.loadDecks()
            }
            .refreshable {
                await viewModel.refreshDecks()
            }
        }
    }

    private var deckListView: some View {
        List {
            ForEach(viewModel.decks) { deck in
                NavigationLink(destination: DeckDetailView(deckID: deck.id)) {
                    DeckRowView(deck: deck)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        Task {
                            await viewModel.deleteDeck(deck)
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }

                    Button {
                        Task {
                            await viewModel.togglePublic(deck)
                        }
                    } label: {
                        Label(deck.isPublic ? "Unpublish" : "Publish",
                              systemImage: deck.isPublic ? "lock" : "globe")
                    }
                    .tint(.blue)
                }
            }
        }
        .listStyle(.plain)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.stack")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Decks Yet")
                .font(.headline)

            Text("Tap + to create your first deck")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                showingCreateDeck = true
            } label: {
                Label("Create Deck", systemImage: "plus")
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
            }
            .padding(.top)
        }
    }
}

// MARK: - Deck Row View

struct DeckRowView: View {
    let deck: RBDeck

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(deck.title)
                    .font(.headline)

                Spacer()

                if deck.isPublic {
                    Image(systemName: "globe")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }

            Text(deck.legendChampionTag)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Label("\(deck.countMain)", systemImage: "rectangle.stack")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if deck.countSide > 0 {
                    Text("•")
                        .foregroundStyle(.secondary)
                    Label("\(deck.countSide)", systemImage: "rectangle.on.rectangle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text("•")
                    .foregroundStyle(.secondary)
                Label("\(deck.countRunes)", systemImage: "diamond")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Create Deck View

struct CreateDeckView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    @State private var title = ""
    @State private var description = ""
    @State private var championTag = ""
    @State private var selectedDomains: Set<String> = []
    @State private var isCreating = false

    let availableDomains = ["Fury", "Mind", "Valor", "Spirit", "Wild"]
    let onSave: (RBDeck) async -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Deck Info") {
                    TextField("Deck Name", text: $title)
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Legend") {
                    TextField("Champion Tag", text: $championTag)
                        .textInputAutocapitalization(.words)

                    Text("Select Domains")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(availableDomains, id: \.self) { domain in
                        Toggle(domain, isOn: Binding(
                            get: { selectedDomains.contains(domain) },
                            set: { isOn in
                                if isOn {
                                    selectedDomains.insert(domain)
                                } else {
                                    selectedDomains.remove(domain)
                                }
                            }
                        ))
                    }
                }
            }
            .navigationTitle("New Deck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            await createDeck()
                        }
                    }
                    .disabled(!isValid || isCreating)
                }
            }
        }
    }

    private var isValid: Bool {
        !title.isEmpty && !championTag.isEmpty && !selectedDomains.isEmpty
    }

    private func createDeck() async {
        guard let userID = appState.currentUser?.id else { return }

        isCreating = true

        let deck = RBDeck(
            ownerUserID: userID,
            title: title,
            description: description.isEmpty ? nil : description,
            legendChampionTag: championTag,
            legendDomains: Array(selectedDomains),
            isPublic: false
        )

        await onSave(deck)
        dismiss()
    }
}

#Preview {
    MyDecksView()
        .environmentObject(AppState())
        .modelContainer(for: [CachedDeck.self])
}
