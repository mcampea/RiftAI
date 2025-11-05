import SwiftUI

struct AddCardsToDeckView: View {
    @ObservedObject var viewModel: DeckDetailViewModel
    let section: AppConfig.DeckSection

    @Environment(\.dismiss) private var dismiss
    @StateObject private var cardBrowser = CardBrowserViewModel()
    @State private var searchText = ""
    @State private var selectedCards: Set<String> = []
    @State private var isAdding = false

    var filteredCards: [RBCard] {
        cardBrowser.filteredCards(searchText: searchText)
    }

    var body: some View {
        NavigationStack {
            List(filteredCards) { card in
                HStack {
                    CardRowView(card: card)

                    Spacer()

                    if selectedCards.contains(card.id) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    toggleSelection(card.id)
                }
            }
            .navigationTitle("Add to \(section.displayName)")
            .searchable(text: $searchText, prompt: "Search cards")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add (\(selectedCards.count))") {
                        Task {
                            await addSelectedCards()
                        }
                    }
                    .disabled(selectedCards.isEmpty || isAdding)
                }
            }
            .task {
                await cardBrowser.loadCards(from: viewModel as! ModelContext) // This is a simplification
            }
        }
    }

    private func toggleSelection(_ cardID: String) {
        if selectedCards.contains(cardID) {
            selectedCards.remove(cardID)
        } else {
            selectedCards.insert(cardID)
        }
    }

    private func addSelectedCards() async {
        isAdding = true
        await viewModel.addCards(Array(selectedCards), to: section)
        dismiss()
    }
}
