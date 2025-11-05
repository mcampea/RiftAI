import Foundation
import CloudKit

struct RBDeck: Identifiable, Codable {
    let id: String // recordName (deck_<uuid>)
    var ownerUserRef: CKRecord.Reference
    var title: String
    var description: String?
    var legendChampionTag: String
    var legendDomains: [String]
    var isPublic: Bool
    var countMain: Int
    var countSide: Int
    var countRunes: Int
    var createdAt: Date
    var updatedAt: Date

    var ckRecordID: CKRecord.ID {
        CKRecord.ID(recordName: id)
    }

    // Initialize from CloudKit record
    init(from record: CKRecord) throws {
        guard let ownerUserRef = record["ownerUserRef"] as? CKRecord.Reference,
              let title = record["title"] as? String,
              let legendChampionTag = record["legendChampionTag"] as? String,
              let legendDomains = record["legendDomains"] as? [String],
              let isPublic = record["isPublic"] as? Int,
              let countMain = record["countMain"] as? Int,
              let countSide = record["countSide"] as? Int,
              let countRunes = record["countRunes"] as? Int,
              let createdAt = record["createdAt"] as? Date,
              let updatedAt = record["updatedAt"] as? Date else {
            throw CloudKitError.invalidRecord
        }

        self.id = record.recordID.recordName
        self.ownerUserRef = ownerUserRef
        self.title = title
        self.description = record["description"] as? String
        self.legendChampionTag = legendChampionTag
        self.legendDomains = legendDomains
        self.isPublic = isPublic == 1
        self.countMain = countMain
        self.countSide = countSide
        self.countRunes = countRunes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // Initialize for creation
    init(ownerUserID: String,
         title: String,
         description: String? = nil,
         legendChampionTag: String,
         legendDomains: [String],
         isPublic: Bool = false) {
        self.id = "deck_\(UUID().uuidString)"
        self.ownerUserRef = CKRecord.Reference(
            recordID: CKRecord.ID(recordName: ownerUserID),
            action: .none
        )
        self.title = title
        self.description = description
        self.legendChampionTag = legendChampionTag
        self.legendDomains = legendDomains
        self.isPublic = isPublic
        self.countMain = 0
        self.countSide = 0
        self.countRunes = 0
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // Convert to CloudKit record
    func toCKRecord(in database: CKDatabase.Scope = .private) -> CKRecord {
        let recordID = CKRecord.ID(recordName: id)
        let record = CKRecord(recordType: AppConfig.RecordType.deck.rawValue,
                             recordID: recordID)

        record["ownerUserRef"] = ownerUserRef
        record["title"] = title as CKRecordValue
        record["legendChampionTag"] = legendChampionTag as CKRecordValue
        record["legendDomains"] = legendDomains as CKRecordValue
        record["isPublic"] = (isPublic ? 1 : 0) as CKRecordValue
        record["countMain"] = countMain as CKRecordValue
        record["countSide"] = countSide as CKRecordValue
        record["countRunes"] = countRunes as CKRecordValue
        record["createdAt"] = createdAt as CKRecordValue
        record["updatedAt"] = updatedAt as CKRecordValue

        if let description = description {
            record["description"] = description as CKRecordValue
        }

        return record
    }
}
