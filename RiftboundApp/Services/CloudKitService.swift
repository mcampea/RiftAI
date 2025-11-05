import Foundation
import CloudKit

@MainActor
class CloudKitService {
    static let shared = CloudKitService()

    private let container: CKContainer
    let publicDatabase: CKDatabase
    let privateDatabase: CKDatabase

    private init() {
        self.container = CKContainer(identifier: AppConfig.containerIdentifier)
        self.publicDatabase = container.publicCloudDatabase
        self.privateDatabase = container.privateCloudDatabase
    }

    // MARK: - Account Status

    func checkAccountStatus() async throws -> CKAccountStatus {
        try await container.accountStatus()
    }

    func fetchUserRecordID() async throws -> CKRecord.ID? {
        try await container.userRecordID()
    }

    // MARK: - Query Operations

    func query(
        recordType: String,
        predicate: NSPredicate = NSPredicate(value: true),
        sortDescriptors: [NSSortDescriptor] = [],
        database: CKDatabase? = nil,
        resultsLimit: Int = CKQueryOperation.maximumResults
    ) async throws -> [CKRecord] {
        let db = database ?? publicDatabase
        let query = CKQuery(recordType: recordType, predicate: predicate)
        query.sortDescriptors = sortDescriptors

        var allRecords: [CKRecord] = []
        var cursor: CKQueryOperation.Cursor?

        repeat {
            let (results, nextCursor) = try await db.records(
                matching: query,
                resultsLimit: resultsLimit
            )

            let records = results.compactMap { _, result -> CKRecord? in
                try? result.get()
            }
            allRecords.append(contentsOf: records)
            cursor = nextCursor
        } while cursor != nil

        return allRecords
    }

    // MARK: - Fetch Operations

    func fetch(
        recordID: CKRecord.ID,
        database: CKDatabase? = nil
    ) async throws -> CKRecord {
        let db = database ?? publicDatabase

        do {
            return try await db.record(for: recordID)
        } catch {
            throw CloudKitError.from(error)
        }
    }

    func fetchRecords(
        recordIDs: [CKRecord.ID],
        database: CKDatabase? = nil
    ) async throws -> [CKRecord.ID: CKRecord] {
        let db = database ?? publicDatabase

        do {
            let results = try await db.records(for: recordIDs)
            var records: [CKRecord.ID: CKRecord] = [:]

            for (recordID, result) in results {
                if let record = try? result.get() {
                    records[recordID] = record
                }
            }

            return records
        } catch {
            throw CloudKitError.from(error)
        }
    }

    // MARK: - Save Operations

    func save(
        record: CKRecord,
        database: CKDatabase? = nil
    ) async throws -> CKRecord {
        let db = database ?? privateDatabase

        do {
            return try await db.save(record)
        } catch {
            throw CloudKitError.from(error)
        }
    }

    func save(
        records: [CKRecord],
        database: CKDatabase? = nil
    ) async throws -> [CKRecord] {
        let db = database ?? privateDatabase

        do {
            let results = try await db.modifyRecords(saving: records, deleting: [])
            return results.saveResults.compactMap { _, result in
                try? result.get()
            }
        } catch {
            throw CloudKitError.from(error)
        }
    }

    // MARK: - Delete Operations

    func delete(
        recordID: CKRecord.ID,
        database: CKDatabase? = nil
    ) async throws {
        let db = database ?? privateDatabase

        do {
            _ = try await db.deleteRecord(withID: recordID)
        } catch {
            throw CloudKitError.from(error)
        }
    }

    func delete(
        recordIDs: [CKRecord.ID],
        database: CKDatabase? = nil
    ) async throws {
        let db = database ?? privateDatabase

        do {
            _ = try await db.modifyRecords(saving: [], deleting: recordIDs)
        } catch {
            throw CloudKitError.from(error)
        }
    }

    // MARK: - Modify Operations (Batch Save + Delete)

    func modify(
        recordsToSave: [CKRecord],
        recordIDsToDelete: [CKRecord.ID],
        database: CKDatabase? = nil
    ) async throws -> (saved: [CKRecord], deleted: [CKRecord.ID]) {
        let db = database ?? privateDatabase

        do {
            let results = try await db.modifyRecords(
                saving: recordsToSave,
                deleting: recordIDsToDelete
            )

            let saved = results.saveResults.compactMap { _, result in
                try? result.get()
            }

            let deleted = results.deleteResults.compactMap { recordID, result in
                (try? result.get()) != nil ? recordID : nil
            }

            return (saved, deleted)
        } catch {
            throw CloudKitError.from(error)
        }
    }

    // MARK: - Count Operations

    func count(
        recordType: String,
        predicate: NSPredicate,
        database: CKDatabase? = nil
    ) async throws -> Int {
        // CloudKit doesn't have a native count operation, so we fetch and count
        let records = try await query(
            recordType: recordType,
            predicate: predicate,
            database: database
        )
        return records.count
    }
}
