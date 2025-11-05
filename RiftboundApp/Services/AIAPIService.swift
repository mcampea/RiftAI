import Foundation

class AIAPIService {
    static let shared = AIAPIService()

    private let baseURL: String
    private let session: URLSession

    private init() {
        self.baseURL = AppConfig.AI_API_BASE_URL
        self.session = URLSession.shared
    }

    // MARK: - API Request/Response

    struct AskRequest: Codable {
        let mode: String // "coach" | "judge"
        let question: String
        let deckId: String?
        let deckSnapshot: DeckSnapshot?
        let selection: [String]? // Optional card IDs
        let rulesEdition: String

        struct DeckSnapshot: Codable {
            let legend: Legend
            let main: [[String]]
            let side: [[String]]
            let runes: [[String]]

            struct Legend: Codable {
                let championTag: String
                let domains: [String]
            }
        }
    }

    struct AskResponse: Codable {
        let answerMarkdown: String
        let citations: [Citation]

        struct Citation: Codable {
            let type: String
            let ref: String
            let id: String?
        }
    }

    // MARK: - Ask Method

    func ask(
        question: String,
        mode: AIMode,
        deck: RBDeck? = nil,
        selection: [String]? = nil
    ) async throws -> AskResponse {
        let url = URL(string: "\(baseURL)/ai/ask")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Build request body
        let deckSnapshot: AskRequest.DeckSnapshot? = nil // TODO: Build from deck if needed

        let askRequest = AskRequest(
            mode: mode == .coach ? "coach" : "judge",
            question: question,
            deckId: deck?.id,
            deckSnapshot: deckSnapshot,
            selection: selection,
            rulesEdition: AppConfig.RULES_EDITION
        )

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(askRequest)

        // Make request
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIAPIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw AIAPIError.serverError(statusCode: httpResponse.statusCode)
        }

        // Parse response
        let decoder = JSONDecoder()
        let askResponse = try decoder.decode(AskResponse.self, from: data)

        return askResponse
    }

    // MARK: - Build Deck Snapshot

    private func buildDeckSnapshot(
        deck: RBDeck,
        items: [RBDeckItem]
    ) -> AskRequest.DeckSnapshot {
        let legend = AskRequest.DeckSnapshot.Legend(
            championTag: deck.legendChampionTag,
            domains: deck.legendDomains
        )

        let main = items
            .filter { $0.section == "main" }
            .map { [$0.cardRef.recordID.recordName, String($0.qty)] }

        let side = items
            .filter { $0.section == "side" }
            .map { [$0.cardRef.recordID.recordName, String($0.qty)] }

        let runes = items
            .filter { $0.section == "rune" }
            .map { [$0.cardRef.recordID.recordName, String($0.qty)] }

        return AskRequest.DeckSnapshot(
            legend: legend,
            main: main,
            side: side,
            runes: runes
        )
    }
}

// MARK: - Errors

enum AIAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let code):
            return "Server error: \(code)"
        case .decodingError:
            return "Failed to decode response"
        }
    }
}

// MARK: - Response Extensions

extension AIAPIService.AskResponse {
    var citations: [AIMessage.Citation] {
        self.citations.map { citation in
            AIMessage.Citation(
                type: citation.type,
                ref: citation.ref
            )
        }
    }
}
