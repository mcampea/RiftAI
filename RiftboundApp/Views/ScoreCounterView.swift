import SwiftUI
import CloudKit

struct ScoreCounterView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = GameSessionViewModel()

    @State private var showNewGameSheet = false
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Tab Picker
                Picker("View", selection: $selectedTab) {
                    Text("Active").tag(0)
                    Text("History").tag(1)
                    Text("Stats").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()

                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    ActiveGamesView(viewModel: viewModel)
                        .tag(0)

                    GameHistoryView(viewModel: viewModel)
                        .tag(1)

                    StatsView(viewModel: viewModel)
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Score Counter")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showNewGameSheet = true
                    } label: {
                        Label("New Game", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showNewGameSheet) {
                GameSetupView(viewModel: viewModel)
            }
            .task {
                await loadGameSessions()
            }
            .refreshable {
                await loadGameSessions()
            }
        }
    }

    func loadGameSessions() async {
        guard let userRecord = appState.currentUserRecord else { return }
        let userRef = CKRecord.Reference(recordID: userRecord.recordID, action: .none)
        await viewModel.fetchGameSessions(for: userRef)
    }
}

struct ActiveGamesView: View {
    @ObservedObject var viewModel: GameSessionViewModel

    var activeGames: [RBGameSession] {
        viewModel.sessions.filter { !$0.isComplete }
    }

    var body: some View {
        List {
            if activeGames.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "gamecontroller")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)

                    Text("No Active Games")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Tap + to start a new game")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
                .listRowBackground(Color.clear)
            } else {
                ForEach(activeGames) { session in
                    NavigationLink {
                        GamePlayView(viewModel: viewModel, session: session)
                    } label: {
                        ActiveGameRow(session: session)
                    }
                }
            }
        }
    }
}

struct ActiveGameRow: View {
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

                Text("\(session.player1Score)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)

                Text("-")
                    .font(.title2)
                    .foregroundColor(.secondary)

                Text("\(session.player2Score)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.red)

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
                Label("In Progress", systemImage: "play.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)

                Spacer()

                Text(session.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
