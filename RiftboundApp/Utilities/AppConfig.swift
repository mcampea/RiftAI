import Foundation

struct AppConfig {
    // CloudKit Configuration
    static let containerIdentifier = "iCloud.com.riftbound.app"

    // Deck Building Rules
    static let DECK_MINIMUM_MAIN = 40
    static let DECK_COPY_LIMIT = 3
    static let DECK_COPY_RULE_STRICT = false // If true, enforce global 3 across Main+Side
    static let SIGNATURE_CAP = 3
    static let SIGNATURE_INCLUDES_SIDEBOARD = false
    static let RUNE_DECK_SIZE = 12
    static let SIDEBOARD_MAX: Int? = nil // No cap in v1

    // API Configuration
    static let AI_API_BASE_URL: String = {
        // In production, read from Info.plist or environment
        return ProcessInfo.processInfo.environment["AI_API_BASE_URL"] ?? "https://api.riftbound.com"
    }()

    // Rules Edition
    static let RULES_EDITION = "1.1-100125"

    // App Info
    static let appVersion: String = {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }()

    // CloudKit Record Types
    enum RecordType: String {
        case user = "RBUser"
        case card = "RBCard"
        case deck = "RBDeck"
        case deckItem = "RBDeckItem"
        case vote = "RBVote"
    }

    // Deck Sections
    enum DeckSection: String, Codable, CaseIterable {
        case main
        case side
        case rune

        var displayName: String {
            switch self {
            case .main: return "Main"
            case .side: return "Sideboard"
            case .rune: return "Runes"
            }
        }
    }
}
