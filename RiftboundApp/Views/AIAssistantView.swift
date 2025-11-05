import SwiftUI

struct AIAssistantView: View {
    @StateObject private var viewModel = AIAssistantViewModel()
    @State private var messageText = ""
    @State private var selectedMode: AIMode = .coach
    @State private var showingDeckPicker = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Mode Picker
                Picker("Mode", selection: $selectedMode) {
                    ForEach(AIMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Selected Deck Info
                if let deck = viewModel.selectedDeck {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Context: \(deck.title)")
                                .font(.caption.bold())
                            Text(deck.legendChampionTag)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button("Change") {
                            showingDeckPicker = true
                        }
                        .font(.caption)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                } else {
                    Button {
                        showingDeckPicker = true
                    } label: {
                        Label("Select Deck (Optional)", systemImage: "plus.circle")
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color(.systemGroupedBackground))
                    }
                }

                Divider()

                // Chat Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            if viewModel.messages.isEmpty {
                                emptyStateView
                            } else {
                                ForEach(viewModel.messages) { message in
                                    MessageBubbleView(message: message)
                                        .id(message.id)
                                }
                            }

                            if viewModel.isLoading {
                                HStack {
                                    ProgressView()
                                        .padding(.horizontal, 8)
                                    Text("Thinking...")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        if let lastMessage = viewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }

                Divider()

                // Input Bar
                HStack(spacing: 12) {
                    TextField("Ask about strategy, rules, or matchups...", text: $messageText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...4)

                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(messageText.isEmpty ? .gray : .blue)
                    }
                    .disabled(messageText.isEmpty || viewModel.isLoading)
                }
                .padding()
            }
            .navigationTitle("AI Assistant")
            .sheet(isPresented: $showingDeckPicker) {
                DeckPickerView { deck in
                    viewModel.selectDeck(deck)
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            VStack(spacing: 8) {
                Text("AI \(selectedMode.rawValue)")
                    .font(.title2.bold())

                Text(selectedMode.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Example questions:")
                    .font(.caption.bold())

                ForEach(selectedMode.exampleQuestions, id: \.self) { question in
                    Button {
                        messageText = question
                    } label: {
                        Text("• \(question)")
                            .font(.caption)
                            .foregroundStyle(.blue)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .cornerRadius(12)
        }
        .padding()
    }

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        messageText = ""
        Task {
            await viewModel.sendMessage(text, mode: selectedMode)
        }
    }
}

// MARK: - Message Bubble

struct MessageBubbleView: View {
    let message: AIMessage

    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.body)
                    .padding(12)
                    .background(message.isUser ? Color.blue : Color(.systemGray5))
                    .foregroundStyle(message.isUser ? .white : .primary)
                    .cornerRadius(16)

                if !message.citations.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Citations:")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)

                        ForEach(message.citations, id: \.ref) { citation in
                            Text("• \(citation.type): \(citation.ref)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 4)
                }

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity * 0.75, alignment: message.isUser ? .trailing : .leading)

            if !message.isUser {
                Spacer()
            }
        }
    }
}

// MARK: - Deck Picker

struct DeckPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = MyDecksViewModel()

    let onSelect: (RBDeck) -> Void

    var body: some View {
        NavigationStack {
            List(viewModel.decks) { deck in
                Button {
                    onSelect(deck)
                    dismiss()
                } label: {
                    DeckRowView(deck: deck)
                }
            }
            .navigationTitle("Select Deck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadDecks()
            }
        }
    }
}

// MARK: - AI Mode

enum AIMode: String, CaseIterable, Identifiable {
    case coach = "Coach"
    case judge = "Judge"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .coach:
            return "Get strategic advice, mulligan decisions, and matchup guidance"
        case .judge:
            return "Ask about rules, timing, and card interactions"
        }
    }

    var exampleQuestions: [String] {
        switch self {
        case .coach:
            return [
                "What should I mulligan against aggro?",
                "How do I play around control?",
                "What's my win condition in this matchup?"
            ]
        case .judge:
            return [
                "Can I respond to this trigger?",
                "What happens if both players...?",
                "How does priority work here?"
            ]
        }
    }
}

#Preview {
    AIAssistantView()
        .environmentObject(AppState())
}
