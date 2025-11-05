import Foundation
import CloudKit

@MainActor
class MyDecksViewModel: ObservableObject {
    @Published var decks: [RBDeck] = []
    @Published var isLoading = false

    private let cloudKit = CloudKitService.shared

    func loadDecks() async {
        isLoading = true

        do {
            // Fetch user's private decks
            let predicate = NSPredicate(value: true)
            let sortDescriptor = NSSortDescriptor(key: "updatedAt", ascending: false)

            let records = try await cloudKit.query(
                recordType: AppConfig.RecordType.deck.rawValue,
                predicate: predicate,
                sortDescriptors: [sortDescriptor],
                database: cloudKit.privateDatabase
            )

            decks = records.compactMap { try? RBDeck(from: $0) }
        } catch {
            print("Failed to load decks: \(error)")
        }

        isLoading = false
    }

    func refreshDecks() async {
        await loadDecks()
    }

    func createDeck(_ deck: RBDeck) async {
        do {
            let record = deck.toCKRecord(in: .private)
            _ = try await cloudKit.save(record: record, database: cloudKit.privateDatabase)

            // Reload decks
            await loadDecks()
        } catch {
            print("Failed to create deck: \(error)")
        }
    }

    func deleteDeck(_ deck: RBDeck) async {
        do {
            // Delete deck and its items
            let database = deck.isPublic ? cloudKit.publicDatabase : cloudKit.privateDatabase

            // Fetch and delete all deck items
            let itemPredicate = NSPredicate(format: "deckRef == %@", deck.ckRecordID)
            let itemRecords = try await cloudKit.query(
                recordType: AppConfig.RecordType.deckItem.rawValue,
                predicate: itemPredicate,
                database: database
            )

            let itemIDs = itemRecords.map { $0.recordID }

            // Delete items and deck
            try await cloudKit.modify(
                recordsToSave: [],
                recordIDsToDelete: itemIDs + [deck.ckRecordID],
                database: database
            )

            // Remove from local list
            decks.removeAll { $0.id == deck.id }
        } catch {
            print("Failed to delete deck: \(error)")
        }
    }

    func togglePublic(_ deck: RBDeck) async {
        do {
            var updatedDeck = deck
            updatedDeck.isPublic.toggle()
            updatedDeck.updatedAt = Date()

            if updatedDeck.isPublic {
                // Move from private to public
                await publishDeck(updatedDeck)
            } else {
                // Move from public to private
                await unpublishDeck(updatedDeck)
            }

            await loadDecks()
        } catch {
            print("Failed to toggle public status: \(error)")
        }
    }

    private func publishDeck(_ deck: RBDeck) async {
        do {
            // Fetch all deck items from private database
            let itemPredicate = NSPredicate(format: "deckRef == %@", deck.ckRecordID)
            let itemRecords = try await cloudKit.query(
                recordType: AppConfig.RecordType.deckItem.rawValue,
                predicate: itemPredicate,
                database: cloudKit.privateDatabase
            )

            // Save deck to public database
            let deckRecord = deck.toCKRecord(in: .public)
            _ = try await cloudKit.save(record: deckRecord, database: cloudKit.publicDatabase)

            // Save items to public database
            _ = try await cloudKit.save(records: itemRecords, database: cloudKit.publicDatabase)

            // Delete from private database
            try await cloudKit.delete(
                recordIDs: [deck.ckRecordID] + itemRecords.map { $0.recordID },
                database: cloudKit.privateDatabase
            )
        } catch {
            print("Failed to publish deck: \(error)")
        }
    }

    private func unpublishDeck(_ deck: RBDeck) async {
        do {
            // Fetch all deck items from public database
            let itemPredicate = NSPredicate(format: "deckRef == %@", deck.ckRecordID)
            let itemRecords = try await cloudKit.query(
                recordType: AppConfig.RecordType.deckItem.rawValue,
                predicate: itemPredicate,
                database: cloudKit.publicDatabase
            )

            // Save deck to private database
            let deckRecord = deck.toCKRecord(in: .private)
            _ = try await cloudKit.save(record: deckRecord, database: cloudKit.privateDatabase)

            // Save items to private database
            _ = try await cloudKit.save(records: itemRecords, database: cloudKit.privateDatabase)

            // Delete from public database (including votes)
            let votePredicate = NSPredicate(format: "deckRef == %@", deck.ckRecordID)
            let voteRecords = try await cloudKit.query(
                recordType: AppConfig.RecordType.vote.rawValue,
                predicate: votePredicate,
                database: cloudKit.publicDatabase
            )

            try await cloudKit.delete(
                recordIDs: [deck.ckRecordID] + itemRecords.map { $0.recordID } + voteRecords.map { $0.recordID },
                database: cloudKit.publicDatabase
            )
        } catch {
            print("Failed to unpublish deck: \(error)")
        }
    }
}
