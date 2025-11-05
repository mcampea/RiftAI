import Foundation
import SwiftData

@Model
final class CachedDeck {
    @Attribute(.unique) var id: String
    var ownerUserID: String
    var title: String
    var deckDescription: String?
    var legendChampionTag: String
    var legendDomains: [String]
    var isPublic: Bool
    var countMain: Int
    var countSide: Int
    var countRunes: Int
    var createdAt: Date
    var updatedAt: Date
    var lastSynced: Date

    init(from deck: RBDeck) {
        self.id = deck.id
        self.ownerUserID = deck.ownerUserRef.recordID.recordName
        self.title = deck.title
        self.deckDescription = deck.description
        self.legendChampionTag = deck.legendChampionTag
        self.legendDomains = deck.legendDomains
        self.isPublic = deck.isPublic
        self.countMain = deck.countMain
        self.countSide = deck.countSide
        self.countRunes = deck.countRunes
        self.createdAt = deck.createdAt
        self.updatedAt = deck.updatedAt
        self.lastSynced = Date()
    }
}

@Model
final class CachedDeckItem {
    @Attribute(.unique) var id: String
    var deckID: String
    var cardID: String
    var section: String
    var qty: Int

    init(from item: RBDeckItem) {
        self.id = item.id
        self.deckID = item.deckRef.recordID.recordName
        self.cardID = item.cardRef.recordID.recordName
        self.section = item.section
        self.qty = item.qty
    }
}
