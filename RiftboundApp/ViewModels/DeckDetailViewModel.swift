import Foundation
import CloudKit

@MainActor
class DeckDetailViewModel: ObservableObject {
    let deckID: String

    @Published var deck: RBDeck?
    @Published var items: [RBDeckItem] = []
    @Published var cards: [String: RBCard] = [:] // cardID -> card
    @Published var isLoading = false

    private let cloudKit = CloudKitService.shared

    init(deckID: String) {
        self.deckID = deckID
    }

    func loadDeck() async {
        isLoading = true

        do {
            // Fetch deck
            let deckRecord = try await cloudKit.fetch(
                recordID: CKRecord.ID(recordName: deckID),
                database: nil // Will try private first, then public
            )
            deck = try RBDeck(from: deckRecord)

            // Fetch deck items
            let database = deck?.isPublic == true ? cloudKit.publicDatabase : cloudKit.privateDatabase
            let itemPredicate = NSPredicate(format: "deckRef == %@", deckRecord.recordID)
            let itemRecords = try await cloudKit.query(
                recordType: AppConfig.RecordType.deckItem.rawValue,
                predicate: itemPredicate,
                database: database
            )

            items = itemRecords.compactMap { try? RBDeckItem(from: $0) }

            // Fetch cards for all items
            let cardIDs = Set(items.map { $0.cardRef.recordID })
            let cardRecords = try await cloudKit.fetchRecords(
                recordIDs: Array(cardIDs),
                database: cloudKit.publicDatabase
            )

            cards = cardRecords.values.reduce(into: [:]) { dict, record in
                if let card = try? RBCard(from: record) {
                    dict[card.id] = card
                }
            }
        } catch {
            print("Failed to load deck: \(error)")
        }

        isLoading = false
    }

    func itemsForSection(_ section: AppConfig.DeckSection) -> [RBDeckItem] {
        items.filter { $0.section == section.rawValue }
            .sorted { cardForItem($0)?.name ?? "" < cardForItem($1)?.name ?? "" }
    }

    func cardForItem(_ item: RBDeckItem) -> RBCard? {
        cards[item.cardRef.recordID.recordName]
    }

    func countForSection(_ section: AppConfig.DeckSection) -> Int {
        itemsForSection(section).reduce(0) { $0 + $1.qty }
    }

    func addCards(_ cardIDs: [String], to section: AppConfig.DeckSection, quantity: Int = 1) async {
        guard let deck = deck else { return }

        do {
            let database = deck.isPublic ? cloudKit.publicDatabase : cloudKit.privateDatabase
            var newItems: [CKRecord] = []

            for cardID in cardIDs {
                // Check if item already exists
                if let existingItem = items.first(where: { $0.cardRef.recordID.recordName == cardID && $0.section == section.rawValue }) {
                    // Update quantity
                    var updated = existingItem
                    updated.qty += quantity
                    newItems.append(updated.toCKRecord())
                } else {
                    // Create new item
                    let item = RBDeckItem(
                        deckID: deck.id,
                        cardID: cardID,
                        section: section,
                        qty: quantity
                    )
                    newItems.append(item.toCKRecord())
                }
            }

            // Save items
            _ = try await cloudKit.save(records: newItems, database: database)

            // Update deck counts
            await updateDeckCounts(database: database)

            // Reload
            await loadDeck()
        } catch {
            print("Failed to add cards: \(error)")
        }
    }

    func removeCard(_ item: RBDeckItem) async {
        guard let deck = deck else { return }

        do {
            let database = deck.isPublic ? cloudKit.publicDatabase : cloudKit.privateDatabase

            try await cloudKit.delete(
                recordID: item.ckRecordID,
                database: database
            )

            // Update counts
            await updateDeckCounts(database: database)

            // Reload
            await loadDeck()
        } catch {
            print("Failed to remove card: \(error)")
        }
    }

    func adjustQuantity(_ item: RBDeckItem, by delta: Int) async {
        guard let deck = deck else { return }

        do {
            var updated = item
            updated.qty = max(1, updated.qty + delta)

            let database = deck.isPublic ? cloudKit.publicDatabase : cloudKit.privateDatabase
            _ = try await cloudKit.save(record: updated.toCKRecord(), database: database)

            // Update counts
            await updateDeckCounts(database: database)

            // Reload
            await loadDeck()
        } catch {
            print("Failed to adjust quantity: \(error)")
        }
    }

    func moveCard(_ item: RBDeckItem, to newSection: AppConfig.DeckSection) async {
        guard let deck = deck else { return }

        do {
            let database = deck.isPublic ? cloudKit.publicDatabase : cloudKit.privateDatabase

            // Delete old item
            try await cloudKit.delete(recordID: item.ckRecordID, database: database)

            // Create new item in new section
            let newItem = RBDeckItem(
                deckID: deck.id,
                cardID: item.cardRef.recordID.recordName,
                section: newSection,
                qty: item.qty
            )

            _ = try await cloudKit.save(record: newItem.toCKRecord(), database: database)

            // Update counts
            await updateDeckCounts(database: database)

            // Reload
            await loadDeck()
        } catch {
            print("Failed to move card: \(error)")
        }
    }

    private func updateDeckCounts(database: CKDatabase) async {
        guard var deck = deck else { return }

        // Recalculate counts
        deck.countMain = items.filter { $0.section == "main" }.reduce(0) { $0 + $1.qty }
        deck.countSide = items.filter { $0.section == "side" }.reduce(0) { $0 + $1.qty }
        deck.countRunes = items.filter { $0.section == "rune" }.reduce(0) { $0 + $1.qty }
        deck.updatedAt = Date()

        do {
            _ = try await cloudKit.save(record: deck.toCKRecord(), database: database)
            self.deck = deck
        } catch {
            print("Failed to update deck counts: \(error)")
        }
    }

    // MARK: - Validation

    func validateDeck() -> DeckValidator.ValidationResult {
        guard let deck = deck else {
            return DeckValidator.ValidationResult(isValid: false)
        }

        let mainCards = itemsForSection(.main).compactMap { item -> DeckCard? in
            guard let card = cardForItem(item) else { return nil }
            return DeckCard(card: card, quantity: item.qty)
        }

        let sideCards = itemsForSection(.side).compactMap { item -> DeckCard? in
            guard let card = cardForItem(item) else { return nil }
            return DeckCard(card: card, quantity: item.qty)
        }

        let runeCards = itemsForSection(.rune).compactMap { item -> DeckCard? in
            guard let card = cardForItem(item) else { return nil }
            return DeckCard(card: card, quantity: item.qty)
        }

        return DeckValidator.validate(
            mainCards: mainCards,
            sideCards: sideCards,
            runeCards: runeCards,
            legendChampionTag: deck.legendChampionTag,
            legendDomains: deck.legendDomains
        )
    }

    // MARK: - Export

    func exportJSON() throws -> String {
        guard let deck = deck else {
            throw ExportError.encodingFailed
        }

        return try DeckExporter.exportToJSON(deck: deck, items: items)
    }
}
