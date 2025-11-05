import SwiftUI

struct DeckLegalityView: View {
    @ObservedObject var viewModel: DeckDetailViewModel
    @Environment(\.dismiss) private var dismiss

    var validation: DeckValidator.ValidationResult {
        viewModel.validateDeck()
    }

    var body: some View {
        NavigationStack {
            List {
                // Overall Status
                Section {
                    HStack {
                        Image(systemName: validation.isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(validation.isValid ? .green : .red)
                            .font(.title2)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(validation.isValid ? "Deck is Legal" : "Deck is Not Legal")
                                .font(.headline)

                            Text(validation.isValid ? "Ready to play" : "\(validation.errors.count) issues found")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Errors
                if !validation.errors.isEmpty {
                    Section("Issues") {
                        ForEach(validation.errors) { error in
                            VStack(alignment: .leading, spacing: 8) {
                                Label(error.description, systemImage: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.red)
                                    .font(.subheadline)

                                Text(error.rule)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                // Warnings
                if !validation.warnings.isEmpty {
                    Section("Warnings") {
                        ForEach(validation.warnings) { warning in
                            Label(warning.description, systemImage: "info.circle.fill")
                                .foregroundStyle(.orange)
                                .font(.subheadline)
                        }
                    }
                }

                // Deck Stats
                Section("Deck Statistics") {
                    HStack {
                        Text("Main Deck")
                        Spacer()
                        Text("\(viewModel.countForSection(.main))")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Sideboard")
                        Spacer()
                        Text("\(viewModel.countForSection(.side))")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Rune Deck")
                        Spacer()
                        Text("\(viewModel.countForSection(.rune))")
                            .foregroundStyle(.secondary)
                    }

                    if let deck = viewModel.deck {
                        HStack {
                            Text("Legend")
                            Spacer()
                            Text(deck.legendChampionTag)
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            Text("Domains")
                            Spacer()
                            Text(deck.legendDomains.joined(separator: ", "))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Deck Legality")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
