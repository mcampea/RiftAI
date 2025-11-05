import Foundation
import SwiftData

@MainActor
class CardBrowserViewModel: ObservableObject {
    @Published var cards: [RBCard] = []
    @Published var isLoading = false
    @Published var filters = CardFilters()
    @Published var sortOption: CardSortOption = .name

    private let cloudKit = CloudKitService.shared

    func loadCards(from modelContext: ModelContext) async {
        // Try loading from cache first
        let descriptor = FetchDescriptor<CachedCard>()
        if let cachedCards = try? modelContext.fetch(descriptor) {
            cards = cachedCards.map { $0.toRBCard() }

            // If cache is old or empty, refresh
            if cards.isEmpty || shouldRefreshCache(cachedCards) {
                await refreshFromCloudKit(modelContext: modelContext)
            }
        } else {
            await refreshFromCloudKit(modelContext: modelContext)
        }
    }

    func refreshFromCloudKit(modelContext: ModelContext) async {
        isLoading = true

        do {
            let records = try await cloudKit.query(
                recordType: AppConfig.RecordType.card.rawValue,
                database: cloudKit.publicDatabase
            )

            let fetchedCards = records.compactMap { try? RBCard(from: $0) }
            cards = fetchedCards

            // Update cache
            updateCache(cards: fetchedCards, modelContext: modelContext)
        } catch {
            print("Failed to fetch cards: \(error)")
        }

        isLoading = false
    }

    func filteredCards(searchText: String) -> [RBCard] {
        var result = cards

        // Search filter
        if !searchText.isEmpty {
            result = result.filter { card in
                card.name.localizedCaseInsensitiveContains(searchText) ||
                card.rulesText.localizedCaseInsensitiveContains(searchText) ||
                card.keywords.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
            }
        }

        // Domain filter
        if !filters.selectedDomains.isEmpty {
            result = result.filter { card in
                !Set(card.domains).isDisjoint(with: filters.selectedDomains)
            }
        }

        // Type filter
        if !filters.selectedTypes.isEmpty {
            result = result.filter { card in
                filters.selectedTypes.contains(card.type)
            }
        }

        // Cost filter
        if let minCost = filters.minCost {
            result = result.filter { card in
                (card.energyCost ?? 0) >= minCost
            }
        }
        if let maxCost = filters.maxCost {
            result = result.filter { card in
                (card.energyCost ?? 999) <= maxCost
            }
        }

        // Might filter
        if let minMight = filters.minMight {
            result = result.filter { card in
                (card.might ?? 0) >= minMight
            }
        }
        if let maxMight = filters.maxMight {
            result = result.filter { card in
                (card.might ?? 999) <= maxMight
            }
        }

        // Signature filter
        if filters.signaturesOnly {
            result = result.filter { $0.isSignature }
        }

        // Rune filter
        if filters.runesOnly {
            result = result.filter { $0.isRune }
        }

        // Battlefield filter
        if filters.battlefieldsOnly {
            result = result.filter { $0.isBattlefield }
        }

        // Sort
        result = sortCards(result, by: sortOption)

        return result
    }

    private func sortCards(_ cards: [RBCard], by option: CardSortOption) -> [RBCard] {
        switch option {
        case .name:
            return cards.sorted { $0.name < $1.name }
        case .cost:
            return cards.sorted { ($0.energyCost ?? 0) < ($1.energyCost ?? 0) }
        case .might:
            return cards.sorted { ($0.might ?? 0) < ($1.might ?? 0) }
        case .setNumber:
            return cards.sorted { $0.setCode + $0.number < $1.setCode + $1.number }
        }
    }

    private func shouldRefreshCache(_ cachedCards: [CachedCard]) -> Bool {
        guard let oldestCard = cachedCards.min(by: { $0.lastSynced < $1.lastSynced }) else {
            return true
        }

        let hoursSinceSync = Date().timeIntervalSince(oldestCard.lastSynced) / 3600
        return hoursSinceSync > 24 // Refresh if older than 24 hours
    }

    private func updateCache(cards: [RBCard], modelContext: ModelContext) {
        // Clear old cache
        let deleteDescriptor = FetchDescriptor<CachedCard>()
        if let oldCards = try? modelContext.fetch(deleteDescriptor) {
            oldCards.forEach { modelContext.delete($0) }
        }

        // Insert new cards
        cards.forEach { card in
            let cached = CachedCard(from: card)
            modelContext.insert(cached)
        }

        try? modelContext.save()
    }
}

// MARK: - Filters

struct CardFilters {
    var selectedDomains: Set<String> = []
    var selectedTypes: Set<String> = []
    var minCost: Int?
    var maxCost: Int?
    var minMight: Int?
    var maxMight: Int?
    var signaturesOnly = false
    var runesOnly = false
    var battlefieldsOnly = false

    var isActive: Bool {
        !selectedDomains.isEmpty ||
        !selectedTypes.isEmpty ||
        minCost != nil ||
        maxCost != nil ||
        minMight != nil ||
        maxMight != nil ||
        signaturesOnly ||
        runesOnly ||
        battlefieldsOnly
    }

    mutating func reset() {
        selectedDomains = []
        selectedTypes = []
        minCost = nil
        maxCost = nil
        minMight = nil
        maxMight = nil
        signaturesOnly = false
        runesOnly = false
        battlefieldsOnly = false
    }
}

enum CardSortOption: String, CaseIterable, Identifiable {
    case name = "Name"
    case cost = "Cost"
    case might = "Might"
    case setNumber = "Set/Number"

    var id: String { rawValue }
}
