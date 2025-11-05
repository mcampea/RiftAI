import SwiftUI

struct DeckDetailView: View {
    let deckID: String

    @StateObject private var viewModel: DeckDetailViewModel
    @State private var selectedSection: AppConfig.DeckSection = .main
    @State private var showingAddCard = false
    @State private var showingLegality = false
    @State private var showingExport = false

    init(deckID: String) {
        self.deckID = deckID
        _viewModel = StateObject(wrappedValue: DeckDetailViewModel(deckID: deckID))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Section Picker
            Picker("Section", selection: $selectedSection) {
                ForEach(AppConfig.DeckSection.allCases, id: \.self) { section in
                    Text(section.displayName).tag(section)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            // Card List
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                cardListForSection(selectedSection)
            }
        }
        .navigationTitle(viewModel.deck?.title ?? "Deck")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingAddCard = true
                    } label: {
                        Label("Add Cards", systemImage: "plus")
                    }

                    Button {
                        showingLegality = true
                    } label: {
                        Label("Check Legality", systemImage: "checkmark.shield")
                    }

                    Button {
                        showingExport = true
                    } label: {
                        Label("Export/Share", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddCard) {
            AddCardsToDeckView(viewModel: viewModel, section: selectedSection)
        }
        .sheet(isPresented: $showingLegality) {
            DeckLegalityView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingExport) {
            DeckExportView(viewModel: viewModel)
        }
        .task {
            await viewModel.loadDeck()
        }
    }

    @ViewBuilder
    private func cardListForSection(_ section: AppConfig.DeckSection) -> some View {
        let items = viewModel.itemsForSection(section)

        if items.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "rectangle.on.rectangle.slash")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)

                Text("No cards in \(section.displayName)")
                    .font(.headline)

                Button {
                    showingAddCard = true
                } label: {
                    Label("Add Cards", systemImage: "plus")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                ForEach(items) { item in
                    DeckCardRowView(item: item, card: viewModel.cardForItem(item))
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                Task {
                                    await viewModel.removeCard(item)
                                }
                            } label: {
                                Label("Remove", systemImage: "minus.circle")
                            }

                            Button {
                                Task {
                                    await viewModel.adjustQuantity(item, by: 1)
                                }
                            } label: {
                                Label("Add 1", systemImage: "plus")
                            }
                            .tint(.green)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            if section == .main {
                                Button {
                                    Task {
                                        await viewModel.moveCard(item, to: .side)
                                    }
                                } label: {
                                    Label("To Side", systemImage: "arrow.right")
                                }
                                .tint(.blue)
                            } else if section == .side {
                                Button {
                                    Task {
                                        await viewModel.moveCard(item, to: .main)
                                    }
                                } label: {
                                    Label("To Main", systemImage: "arrow.left")
                                }
                                .tint(.blue)
                            }
                        }
                }
            }
            .listStyle(.plain)

            // Footer with count
            footerForSection(section, count: viewModel.countForSection(section))
        }
    }

    @ViewBuilder
    private func footerForSection(_ section: AppConfig.DeckSection, count: Int) -> some View {
        HStack {
            Text("\(section.displayName): \(count)")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            Spacer()

            if section == .main {
                if count < AppConfig.DECK_MINIMUM_MAIN {
                    Label("Min \(AppConfig.DECK_MINIMUM_MAIN)", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            } else if section == .rune {
                if count != AppConfig.RUNE_DECK_SIZE {
                    Label("Need \(AppConfig.RUNE_DECK_SIZE)", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Deck Card Row View

struct DeckCardRowView: View {
    let item: RBDeckItem
    let card: RBCard?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(card?.name ?? "Unknown Card")
                    .font(.subheadline)

                if let card = card {
                    HStack {
                        Text(card.type)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if let cost = card.energyCost {
                            Text("•")
                                .foregroundStyle(.secondary)
                            Text("Cost \(cost)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Spacer()

            Text("\(item.qty)x")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        DeckDetailView(deckID: "deck_preview")
            .environmentObject(AppState())
    }
}
