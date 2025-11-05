import SwiftUI
import SwiftData

struct CardBrowserView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var cachedCards: [CachedCard]

    @StateObject private var viewModel = CardBrowserViewModel()
    @State private var showFilters = false
    @State private var searchText = ""

    var filteredCards: [RBCard] {
        viewModel.filteredCards(searchText: searchText)
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.cards.isEmpty {
                    ProgressView("Loading cards...")
                } else if viewModel.cards.isEmpty {
                    emptyStateView
                } else {
                    cardListView
                }
            }
            .navigationTitle("Card Browser")
            .searchable(text: $searchText, prompt: "Search cards")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showFilters.toggle()
                    } label: {
                        Label("Filters", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }

                ToolbarItem(placement: .secondaryAction) {
                    Menu {
                        Picker("Sort By", selection: $viewModel.sortOption) {
                            ForEach(CardSortOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                    }
                }
            }
            .sheet(isPresented: $showFilters) {
                CardFiltersView(filters: $viewModel.filters)
            }
            .task {
                await viewModel.loadCards(from: modelContext)
            }
            .refreshable {
                await viewModel.refreshFromCloudKit(modelContext: modelContext)
            }
        }
    }

    private var cardListView: some View {
        List(filteredCards) { card in
            NavigationLink(destination: CardDetailView(card: card)) {
                CardRowView(card: card)
            }
        }
        .listStyle(.plain)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.on.rectangle.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Cards Found")
                .font(.headline)

            Text("Pull to refresh or check your filters")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Card Row View

struct CardRowView: View {
    let card: RBCard

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(card.name)
                    .font(.headline)

                Spacer()

                if let cost = card.energyCost {
                    Text("\(cost)")
                        .font(.caption.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                }
            }

            HStack {
                Text(card.type)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !card.domains.isEmpty {
                    Text("•")
                        .foregroundStyle(.secondary)

                    Text(card.domains.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if card.isSignature {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Card Detail View

struct CardDetailView: View {
    let card: RBCard

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(card.name)
                        .font(.title.bold())

                    HStack {
                        Text(card.type)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        if let rarity = card.rarity {
                            Text("•")
                                .foregroundStyle(.secondary)
                            Text(rarity)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Divider()

                // Stats
                VStack(alignment: .leading, spacing: 8) {
                    if !card.domains.isEmpty {
                        InfoRow(label: "Domains", value: card.domains.joined(separator: ", "))
                    }

                    if let cost = card.energyCost {
                        InfoRow(label: "Energy Cost", value: "\(cost)")
                    }

                    if let might = card.might {
                        InfoRow(label: "Might", value: "\(might)")
                    }

                    if !card.keywords.isEmpty {
                        InfoRow(label: "Keywords", value: card.keywords.joined(separator: ", "))
                    }
                }

                Divider()

                // Rules Text
                VStack(alignment: .leading, spacing: 8) {
                    Text("Rules Text")
                        .font(.headline)

                    Text(card.rulesText)
                        .font(.body)
                }

                // Tags
                if !card.tags.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags")
                            .font(.headline)

                        FlowLayout(spacing: 8) {
                            ForEach(card.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }

                // Set Info
                Divider()

                InfoRow(label: "Set", value: "\(card.setCode) #\(card.number)")
            }
            .padding()
        }
        .navigationTitle("Card Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline.bold())
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Flow Layout for Tags

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

#Preview {
    CardBrowserView()
        .modelContainer(for: [CachedCard.self])
        .environmentObject(AppState())
}
