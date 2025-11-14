import SwiftUI

struct StatsView: View {
    @ObservedObject var viewModel: GameSessionViewModel

    var stats: GameSessionViewModel.GameStats {
        viewModel.calculateStats()
    }

    var body: some View {
        List {
            if stats.totalGames == 0 {
                VStack(spacing: 16) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)

                    Text("No Stats Yet")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Complete some games to see your statistics")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
                .listRowBackground(Color.clear)
            } else {
                // Overall Stats
                Section("Overall Record") {
                    HStack {
                        Text("Total Games")
                        Spacer()
                        Text("\(stats.totalGames)")
                            .fontWeight(.semibold)
                    }

                    HStack {
                        Text("Wins")
                        Spacer()
                        Text("\(stats.wins)")
                            .foregroundColor(.green)
                            .fontWeight(.semibold)
                    }

                    HStack {
                        Text("Losses")
                        Spacer()
                        Text("\(stats.losses)")
                            .foregroundColor(.red)
                            .fontWeight(.semibold)
                    }

                    if stats.draws > 0 {
                        HStack {
                            Text("Draws")
                            Spacer()
                            Text("\(stats.draws)")
                                .foregroundColor(.orange)
                                .fontWeight(.semibold)
                        }
                    }

                    HStack {
                        Text("Win Rate")
                        Spacer()
                        Text(String(format: "%.1f%%", stats.winRate * 100))
                            .fontWeight(.bold)
                            .foregroundColor(stats.winRate >= 0.5 ? .green : .red)
                    }
                }

                // Stats by Legend
                if !stats.statsByLegend.isEmpty {
                    Section("Stats by Your Legend") {
                        ForEach(Array(stats.statsByLegend.keys.sorted()), id: \.self) { legendTag in
                            if let legendStats = stats.statsByLegend[legendTag] {
                                NavigationLink {
                                    LegendStatsDetailView(
                                        legendTag: legendTag,
                                        stats: legendStats
                                    )
                                } label: {
                                    LegendStatsRow(
                                        legendTag: legendTag,
                                        stats: legendStats
                                    )
                                }
                            }
                        }
                    }
                }

                // Stats by Deck
                if !stats.statsByDeck.isEmpty {
                    Section("Stats by Your Deck") {
                        ForEach(Array(stats.statsByDeck.keys.sorted()), id: \.self) { deckTitle in
                            if let deckStats = stats.statsByDeck[deckTitle] {
                                NavigationLink {
                                    DeckStatsDetailView(
                                        deckTitle: deckTitle,
                                        stats: deckStats
                                    )
                                } label: {
                                    DeckStatsRow(
                                        deckTitle: deckTitle,
                                        stats: deckStats
                                    )
                                }
                            }
                        }
                    }
                }

                // Stats vs Opponent Legends
                if !stats.statsVsLegend.isEmpty {
                    Section("Stats vs Opponent Legends") {
                        ForEach(Array(stats.statsVsLegend.keys.sorted()), id: \.self) { opponentLegend in
                            if let opponentStats = stats.statsVsLegend[opponentLegend] {
                                NavigationLink {
                                    OpponentStatsDetailView(
                                        opponentLegend: opponentLegend,
                                        stats: opponentStats
                                    )
                                } label: {
                                    OpponentStatsRow(
                                        opponentLegend: opponentLegend,
                                        stats: opponentStats
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Statistics")
    }
}

struct LegendStatsRow: View {
    let legendTag: String
    let stats: GameSessionViewModel.LegendStats

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(legendTag)
                .font(.headline)

            HStack(spacing: 16) {
                Label("\(stats.wins)W", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)

                Label("\(stats.losses)L", systemImage: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.red)

                Spacer()

                Text(String(format: "%.1f%%", stats.winRate * 100))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(stats.winRate >= 0.5 ? .green : .red)
            }
        }
        .padding(.vertical, 4)
    }
}

struct DeckStatsRow: View {
    let deckTitle: String
    let stats: GameSessionViewModel.DeckStats

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(deckTitle)
                .font(.headline)

            HStack(spacing: 16) {
                Label("\(stats.wins)W", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)

                Label("\(stats.losses)L", systemImage: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.red)

                Spacer()

                Text(String(format: "%.1f%%", stats.winRate * 100))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(stats.winRate >= 0.5 ? .green : .red)
            }
        }
        .padding(.vertical, 4)
    }
}

struct OpponentStatsRow: View {
    let opponentLegend: String
    let stats: GameSessionViewModel.OpponentStats

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(opponentLegend)
                .font(.headline)

            HStack(spacing: 16) {
                Label("\(stats.wins)W", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)

                Label("\(stats.losses)L", systemImage: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.red)

                Spacer()

                Text(String(format: "%.1f%%", stats.winRate * 100))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(stats.winRate >= 0.5 ? .green : .red)
            }
        }
        .padding(.vertical, 4)
    }
}

struct LegendStatsDetailView: View {
    let legendTag: String
    let stats: GameSessionViewModel.LegendStats

    var body: some View {
        List {
            Section("Record with \(legendTag)") {
                HStack {
                    Text("Games Played")
                    Spacer()
                    Text("\(stats.games)")
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Wins")
                    Spacer()
                    Text("\(stats.wins)")
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Losses")
                    Spacer()
                    Text("\(stats.losses)")
                        .foregroundColor(.red)
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Win Rate")
                    Spacer()
                    Text(String(format: "%.1f%%", stats.winRate * 100))
                        .fontWeight(.bold)
                        .foregroundColor(stats.winRate >= 0.5 ? .green : .red)
                }
            }
        }
        .navigationTitle(legendTag)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DeckStatsDetailView: View {
    let deckTitle: String
    let stats: GameSessionViewModel.DeckStats

    var body: some View {
        List {
            Section("Record with \(deckTitle)") {
                HStack {
                    Text("Games Played")
                    Spacer()
                    Text("\(stats.games)")
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Wins")
                    Spacer()
                    Text("\(stats.wins)")
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Losses")
                    Spacer()
                    Text("\(stats.losses)")
                        .foregroundColor(.red)
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Win Rate")
                    Spacer()
                    Text(String(format: "%.1f%%", stats.winRate * 100))
                        .fontWeight(.bold)
                        .foregroundColor(stats.winRate >= 0.5 ? .green : .red)
                }
            }
        }
        .navigationTitle(deckTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct OpponentStatsDetailView: View {
    let opponentLegend: String
    let stats: GameSessionViewModel.OpponentStats

    var body: some View {
        List {
            Section("Record vs \(opponentLegend)") {
                HStack {
                    Text("Games Played")
                    Spacer()
                    Text("\(stats.games)")
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Wins")
                    Spacer()
                    Text("\(stats.wins)")
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Losses")
                    Spacer()
                    Text("\(stats.losses)")
                        .foregroundColor(.red)
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Win Rate")
                    Spacer()
                    Text(String(format: "%.1f%%", stats.winRate * 100))
                        .fontWeight(.bold)
                        .foregroundColor(stats.winRate >= 0.5 ? .green : .red)
                }
            }
        }
        .navigationTitle("vs \(opponentLegend)")
        .navigationBarTitleDisplayMode(.inline)
    }
}
