import Foundation
import CloudKit

enum CloudKitError: LocalizedError {
    case invalidRecord
    case recordNotFound
    case networkUnavailable
    case permissionDenied
    case quotaExceeded
    case conflict
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidRecord:
            return "The record is invalid or missing required fields"
        case .recordNotFound:
            return "The requested record was not found"
        case .networkUnavailable:
            return "Network connection is unavailable"
        case .permissionDenied:
            return "You don't have permission to perform this action"
        case .quotaExceeded:
            return "CloudKit quota exceeded"
        case .conflict:
            return "A conflict occurred while saving"
        case .unknown(let error):
            return error.localizedDescription
        }
    }

    static func from(_ error: Error) -> CloudKitError {
        guard let ckError = error as? CKError else {
            return .unknown(error)
        }

        switch ckError.code {
        case .networkUnavailable, .networkFailure:
            return .networkUnavailable
        case .notAuthenticated, .permissionFailure:
            return .permissionDenied
        case .quotaExceeded:
            return .quotaExceeded
        case .serverRecordChanged, .batchRequestFailed:
            return .conflict
        case .unknownItem:
            return .recordNotFound
        default:
            return .unknown(error)
        }
    }
}
