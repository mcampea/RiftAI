import SwiftUI
import CloudKit

struct GameSetupView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var viewModel: GameSessionViewModel

    @Environment(\.dismiss) var dismiss

    // Player 1 (current user)
    @State private var player1Name: String = ""
    @State private var player1ChampionTag: String = ""
    @State private var player1Domains: Set<String> = []
    @State private var player1DeckTitle: String = ""
    @State private var player1StartingScore: Int = 25

    // Player 2 (opponent)
    @State private var player2Name: String = ""
    @State private var player2ChampionTag: String = ""
    @State private var player2Domains: Set<String> = []
    @State private var player2StartingScore: Int = 25

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

                    TextField("Deck Name (optional)", text: $player1DeckTitle)

                    Stepper("Starting Score: \(player1StartingScore)", value: $player1StartingScore, in: 1...100)
                }

                // Player 2
                Section(header: Text("Opponent Info")) {
                    TextField("Opponent Name", text: $player2Name)
                        .textContentType(.name)

                    TextField("Opponent Legend (Champion Tag)", text: $player2ChampionTag)
                        .textContentType(.none)

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

                    Stepper("Starting Score: \(player2StartingScore)", value: $player2StartingScore, in: 1...100)
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

    func createGame() async {
        guard let userRecord = appState.currentUserRecord else { return }
        let userRef = CKRecord.Reference(recordID: userRecord.recordID, action: .none)

        isCreating = true

        let session = RBGameSession(
            player1Name: player1Name.trimmingCharacters(in: .whitespaces),
            player1LegendChampionTag: player1ChampionTag.trimmingCharacters(in: .whitespaces),
            player1LegendDomains: Array(player1Domains),
            player1DeckTitle: player1DeckTitle.isEmpty ? nil : player1DeckTitle.trimmingCharacters(in: .whitespaces),
            player1Score: player1StartingScore,
            player2Name: player2Name.trimmingCharacters(in: .whitespaces),
            player2LegendChampionTag: player2ChampionTag.trimmingCharacters(in: .whitespaces),
            player2LegendDomains: Array(player2Domains),
            player2Score: player2StartingScore,
            ownerUserRef: userRef
        )

        let success = await viewModel.createGameSession(session)
        isCreating = false

        if success {
            navigateToGame = true
        }
    }
}
