import SwiftUI
import CloudKit

struct GameSetupView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var viewModel: GameSessionViewModel

    @Environment(\.dismiss) var dismiss

    // User's decks
    @State private var userDecks: [RBDeck] = []
    @State private var selectedDeck: RBDeck?
    @State private var isLoadingDecks = false

    // Player 1 (current user)
    @State private var player1Name: String = ""
    @State private var player1ChampionTag: String = ""
    @State private var player1Domains: Set<String> = []
    @State private var player1DeckTitle: String = ""

    // Player 2 (opponent)
    @State private var player2Name: String = ""
    @State private var player2ChampionTag: String = ""
    @State private var player2Domains: Set<String> = []
    @State private var isLookingUpOpponent = false

    @State private var isCreating = false
    @State private var navigateToGame = false

    let allDomains = ["Fury", "Mind", "Valor", "Spirit", "Wild"]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Configure the players and their legends")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Player 1
                Section(header: Text("Your Info")) {
                    TextField("Your Name", text: $player1Name)
                        .textContentType(.name)

                    if !userDecks.isEmpty {
                        Picker("Select Your Deck", selection: $selectedDeck) {
                            Text("No Deck Selected").tag(nil as RBDeck?)
                            ForEach(userDecks) { deck in
                                Text(deck.title).tag(deck as RBDeck?)
                            }
                        }
                        .onChange(of: selectedDeck) { _, newDeck in
                            if let deck = newDeck {
                                populatePlayer1FromDeck(deck)
                            }
                        }
                    }

                    TextField("Your Legend (Champion Tag)", text: $player1ChampionTag)
                        .textContentType(.none)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Legend Domains")
                            .font(.subheadline)
                        ForEach(allDomains, id: \.self) { domain in
                            Toggle(domain, isOn: Binding(
                                get: { player1Domains.contains(domain) },
                                set: { isOn in
                                    if isOn {
                                        player1Domains.insert(domain)
                                    } else {
                                        player1Domains.remove(domain)
                                    }
                                }
                            ))
                        }
                    }

                    if selectedDeck != nil {
                        HStack {
                            Text("Deck")
                            Spacer()
                            Text(player1DeckTitle)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        TextField("Deck Name (optional)", text: $player1DeckTitle)
                    }
                }

                // Player 2
                Section(header: Text("Opponent Info")) {
                    TextField("Opponent Name", text: $player2Name)
                        .textContentType(.name)

                    HStack {
                        TextField("Opponent Legend (Champion Tag)", text: $player2ChampionTag)
                            .textContentType(.none)

                        if !player2ChampionTag.isEmpty && player2Domains.isEmpty {
                            Button {
                                Task {
                                    await lookupOpponentLegend()
                                }
                            } label: {
                                if isLookingUpOpponent {
                                    ProgressView()
                                } else {
                                    Image(systemName: "magnifyingglass")
                                }
                            }
                            .disabled(isLookingUpOpponent)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Opponent Legend Domains")
                            .font(.subheadline)
                        ForEach(allDomains, id: \.self) { domain in
                            Toggle(domain, isOn: Binding(
                                get: { player2Domains.contains(domain) },
                                set: { isOn in
                                    if isOn {
                                        player2Domains.insert(domain)
                                    } else {
                                        player2Domains.remove(domain)
                                    }
                                }
                            ))
                        }
                    }

                    if player2Domains.isEmpty && !player2ChampionTag.isEmpty {
                        Text("Tap the magnifying glass to look up legend domains")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("New Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start Game") {
                        Task {
                            await createGame()
                        }
                    }
                    .disabled(!isFormValid || isCreating)
                }
            }
            .disabled(isCreating)
            .navigationDestination(isPresented: $navigateToGame) {
                if let session = viewModel.currentSession {
                    GamePlayView(viewModel: viewModel, session: session)
                }
            }
            .task {
                await loadUserDecks()
                if let userName = appState.currentUser?.displayName, !userName.isEmpty {
                    player1Name = userName
                }
            }
        }
    }

    var isFormValid: Bool {
        !player1Name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !player1ChampionTag.trimmingCharacters(in: .whitespaces).isEmpty &&
        !player1Domains.isEmpty &&
        !player2Name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !player2ChampionTag.trimmingCharacters(in: .whitespaces).isEmpty &&
        !player2Domains.isEmpty
    }

    func loadUserDecks() async {
        isLoadingDecks = true

        do {
            let predicate = NSPredicate(value: true)
            let sortDescriptor = NSSortDescriptor(key: "updatedAt", ascending: false)
            let cloudKit = CloudKitService.shared

            let records = try await cloudKit.query(
                recordType: "RBDeck",
                predicate: predicate,
                sortDescriptors: [sortDescriptor],
                database: cloudKit.privateDatabase
            )

            userDecks = records.compactMap { try? RBDeck(from: $0) }
        } catch {
            print("Failed to load decks: \(error)")
        }

        isLoadingDecks = false
    }

    func populatePlayer1FromDeck(_ deck: RBDeck) {
        player1ChampionTag = deck.legendChampionTag
        player1Domains = Set(deck.legendDomains)
        player1DeckTitle = deck.title
    }

    func lookupOpponentLegend() async {
        isLookingUpOpponent = true

        // Try to find legend domains from existing decks (both private and public)
        let championTag = player2ChampionTag.trimmingCharacters(in: .whitespaces)

        do {
            let cloudKit = CloudKitService.shared

            // Search public decks first
            let publicPredicate = NSPredicate(format: "legendChampionTag == %@", championTag)
            let publicRecords = try await cloudKit.query(
                recordType: "RBDeck",
                predicate: publicPredicate,
                database: cloudKit.publicDatabase
            )

            if let firstDeck = publicRecords.first,
               let deck = try? RBDeck(from: firstDeck) {
                player2Domains = Set(deck.legendDomains)
                isLookingUpOpponent = false
                return
            }

            // If not found in public, try user's private decks
            let privatePredicate = NSPredicate(format: "legendChampionTag == %@", championTag)
            let privateRecords = try await cloudKit.query(
                recordType: "RBDeck",
                predicate: privatePredicate,
                database: cloudKit.privateDatabase
            )

            if let firstDeck = privateRecords.first,
               let deck = try? RBDeck(from: firstDeck) {
                player2Domains = Set(deck.legendDomains)
                isLookingUpOpponent = false
                return
            }

            // If still not found, try looking up from cards
            let cardPredicate = NSPredicate(format: "championTag == %@ AND isSignature == 1", championTag)
            let cardRecords = try await cloudKit.query(
                recordType: "RBCard",
                predicate: cardPredicate,
                database: cloudKit.publicDatabase
            )

            if let firstCard = cardRecords.first,
               let card = RBCard(from: firstCard) {
                player2Domains = Set(card.domains)
            }
        } catch {
            print("Failed to lookup opponent legend: \(error)")
        }

        isLookingUpOpponent = false
    }

    func createGame() async {
        guard let userID = appState.currentUser?.id else { return }

        isCreating = true

        let userRef = CKRecord.Reference(
            recordID: CKRecord.ID(recordName: userID),
            action: .none
        )

        let session = RBGameSession(
            player1Name: player1Name.trimmingCharacters(in: .whitespaces),
            player1LegendChampionTag: player1ChampionTag.trimmingCharacters(in: .whitespaces),
            player1LegendDomains: Array(player1Domains),
            player1DeckTitle: player1DeckTitle.isEmpty ? nil : player1DeckTitle.trimmingCharacters(in: .whitespaces),
            player2Name: player2Name.trimmingCharacters(in: .whitespaces),
            player2LegendChampionTag: player2ChampionTag.trimmingCharacters(in: .whitespaces),
            player2LegendDomains: Array(player2Domains),
            ownerUserRef: userRef
        )

        let success = await viewModel.createGameSession(session)
        isCreating = false

        if success {
            navigateToGame = true
        }
    }
}
