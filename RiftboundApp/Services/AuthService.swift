import Foundation
import CloudKit
import AuthenticationServices
import CryptoKit

@MainActor
class AuthService: NSObject, ObservableObject {
    static let shared = AuthService()

    private let cloudKit = CloudKitService.shared
    private var currentUserRecordID: CKRecord.ID?

    private override init() {
        super.init()
    }

    // MARK: - User Fetching

    func fetchOrCreateUser() async throws -> RBUser? {
        guard let userRecordID = try await cloudKit.fetchUserRecordID() else {
            throw AppError.noUserRecordID
        }

        currentUserRecordID = userRecordID
        let recordName = "user_\(userRecordID.recordName)"

        do {
            let record = try await cloudKit.fetch(
                recordID: CKRecord.ID(recordName: recordName),
                database: cloudKit.publicDatabase
            )
            return try RBUser(from: record)
        } catch CloudKitError.recordNotFound {
            // User doesn't exist yet
            return nil
        }
    }

    func createUserProfile(
        userRecordID: CKRecord.ID,
        displayName: String,
        siwaUserIdentifier: String? = nil
    ) async throws -> RBUser {
        // Validate username
        guard !displayName.isEmpty else {
            throw ValidationError.emptyUsername
        }

        let normalizedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedName.count >= 3, normalizedName.count <= 20 else {
            throw ValidationError.usernameTooShort
        }

        // Check if username already exists
        let predicate = NSPredicate(format: "displayName == %@", normalizedName)
        let existingUsers = try await cloudKit.query(
            recordType: AppConfig.RecordType.user.rawValue,
            predicate: predicate,
            database: cloudKit.publicDatabase
        )

        if !existingUsers.isEmpty {
            throw AppError.usernameExists
        }

        // Hash SIWA identifier if provided
        let siwaHash = siwaUserIdentifier.map { hashString($0) }

        // Create user
        var user = RBUser(
            userRecordID: userRecordID,
            displayName: normalizedName,
            siwaSubHash: siwaHash
        )

        let record = user.toCKRecord()
        _ = try await cloudKit.save(record: record, database: cloudKit.publicDatabase)

        return user
    }

    // MARK: - Sign in with Apple

    func performSignInWithApple() async throws -> ASAuthorizationAppleIDCredential {
        return try await withCheckedThrowingContinuation { continuation in
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName]

            let controller = ASAuthorizationController(authorizationRequests: [request])
            let delegate = SignInDelegate(continuation: continuation)
            controller.delegate = delegate
            controller.performRequests()

            // Keep delegate alive
            objc_setAssociatedObject(controller, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    // MARK: - Helpers

    private func hashString(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Sign In Delegate

private class SignInDelegate: NSObject, ASAuthorizationControllerDelegate {
    let continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>

    init(continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>) {
        self.continuation = continuation
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
            continuation.resume(returning: credential)
        } else {
            continuation.resume(throwing: AuthError.invalidCredential)
        }
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        continuation.resume(throwing: error)
    }
}

// MARK: - Errors

enum AuthError: LocalizedError {
    case invalidCredential
    case cancelled

    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "Invalid credentials received"
        case .cancelled:
            return "Sign in was cancelled"
        }
    }
}

enum ValidationError: LocalizedError {
    case emptyUsername
    case usernameTooShort

    var errorDescription: String? {
        switch self {
        case .emptyUsername:
            return "Username cannot be empty"
        case .usernameTooShort:
            return "Username must be between 3 and 20 characters"
        }
    }
}
