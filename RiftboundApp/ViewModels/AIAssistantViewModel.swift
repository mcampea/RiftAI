import Foundation

@MainActor
class AIAssistantViewModel: ObservableObject {
    @Published var messages: [AIMessage] = []
    @Published var isLoading = false
    @Published var selectedDeck: RBDeck?

    private let apiService = AIAPIService.shared

    func selectDeck(_ deck: RBDeck) {
        selectedDeck = deck
    }

    func sendMessage(_ text: String, mode: AIMode) async {
        // Add user message
        let userMessage = AIMessage(text: text, isUser: true)
        messages.append(userMessage)

        isLoading = true

        do {
            // Call AI API
            let response = try await apiService.ask(
                question: text,
                mode: mode,
                deck: selectedDeck
            )

            // Add assistant message
            let assistantMessage = AIMessage(
                text: response.answerMarkdown,
                isUser: false,
                citations: response.citations
            )
            messages.append(assistantMessage)
        } catch {
            // Add error message
            let errorMessage = AIMessage(
                text: "Sorry, I couldn't process your request: \(error.localizedDescription)",
                isUser: false
            )
            messages.append(errorMessage)
        }

        isLoading = false
    }

    func clearChat() {
        messages = []
    }
}

// MARK: - AI Message

struct AIMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let citations: [Citation]
    let timestamp: Date

    init(text: String, isUser: Bool, citations: [Citation] = []) {
        self.text = text
        self.isUser = isUser
        self.citations = citations
        self.timestamp = Date()
    }

    struct Citation {
        let type: String // "rule" or "card"
        let ref: String
    }
}
