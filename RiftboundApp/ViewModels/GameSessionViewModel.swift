import Foundation
import CloudKit
import Combine

@MainActor
class GameSessionViewModel: ObservableObject {
    @Published var sessions: [RBGameSession] = []
    @Published var currentSession: RBGameSession?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let cloudKit = CloudKitService.shared

    // MARK: - Fetch Game Sessions

    func fetchGameSessions(for userRef: CKRecord.Reference) async {
        isLoading = true
        errorMessage = nil

        do {
            let predicate = NSPredicate(format: "ownerUserRef == %@", userRef)
            let query = CKQuery(recordType: RBGameSession.recordType, predicate: predicate)
            query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

            let records = try await cloudKit.queryRecords(
                query: query,
                database: .private
            )

            sessions = records.compactMap { RBGameSession(from: $0) }
        } catch {
            errorMessage = "Failed to load game sessions: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Create Game Session

    func createGameSession(_ session: RBGameSession) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let record = session.toRecord()
            _ = try await cloudKit.saveRecord(record, to: .private)
            currentSession = session
            sessions.insert(session, at: 0)
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to create game session: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    // MARK: - Update Game Session

    func updateGameSession(_ session: RBGameSession) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let record = session.toRecord()
            _ = try await cloudKit.saveRecord(record, to: .private)

            // Update in local array
            if let index = sessions.firstIndex(where: { $0.id == session.id }) {
                sessions[index] = session
            }

            if currentSession?.id == session.id {
                currentSession = session
            }

            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to update game session: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    // MARK: - Delete Game Session

    func deleteGameSession(_ session: RBGameSession) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let recordID = CKRecord.ID(recordName: session.id)
            try await cloudKit.deleteRecord(withID: recordID, from: .private)

            sessions.removeAll { $0.id == session.id }

            if currentSession?.id == session.id {
                currentSession = nil
            }

            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to delete game session: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    // MARK: - Statistics

    struct GameStats {
        var totalGames: Int
        var wins: Int
        var losses: Int
        var draws: Int
        var winRate: Double
        var statsByLegend: [String: LegendStats]
        var statsByDeck: [String: DeckStats]
        var statsVsLegend: [String: OpponentStats]
    }

    struct LegendStats {
        var legendName: String
        var games: Int
        var wins: Int
        var losses: Int
        var winRate: Double
    }

    struct DeckStats {
        var deckTitle: String
        var games: Int
        var wins: Int
        var losses: Int
        var winRate: Double
    }

    struct OpponentStats {
        var opponentLegend: String
        var games: Int
        var wins: Int
        var losses: Int
        var winRate: Double
    }

    func calculateStats() -> GameStats {
        let completedGames = sessions.filter { $0.isComplete }
        let totalGames = completedGames.count
        let wins = completedGames.filter { $0.winner == 1 }.count
        let losses = completedGames.filter { $0.winner == 2 }.count
        let draws = completedGames.filter { $0.winner == nil }.count
        let winRate = totalGames > 0 ? Double(wins) / Double(totalGames) : 0.0

        // Stats by legend
        var legendStatsDict: [String: (games: Int, wins: Int, losses: Int)] = [:]
        for game in completedGames {
            let legend = game.player1LegendChampionTag
            let current = legendStatsDict[legend] ?? (games: 0, wins: 0, losses: 0)
            legendStatsDict[legend] = (
                games: current.games + 1,
                wins: current.wins + (game.winner == 1 ? 1 : 0),
                losses: current.losses + (game.winner == 2 ? 1 : 0)
            )
        }
        let statsByLegend = legendStatsDict.mapValues { stats in
            LegendStats(
                legendName: "",
                games: stats.games,
                wins: stats.wins,
                losses: stats.losses,
                winRate: stats.games > 0 ? Double(stats.wins) / Double(stats.games) : 0.0
            )
        }

        // Stats by deck
        var deckStatsDict: [String: (games: Int, wins: Int, losses: Int)] = [:]
        for game in completedGames {
            guard let deck = game.player1DeckTitle, !deck.isEmpty else { continue }
            let current = deckStatsDict[deck] ?? (games: 0, wins: 0, losses: 0)
            deckStatsDict[deck] = (
                games: current.games + 1,
                wins: current.wins + (game.winner == 1 ? 1 : 0),
                losses: current.losses + (game.winner == 2 ? 1 : 0)
            )
        }
        let statsByDeck = deckStatsDict.mapValues { stats in
            DeckStats(
                deckTitle: "",
                games: stats.games,
                wins: stats.wins,
                losses: stats.losses,
                winRate: stats.games > 0 ? Double(stats.wins) / Double(stats.games) : 0.0
            )
        }

        // Stats vs opponent legends
        var vsLegendDict: [String: (games: Int, wins: Int, losses: Int)] = [:]
        for game in completedGames {
            let opponentLegend = game.player2LegendChampionTag
            let current = vsLegendDict[opponentLegend] ?? (games: 0, wins: 0, losses: 0)
            vsLegendDict[opponentLegend] = (
                games: current.games + 1,
                wins: current.wins + (game.winner == 1 ? 1 : 0),
                losses: current.losses + (game.winner == 2 ? 1 : 0)
            )
        }
        let statsVsLegend = vsLegendDict.mapValues { stats in
            OpponentStats(
                opponentLegend: "",
                games: stats.games,
                wins: stats.wins,
                losses: stats.losses,
                winRate: stats.games > 0 ? Double(stats.wins) / Double(stats.games) : 0.0
            )
        }

        return GameStats(
            totalGames: totalGames,
            wins: wins,
            losses: losses,
            draws: draws,
            winRate: winRate,
            statsByLegend: statsByLegend,
            statsByDeck: statsByDeck,
            statsVsLegend: statsVsLegend
        )
    }
}
