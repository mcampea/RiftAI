import Foundation
import CloudKit

@MainActor
class PublicDecksViewModel: ObservableObject {
    @Published var decks: [DeckWithVotes] = []
    @Published var sortedDecks: [DeckWithVotes] = []
    @Published var isLoading = false

    private let cloudKit = CloudKitService.shared
    private var currentUserID: String?

    struct DeckWithVotes: Identifiable {
        let deck: RBDeck
        var voteCount: Int
        var hasUserVoted: Bool
        var trendingScore: Double

        var id: String { deck.id }
    }

    func loadPublicDecks() async {
        isLoading = true

        do {
            // Get current user
            if let userRecordID = try await cloudKit.fetchUserRecordID() {
                currentUserID = "user_\(userRecordID.recordName)"
            }

            // Fetch all public decks
            let predicate = NSPredicate(format: "isPublic == %@", NSNumber(value: 1))
            let sortDescriptor = NSSortDescriptor(key: "updatedAt", ascending: false)

            let deckRecords = try await cloudKit.query(
                recordType: AppConfig.RecordType.deck.rawValue,
                predicate: predicate,
                sortDescriptors: [sortDescriptor],
                database: cloudKit.publicDatabase
            )

            let fetchedDecks = deckRecords.compactMap { try? RBDeck(from: $0) }

            // Fetch all votes
            let votePredicate = NSPredicate(value: true)
            let voteRecords = try await cloudKit.query(
                recordType: AppConfig.RecordType.vote.rawValue,
                predicate: votePredicate,
                database: cloudKit.publicDatabase
            )

            let votes = voteRecords.compactMap { try? RBVote(from: $0) }

            // Group votes by deck
            let votesByDeck = Dictionary(grouping: votes, by: { $0.deckRef.recordID.recordName })

            // Combine decks with vote info
            decks = fetchedDecks.map { deck in
                let deckVotes = votesByDeck[deck.id] ?? []
                let hasUserVoted = currentUserID != nil && deckVotes.contains { $0.voterUserRef.recordID.recordName == currentUserID }
                let trendingScore = calculateTrendingScore(
                    voteCount: deckVotes.count,
                    createdAt: deck.createdAt
                )

                return DeckWithVotes(
                    deck: deck,
                    voteCount: deckVotes.count,
                    hasUserVoted: hasUserVoted,
                    trendingScore: trendingScore
                )
            }

            // Default sort by trending
            sortDecks(by: .trending)
        } catch {
            print("Failed to load public decks: \(error)")
        }

        isLoading = false
    }

    func sortDecks(by option: PublicDeckSort) {
        switch option {
        case .trending:
            sortedDecks = decks.sorted { $0.trendingScore > $1.trendingScore }
        case .recent:
            sortedDecks = decks.sorted { $0.deck.updatedAt > $1.deck.updatedAt }
        case .top:
            sortedDecks = decks.sorted { $0.voteCount > $1.voteCount }
        }
    }

    func toggleVote(for deck: RBDeck) async {
        guard let currentUserID = currentUserID else { return }

        do {
            if let deckWithVotes = decks.first(where: { $0.deck.id == deck.id }) {
                if deckWithVotes.hasUserVoted {
                    // Remove vote
                    let voteID = "vote_\(deck.id)_\(currentUserID)"
                    try await cloudKit.delete(
                        recordID: CKRecord.ID(recordName: voteID),
                        database: cloudKit.publicDatabase
                    )
                } else {
                    // Add vote
                    let vote = RBVote(deckID: deck.id, voterUserID: currentUserID)
                    _ = try await cloudKit.save(
                        record: vote.toCKRecord(),
                        database: cloudKit.publicDatabase
                    )
                }

                // Reload
                await loadPublicDecks()
            }
        } catch {
            print("Failed to toggle vote: \(error)")
        }
    }

    private func calculateTrendingScore(voteCount: Int, createdAt: Date) -> Double {
        let hoursSinceCreation = Date().timeIntervalSince(createdAt) / 3600
        let score = Double(voteCount) / log1p(hoursSinceCreation + 2)
        return score
    }
}

enum PublicDeckSort: String, CaseIterable, Identifiable {
    case trending = "Trending"
    case recent = "Recent"
    case top = "Top Rated"

    var id: String { rawValue }
}
