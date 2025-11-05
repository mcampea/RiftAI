import Foundation
import CloudKit

struct RBCard: Identifiable, Codable, Hashable {
    let id: String // recordName (card_<uuid>)
    var number: String
    var name: String
    var type: String
    var domains: [String]
    var energyCost: Int?
    var powerCostJSON: String? // For multi-mode costs
    var might: Int?
    var keywords: [String]
    var tags: [String]
    var rulesText: String
    var isSignature: Bool
    var championTag: String?
    var isBattlefield: Bool
    var isRune: Bool
    var setCode: String
    var rarity: String?

    var ckRecordID: CKRecord.ID {
        CKRecord.ID(recordName: id)
    }

    // Initialize from CloudKit record
    init(from record: CKRecord) throws {
        guard let number = record["number"] as? String,
              let name = record["name"] as? String,
              let type = record["type"] as? String,
              let domains = record["domains"] as? [String],
              let keywords = record["keywords"] as? [String],
              let tags = record["tags"] as? [String],
              let rulesText = record["rulesText"] as? String,
              let setCode = record["setCode"] as? String else {
            throw CloudKitError.invalidRecord
        }

        self.id = record.recordID.recordName
        self.number = number
        self.name = name
        self.type = type
        self.domains = domains
        self.energyCost = record["energyCost"] as? Int
        self.powerCostJSON = record["powerCostJSON"] as? String
        self.might = record["might"] as? Int
        self.keywords = keywords
        self.tags = tags
        self.rulesText = rulesText
        self.isSignature = (record["isSignature"] as? Int ?? 0) == 1
        self.championTag = record["championTag"] as? String
        self.isBattlefield = (record["isBattlefield"] as? Int ?? 0) == 1
        self.isRune = (record["isRune"] as? Int ?? 0) == 1
        self.setCode = setCode
        self.rarity = record["rarity"] as? String
    }

    // Convert to CloudKit record
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: AppConfig.RecordType.card.rawValue,
                             recordID: CKRecord.ID(recordName: id))

        record["number"] = number as CKRecordValue
        record["name"] = name as CKRecordValue
        record["type"] = type as CKRecordValue
        record["domains"] = domains as CKRecordValue
        record["keywords"] = keywords as CKRecordValue
        record["tags"] = tags as CKRecordValue
        record["rulesText"] = rulesText as CKRecordValue
        record["isSignature"] = (isSignature ? 1 : 0) as CKRecordValue
        record["isBattlefield"] = (isBattlefield ? 1 : 0) as CKRecordValue
        record["isRune"] = (isRune ? 1 : 0) as CKRecordValue
        record["setCode"] = setCode as CKRecordValue

        if let energyCost = energyCost {
            record["energyCost"] = energyCost as CKRecordValue
        }
        if let powerCostJSON = powerCostJSON {
            record["powerCostJSON"] = powerCostJSON as CKRecordValue
        }
        if let might = might {
            record["might"] = might as CKRecordValue
        }
        if let championTag = championTag {
            record["championTag"] = championTag as CKRecordValue
        }
        if let rarity = rarity {
            record["rarity"] = rarity as CKRecordValue
        }

        return record
    }
}
