import Foundation
import CloudKit

struct RBVote: Identifiable, Codable {
    let id: String // recordName (vote_<deckId>_<userRecordID>)
    var deckRef: CKRecord.Reference
    var voterUserRef: CKRecord.Reference
    var createdAt: Date

    var ckRecordID: CKRecord.ID {
        CKRecord.ID(recordName: id)
    }

    // Initialize from CloudKit record
    init(from record: CKRecord) throws {
        guard let deckRef = record["deckRef"] as? CKRecord.Reference,
              let voterUserRef = record["voterUserRef"] as? CKRecord.Reference,
              let createdAt = record["createdAt"] as? Date else {
            throw CloudKitError.invalidRecord
        }

        self.id = record.recordID.recordName
        self.deckRef = deckRef
        self.voterUserRef = voterUserRef
        self.createdAt = createdAt
    }

    // Initialize for creation
    init(deckID: String, voterUserID: String) {
        self.id = "vote_\(deckID)_\(voterUserID)"
        self.deckRef = CKRecord.Reference(
            recordID: CKRecord.ID(recordName: deckID),
            action: .none
        )
        self.voterUserRef = CKRecord.Reference(
            recordID: CKRecord.ID(recordName: voterUserID),
            action: .none
        )
        self.createdAt = Date()
    }

    // Convert to CloudKit record
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: AppConfig.RecordType.vote.rawValue,
                             recordID: CKRecord.ID(recordName: id))

        record["deckRef"] = deckRef
        record["voterUserRef"] = voterUserRef
        record["createdAt"] = createdAt as CKRecordValue

        return record
    }
}
