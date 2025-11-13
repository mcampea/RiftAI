import SwiftUI

struct GameHistoryView: View {
    @ObservedObject var viewModel: GameSessionViewModel

    @State private var showDeleteConfirmation = false
    @State private var sessionToDelete: RBGameSession?

    var body: some View {
        List {
            if viewModel.sessions.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "list.bullet.clipboard")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)

                    Text("No Games Yet")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Start a new game to begin tracking your matches")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
                .listRowBackground(Color.clear)
            } else {
                ForEach(viewModel.sessions) { session in
                    NavigationLink {
                        GameDetailView(session: session)
                    } label: {
                        GameHistoryRow(session: session)
                    }
                }
                .onDelete { indexSet in
                    if let index = indexSet.first {
                        sessionToDelete = viewModel.sessions[index]
                        showDeleteConfirmation = true
                    }
                }
            }
        }
        .navigationTitle("Game History")
        .refreshable {
            // Refresh would require passing user reference
        }
        .alert("Delete Game", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let session = sessionToDelete {
                    Task {
                        await viewModel.deleteGameSession(session)
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this game session?")
        }
    }
}

struct GameHistoryRow: View {
    let session: RBGameSession

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.player1Name)
                        .font(.headline)
                    Text(session.player1LegendChampionTag)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("vs")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(session.player2Name)
                        .font(.headline)
                    Text(session.player2LegendChampionTag)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            HStack {
                if session.isComplete {
                    if let winner = session.winner {
                        if winner == 1 {
                            Label("Won", systemImage: "trophy.fill")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        } else {
                            Label("Lost", systemImage: "xmark.circle.fill")
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                    } else {
                        Label("Draw", systemImage: "equal.circle.fill")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                } else {
                    Label("In Progress", systemImage: "play.circle.fill")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }

                Spacer()

                Text(session.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct GameDetailView: View {
    let session: RBGameSession

    var body: some View {
        List {
            Section("Game Result") {
                if session.isComplete {
                    if let winner = session.winner {
                        HStack {
                            Text("Winner")
                            Spacer()
                            Text(winner == 1 ? session.player1Name : session.player2Name)
                                .fontWeight(.semibold)
                                .foregroundColor(winner == 1 ? .green : .red)
                        }
                    } else {
                        HStack {
                            Text("Result")
                            Spacer()
                            Text("Draw")
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)
                        }
                    }

                    if let completedAt = session.completedAt {
                        HStack {
                            Text("Completed")
                            Spacer()
                            Text(completedAt, style: .date)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text("In Progress")
                            .foregroundColor(.blue)
                    }
                }

                HStack {
                    Text("Started")
                    Spacer()
                    Text(session.createdAt, style: .date)
                        .foregroundColor(.secondary)
                }
            }

            Section("Player 1") {
                HStack {
                    Text("Name")
                    Spacer()
                    Text(session.player1Name)
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Legend")
                    Spacer()
                    Text(session.player1LegendChampionTag)
                }

                HStack {
                    Text("Domains")
                    Spacer()
                    Text(session.player1LegendDomains.joined(separator: ", "))
                        .foregroundColor(.secondary)
                }

                if let deckTitle = session.player1DeckTitle {
                    HStack {
                        Text("Deck")
                        Spacer()
                        Text(deckTitle)
                    }
                }

                HStack {
                    Text("Final Score")
                    Spacer()
                    Text("\(session.player1Score)")
                        .fontWeight(.bold)
                }

                HStack {
                    Text("Battlefield 1 Might")
                    Spacer()
                    Text("\(session.player1Battlefield1Might)")
                }

                HStack {
                    Text("Battlefield 2 Might")
                    Spacer()
                    Text("\(session.player1Battlefield2Might)")
                }
            }

            Section("Player 2") {
                HStack {
                    Text("Name")
                    Spacer()
                    Text(session.player2Name)
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Legend")
                    Spacer()
                    Text(session.player2LegendChampionTag)
                }

                HStack {
                    Text("Domains")
                    Spacer()
                    Text(session.player2LegendDomains.joined(separator: ", "))
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Final Score")
                    Spacer()
                    Text("\(session.player2Score)")
                        .fontWeight(.bold)
                }

                HStack {
                    Text("Battlefield 1 Might")
                    Spacer()
                    Text("\(session.player2Battlefield1Might)")
                }

                HStack {
                    Text("Battlefield 2 Might")
                    Spacer()
                    Text("\(session.player2Battlefield2Might)")
                }
            }
        }
        .navigationTitle("Game Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
