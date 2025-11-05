import SwiftUI
import CloudKit

@MainActor
class AppState: ObservableObject {
    @Published var isInitialized = false
    @Published var currentUser: RBUser?
    @Published var authState: AuthState = .checking
    @Published var errorMessage: String?

    let cloudKitService = CloudKitService.shared
    let authService = AuthService.shared

    enum AuthState {
        case checking
        case needsiCloudSignIn
        case needsUsernameSetup
        case authenticated
    }

    func initialize() async {
        do {
            // Check iCloud availability
            let accountStatus = try await cloudKitService.checkAccountStatus()

            guard accountStatus == .available else {
                authState = .needsiCloudSignIn
                return
            }

            // Try to fetch or create user
            if let user = try await authService.fetchOrCreateUser() {
                currentUser = user
                authState = user.displayName.isEmpty ? .needsUsernameSetup : .authenticated
            } else {
                authState = .needsUsernameSetup
            }

            isInitialized = true
        } catch {
            errorMessage = "Failed to initialize: \(error.localizedDescription)"
            authState = .needsiCloudSignIn
        }
    }

    func setUsername(_ username: String) async throws {
        guard let userRecordID = try await cloudKitService.fetchUserRecordID() else {
            throw AppError.noUserRecordID
        }

        let user = try await authService.createUserProfile(
            userRecordID: userRecordID,
            displayName: username
        )

        currentUser = user
        authState = .authenticated
    }
}

enum AppError: LocalizedError {
    case noUserRecordID
    case usernameExists
    case iCloudUnavailable

    var errorDescription: String? {
        switch self {
        case .noUserRecordID:
            return "Could not fetch user record ID"
        case .usernameExists:
            return "This username is already taken"
        case .iCloudUnavailable:
            return "iCloud is not available. Please sign in to iCloud in Settings."
        }
    }
}
