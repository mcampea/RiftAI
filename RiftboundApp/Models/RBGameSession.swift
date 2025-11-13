import Foundation
import CloudKit

/// Represents a game session between two players
struct RBGameSession: Identifiable {
    let id: String // gamesession_<uuid>

    // Player 1 (current user)
    var player1Name: String
    var player1LegendChampionTag: String
    var player1LegendDomains: [String]
    var player1DeckTitle: String?
    var player1Score: Int
    var player1Battlefield1Might: Int
    var player1Battlefield2Might: Int

    // Player 2 (opponent)
    var player2Name: String
    var player2LegendChampionTag: String
    var player2LegendDomains: [String]
    var player2Score: Int
    var player2Battlefield1Might: Int
    var player2Battlefield2Might: Int

    // Game metadata
    var ownerUserRef: CKRecord.Reference
    var isComplete: Bool
    var winner: Int? // 1 for player1, 2 for player2, nil for draw/incomplete
    var createdAt: Date
    var completedAt: Date?

    init(
        id: String = "gamesession_\(UUID().uuidString)",
        player1Name: String,
        player1LegendChampionTag: String,
        player1LegendDomains: [String],
        player1DeckTitle: String? = nil,
        player1Score: Int = 25,
        player1Battlefield1Might: Int = 0,
        player1Battlefield2Might: Int = 0,
        player2Name: String,
        player2LegendChampionTag: String,
        player2LegendDomains: [String],
        player2Score: Int = 25,
        player2Battlefield1Might: Int = 0,
        player2Battlefield2Might: Int = 0,
        ownerUserRef: CKRecord.Reference,
        isComplete: Bool = false,
        winner: Int? = nil,
        createdAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.player1Name = player1Name
        self.player1LegendChampionTag = player1LegendChampionTag
        self.player1LegendDomains = player1LegendDomains
        self.player1DeckTitle = player1DeckTitle
        self.player1Score = player1Score
        self.player1Battlefield1Might = player1Battlefield1Might
        self.player1Battlefield2Might = player1Battlefield2Might
        self.player2Name = player2Name
        self.player2LegendChampionTag = player2LegendChampionTag
        self.player2LegendDomains = player2LegendDomains
        self.player2Score = player2Score
        self.player2Battlefield1Might = player2Battlefield1Might
        self.player2Battlefield2Might = player2Battlefield2Might
        self.ownerUserRef = ownerUserRef
        self.isComplete = isComplete
        self.winner = winner
        self.createdAt = createdAt
        self.completedAt = completedAt
    }

    // MARK: - CloudKit Conversion

    static let recordType = "RBGameSession"

    init?(from record: CKRecord) {
        guard
            let player1Name = record["player1Name"] as? String,
            let player1LegendChampionTag = record["player1LegendChampionTag"] as? String,
            let player1LegendDomains = record["player1LegendDomains"] as? [String],
            let player1Score = record["player1Score"] as? Int,
            let player1Battlefield1Might = record["player1Battlefield1Might"] as? Int,
            let player1Battlefield2Might = record["player1Battlefield2Might"] as? Int,
            let player2Name = record["player2Name"] as? String,
            let player2LegendChampionTag = record["player2LegendChampionTag"] as? String,
            let player2LegendDomains = record["player2LegendDomains"] as? [String],
            let player2Score = record["player2Score"] as? Int,
            let player2Battlefield1Might = record["player2Battlefield1Might"] as? Int,
            let player2Battlefield2Might = record["player2Battlefield2Might"] as? Int,
            let ownerUserRef = record["ownerUserRef"] as? CKRecord.Reference,
            let isComplete = record["isComplete"] as? Int,
            let createdAt = record["createdAt"] as? Date
        else {
            return nil
        }

        self.id = record.recordID.recordName
        self.player1Name = player1Name
        self.player1LegendChampionTag = player1LegendChampionTag
        self.player1LegendDomains = player1LegendDomains
        self.player1DeckTitle = record["player1DeckTitle"] as? String
        self.player1Score = player1Score
        self.player1Battlefield1Might = player1Battlefield1Might
        self.player1Battlefield2Might = player1Battlefield2Might
        self.player2Name = player2Name
        self.player2LegendChampionTag = player2LegendChampionTag
        self.player2LegendDomains = player2LegendDomains
        self.player2Score = player2Score
        self.player2Battlefield1Might = player2Battlefield1Might
        self.player2Battlefield2Might = player2Battlefield2Might
        self.ownerUserRef = ownerUserRef
        self.isComplete = isComplete == 1
        self.winner = record["winner"] as? Int
        self.createdAt = createdAt
        self.completedAt = record["completedAt"] as? Date
    }

    func toRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)

        record["player1Name"] = player1Name
        record["player1LegendChampionTag"] = player1LegendChampionTag
        record["player1LegendDomains"] = player1LegendDomains
        record["player1DeckTitle"] = player1DeckTitle
        record["player1Score"] = player1Score
        record["player1Battlefield1Might"] = player1Battlefield1Might
        record["player1Battlefield2Might"] = player1Battlefield2Might
        record["player2Name"] = player2Name
        record["player2LegendChampionTag"] = player2LegendChampionTag
        record["player2LegendDomains"] = player2LegendDomains
        record["player2Score"] = player2Score
        record["player2Battlefield1Might"] = player2Battlefield1Might
        record["player2Battlefield2Might"] = player2Battlefield2Might
        record["ownerUserRef"] = ownerUserRef
        record["isComplete"] = isComplete ? 1 : 0
        record["winner"] = winner
        record["createdAt"] = createdAt
        record["completedAt"] = completedAt

        return record
    }
}
