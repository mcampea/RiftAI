# Riftbound SwiftUI App

A comprehensive iOS/iPadOS app for the Riftbound trading card game. Build decks, browse cards, share with the community, and get AI-powered coaching.

## Features

### Core Features (v1)
- **Card Browser**: Filter and search cards by domain, type, cost, keywords, and more
- **Deck Builder**: Build decks with Main (≥40), Sideboard, and Rune (12) sections
- **Legality Validation**: Real-time deck validation with detailed error reporting
- **My Decks**: Create, edit, and manage your deck collection
- **Public Decks**: Share decks publicly and upvote community creations
- **AI Assistant**: Get coaching and rules guidance (Coach/Judge modes)
- **Settings**: Manage cache, view legal info, and app configuration

### Technical Stack
- **iOS 17+** with SwiftUI and Swift Concurrency
- **CloudKit** for data storage (Public + Private databases)
- **SwiftData** for offline caching
- **Sign in with Apple** for user authentication
- **URLSession** for AI API calls

## Project Structure

```
RiftboundApp/
├── RiftboundApp.swift          # Main app entry point
├── AppState.swift              # Global app state management
├── Info.plist                  # App configuration
├── RiftboundApp.entitlements   # CloudKit & SIWA entitlements
├── Models/                     # Data models
│   ├── RBCard.swift           # Card model
│   ├── RBUser.swift           # User profile model
│   ├── RBDeck.swift           # Deck model
│   ├── RBDeckItem.swift       # Deck item (card entry)
│   ├── RBVote.swift           # Upvote model
│   ├── CachedCard.swift       # SwiftData cache model
│   ├── CachedDeck.swift       # SwiftData deck cache
│   └── CachedDeckItem.swift   # SwiftData item cache
├── Views/                      # SwiftUI views
│   ├── ContentView.swift      # Main tab navigation
│   ├── CardBrowserView.swift  # Card browser & search
│   ├── CardFiltersView.swift  # Filter sheet
│   ├── MyDecksView.swift      # User's deck list
│   ├── DeckDetailView.swift   # Deck editor
│   ├── DeckLegalityView.swift # Legality checker
│   ├── DeckExportView.swift   # Export/share
│   ├── AddCardsToDeckView.swift # Card picker
│   ├── PublicDecksView.swift  # Public deck feed
│   ├── AIAssistantView.swift  # AI chat interface
│   └── SettingsView.swift     # Settings & profile
├── ViewModels/                 # View models
│   ├── CardBrowserViewModel.swift
│   ├── MyDecksViewModel.swift
│   ├── DeckDetailViewModel.swift
│   ├── PublicDecksViewModel.swift
│   └── AIAssistantViewModel.swift
├── Services/                   # Business logic
│   ├── CloudKitService.swift  # CloudKit wrapper
│   ├── CloudKitError.swift    # Error handling
│   ├── AuthService.swift      # Authentication
│   └── AIAPIService.swift     # AI API client
└── Utilities/                  # Helpers
    ├── AppConfig.swift        # Configuration constants
    ├── DeckValidator.swift    # Legality validation
    └── DeckExporter.swift     # Import/export JSON
```

## Setup Instructions

### 1. Xcode Project Setup

1. Open Xcode 15+ and create a new iOS App project
2. Set **Bundle Identifier**: `com.riftbound.app` (or your own)
3. Set **Team**: Your Apple Developer Team
4. Set **Minimum Deployment**: iOS 17.0

### 2. Add Source Files

1. Copy all files from `RiftboundApp/` into your Xcode project
2. Ensure all `.swift` files are added to the target
3. Add `Info.plist` and `RiftboundApp.entitlements` to the project root

### 3. Configure Entitlements

1. In Xcode, go to **Signing & Capabilities**
2. Add **iCloud** capability:
   - Enable **CloudKit**
   - Set container: `iCloud.com.riftbound.app` (or your identifier)
3. Add **Sign in with Apple** capability

### 4. CloudKit Setup

#### Create CloudKit Container

1. Go to [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard)
2. Select your container (`iCloud.com.riftbound.app`)
3. Create the following **Record Types** in the **Schema** section:

##### RBUser (Public Database)
- `displayName`: String (Queryable, Sortable)
- `siwaSubHash`: String
- `avatarAsset`: Asset
- `createdAt`: Date/Time (Queryable, Sortable)

##### RBCard (Public Database)
- `number`: String (Queryable, Sortable)
- `name`: String (Queryable, Sortable)
- `type`: String (Queryable, Sortable)
- `domains`: List<String> (Queryable)
- `energyCost`: Int64 (Queryable, Sortable)
- `powerCostJSON`: String
- `might`: Int64 (Queryable, Sortable)
- `keywords`: List<String> (Queryable)
- `tags`: List<String> (Queryable)
- `rulesText`: String (Queryable)
- `isSignature`: Int64 (Queryable)
- `championTag`: String (Queryable)
- `isBattlefield`: Int64 (Queryable)
- `isRune`: Int64 (Queryable)
- `setCode`: String (Queryable, Sortable)
- `rarity`: String (Queryable)

##### RBDeck (Public & Private Databases)
- `ownerUserRef`: Reference (to RBUser)
- `title`: String (Queryable, Sortable)
- `description`: String
- `legendChampionTag`: String (Queryable)
- `legendDomains`: List<String>
- `isPublic`: Int64 (Queryable, Sortable)
- `countMain`: Int64
- `countSide`: Int64
- `countRunes`: Int64
- `createdAt`: Date/Time (Queryable, Sortable)
- `updatedAt`: Date/Time (Queryable, Sortable)

##### RBDeckItem (Same database as parent deck)
- `deckRef`: Reference (to RBDeck, Delete Self)
- `cardRef`: Reference (to RBCard)
- `section`: String (Queryable)
- `qty`: Int64

##### RBVote (Public Database)
- `deckRef`: Reference (to RBDeck)
- `voterUserRef`: Reference (to RBUser)
- `createdAt`: Date/Time (Sortable)

#### Set Indexes

In CloudKit Dashboard > Indexes:
- `RBDeck.isPublic` + `RBDeck.updatedAt`
- `RBVote.deckRef`
- `RBCard.domains`
- `RBCard.type`
- `RBCard.isRune`

#### Configure Permissions

Public Database:
- **World**: Read
- **Authenticated**: Create (for RBDeck, RBVote)

Private Database:
- **Owner**: Read, Write

### 5. AI Backend Setup

The app expects an AI API endpoint at:
```
POST {AI_API_BASE_URL}/ai/ask
```

Request format:
```json
{
  "mode": "coach" | "judge",
  "question": "string",
  "deckId": "deck_<uuid>",
  "deckSnapshot": { "legend": {...}, "main": [...], "side": [...], "runes": [...] },
  "selection": ["card_id"],
  "rulesEdition": "1.1-100125"
}
```

Response format:
```json
{
  "answerMarkdown": "string",
  "citations": [{"type": "rule|card", "ref": "103.2", "id": "card_id"}]
}
```

Update `AppConfig.swift` or `Info.plist` with your API base URL.

### 6. Build Configuration

Edit `RiftboundApp/Utilities/AppConfig.swift` to configure:
- `DECK_MINIMUM_MAIN` (default: 40)
- `DECK_COPY_LIMIT` (default: 3)
- `SIGNATURE_CAP` (default: 3)
- `RUNE_DECK_SIZE` (default: 12)
- `AI_API_BASE_URL`

## Deck Building Rules

The app enforces these legality rules (configurable):

1. **Main Deck**: ≥ 40 cards
2. **Copy Limit**: ≤ 3 copies per card name (per section by default)
3. **Domain Identity**: All non-rune cards must have domains ⊆ legend domains
4. **Signature Cap**: ≤ 3 Signature cards matching legend's champion tag (Main only by default)
5. **Rune Deck**: Exactly 12 runes matching legend's domains
6. **Battlefield**: Multiple allowed (informational: choose 1 in game)
7. **Sideboard**: No size limit in v1 (configurable for future)

## Data Flow

### Deck Creation Flow
1. User creates deck in **My Decks** (Private DB)
2. Deck is stored in CloudKit Private Database
3. User can toggle "Public" to share
4. Public toggle moves deck + items to Public Database
5. Other users can view, upvote, and import

### Upvote Flow
1. User taps upvote on public deck
2. App attempts to create `RBVote` record with stable `recordName`
3. If record exists, treat as "already voted"
4. Upvote counts fetched via query + count

### Card Caching
1. On first launch, app fetches all `RBCard` from Public DB
2. Cards cached in SwiftData with `lastSynced` timestamp
3. Pull-to-refresh updates cache (24-hour staleness check)

## Testing

### Required Test Accounts
1. **iCloud Account**: Sign in to iCloud on simulator/device
2. **Apple Developer Account**: For Sign in with Apple (Sandbox)

### Testing Checklist
- [ ] iCloud sign-in prompt on first launch
- [ ] Username creation with SIWA
- [ ] Card browser loads and filters work
- [ ] Create deck with Main/Sideboard/Rune sections
- [ ] Legality validator shows correct errors
- [ ] Publish deck to Public feed
- [ ] Upvote/unvote public decks
- [ ] Import deck from JSON
- [ ] AI chat sends requests (requires backend)
- [ ] Offline mode with cached cards

## Known Limitations (v1)

- No on-device vector embeddings (AI backend handles retrieval)
- Sideboard max size not enforced (config flag exists)
- QR code export not implemented (JSON + clipboard only)
- No deck sharing via CKShare (reserved for v2)
- AI requires backend implementation
- No card images (text-only in v1)

## Next Steps

### Milestone 1: Data Import
Create a script or admin tool to populate CloudKit Public DB with card data.

### Milestone 2: Backend AI
Implement the `/ai/ask` endpoint with retrieval-augmented generation.

### Milestone 3: Polish
- Add card images (stored as CKAsset in RBCard)
- QR code deck sharing
- Enhanced iPad layout with NavigationSplitView
- Deck statistics and insights

## License

See LICENSE file for details. This is an unofficial fan project not affiliated with Riot Games.

## Contributing

This is a specification-driven build. To contribute:
1. Follow the existing code structure
2. Maintain compatibility with CloudKit schema
3. Add tests for new validators
4. Update this README with new features

---

**Built with SwiftUI, CloudKit, and passion for Riftbound.**
