import Foundation
import CloudKit

struct RBDeckItem: Identifiable, Codable {
    let id: String // recordName (deckitem_<deckId>_<cardId>_<section>)
    var deckRef: CKRecord.Reference
    var cardRef: CKRecord.Reference
    var section: String // "main" | "side" | "rune"
    var qty: Int

    var ckRecordID: CKRecord.ID {
        CKRecord.ID(recordName: id)
    }

    var sectionEnum: AppConfig.DeckSection? {
        AppConfig.DeckSection(rawValue: section)
    }

    // Initialize from CloudKit record
    init(from record: CKRecord) throws {
        guard let deckRef = record["deckRef"] as? CKRecord.Reference,
              let cardRef = record["cardRef"] as? CKRecord.Reference,
              let section = record["section"] as? String,
              let qty = record["qty"] as? Int else {
            throw CloudKitError.invalidRecord
        }

        self.id = record.recordID.recordName
        self.deckRef = deckRef
        self.cardRef = cardRef
        self.section = section
        self.qty = qty
    }

    // Initialize for creation
    init(deckID: String, cardID: String, section: AppConfig.DeckSection, qty: Int) {
        self.id = "deckitem_\(deckID)_\(cardID)_\(section.rawValue)"
        self.deckRef = CKRecord.Reference(
            recordID: CKRecord.ID(recordName: deckID),
            action: .deleteSelf
        )
        self.cardRef = CKRecord.Reference(
            recordID: CKRecord.ID(recordName: cardID),
            action: .none
        )
        self.section = section.rawValue
        self.qty = qty
    }

    // Convert to CloudKit record
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: AppConfig.RecordType.deckItem.rawValue,
                             recordID: CKRecord.ID(recordName: id))

        record["deckRef"] = deckRef
        record["cardRef"] = cardRef
        record["section"] = section as CKRecordValue
        record["qty"] = qty as CKRecordValue

        return record
    }
}
