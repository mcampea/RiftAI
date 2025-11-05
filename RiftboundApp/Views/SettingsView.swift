import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.modelContext) private var modelContext

    @State private var showingClearCacheAlert = false
    @State private var showingLegalDisclaimer = false

    var body: some View {
        NavigationStack {
            List {
                // Profile Section
                if let user = appState.currentUser {
                    Section("Profile") {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.title)
                                .foregroundStyle(.blue)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.displayName)
                                    .font(.headline)

                                Text("iCloud: Connected")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Cache Section
                Section("Data") {
                    Button {
                        showingClearCacheAlert = true
                    } label: {
                        Label("Clear Cache", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                }

                // Legal Section
                Section("Legal") {
                    Button {
                        showingLegalDisclaimer = true
                    } label: {
                        Label("Legal Disclaimer", systemImage: "doc.text")
                    }
                }

                // App Info Section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(AppConfig.appVersion)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Rules Edition")
                        Spacer()
                        Text(AppConfig.RULES_EDITION)
                            .foregroundStyle(.secondary)
                    }
                }

                // Developer Section
                Section("Developer") {
                    HStack {
                        Text("Container ID")
                        Spacer()
                        Text(AppConfig.containerIdentifier)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    HStack {
                        Text("Deck Copy Rule")
                        Spacer()
                        Text(AppConfig.DECK_COPY_RULE_STRICT ? "Strict" : "Per Section")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Signature Includes Side")
                        Spacer()
                        Text(AppConfig.SIGNATURE_INCLUDES_SIDEBOARD ? "Yes" : "No")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Clear Cache", isPresented: $showingClearCacheAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    clearCache()
                }
            } message: {
                Text("This will delete all locally cached cards and decks. They will be re-downloaded from iCloud when needed.")
            }
            .sheet(isPresented: $showingLegalDisclaimer) {
                LegalDisclaimerView()
            }
        }
    }

    private func clearCache() {
        // Clear SwiftData cache
        let cardDescriptor = FetchDescriptor<CachedCard>()
        let deckDescriptor = FetchDescriptor<CachedDeck>()
        let itemDescriptor = FetchDescriptor<CachedDeckItem>()

        do {
            let cards = try modelContext.fetch(cardDescriptor)
            cards.forEach { modelContext.delete($0) }

            let decks = try modelContext.fetch(deckDescriptor)
            decks.forEach { modelContext.delete($0) }

            let items = try modelContext.fetch(itemDescriptor)
            items.forEach { modelContext.delete($0) }

            try modelContext.save()
        } catch {
            print("Failed to clear cache: \(error)")
        }
    }
}

// MARK: - Legal Disclaimer View

struct LegalDisclaimerView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Legal Disclaimer")
                        .font(.title.bold())

                    Text(legalText)
                        .font(.body)

                    Spacer()
                }
                .padding()
            }
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

    private let legalText = """
    Riftbound is not affiliated with, endorsed, sponsored, or specifically approved by Riot Games.

    This app is an unofficial companion tool for the Riftbound trading card game. All game content, card names, artwork, and game rules are the property of Riot Games.

    By using this app, you agree to comply with Riot Games' Terms of Service and Legal Jibber Jabber.

    This app stores your deck data in your personal iCloud account. We do not collect, store, or share your personal information.

    THE APP IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED.
    """
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
        .modelContainer(for: [CachedCard.self, CachedDeck.self])
}
