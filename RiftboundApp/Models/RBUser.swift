import Foundation
import CloudKit

struct RBUser: Identifiable, Codable {
    let id: String // recordName
    var displayName: String
    var siwaSubHash: String?
    var avatarAsset: CKAsset?
    var createdAt: Date

    var ckRecordID: CKRecord.ID {
        CKRecord.ID(recordName: id)
    }

    // Initialize from CloudKit record
    init(from record: CKRecord) throws {
        guard let displayName = record["displayName"] as? String,
              let createdAt = record["createdAt"] as? Date else {
            throw CloudKitError.invalidRecord
        }

        self.id = record.recordID.recordName
        self.displayName = displayName
        self.siwaSubHash = record["siwaSubHash"] as? String
        self.avatarAsset = record["avatarAsset"] as? CKAsset
        self.createdAt = createdAt
    }

    // Initialize for creation
    init(userRecordID: CKRecord.ID, displayName: String, siwaSubHash: String? = nil) {
        self.id = "user_\(userRecordID.recordName)"
        self.displayName = displayName
        self.siwaSubHash = siwaSubHash
        self.createdAt = Date()
    }

    // Convert to CloudKit record
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: AppConfig.RecordType.user.rawValue,
                             recordID: CKRecord.ID(recordName: id))
        record["displayName"] = displayName as CKRecordValue
        record["createdAt"] = createdAt as CKRecordValue

        if let siwaSubHash = siwaSubHash {
            record["siwaSubHash"] = siwaSubHash as CKRecordValue
        }
        if let avatarAsset = avatarAsset {
            record["avatarAsset"] = avatarAsset
        }

        return record
    }
}
