import Foundation

struct DeckExporter {
    // MARK: - Export Format

    struct ExportedDeck: Codable {
        struct Legend: Codable {
            let championTag: String
            let domains: [String]
        }

        let legend: Legend
        let main: [[String]] // [["CARD_ID", qty], ...]
        let side: [[String]]
        let runes: [[String]]
        let title: String?
        let description: String?

        enum CodingKeys: String, CodingKey {
            case legend, main, side, runes, title, description
        }
    }

    // MARK: - Export

    static func exportToJSON(
        deck: RBDeck,
        items: [RBDeckItem]
    ) throws -> String {
        let mainItems = items.filter { $0.section == "main" }
            .map { [$0.cardRef.recordID.recordName, String($0.qty)] }

        let sideItems = items.filter { $0.section == "side" }
            .map { [$0.cardRef.recordID.recordName, String($0.qty)] }

        let runeItems = items.filter { $0.section == "rune" }
            .map { [$0.cardRef.recordID.recordName, String($0.qty)] }

        let exported = ExportedDeck(
            legend: ExportedDeck.Legend(
                championTag: deck.legendChampionTag,
                domains: deck.legendDomains
            ),
            main: mainItems,
            side: sideItems,
            runes: runeItems,
            title: deck.title,
            description: deck.description
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(exported)

        guard let json = String(data: data, encoding: .utf8) else {
            throw ExportError.encodingFailed
        }

        return json
    }

    // MARK: - Import

    static func importFromJSON(
        _ json: String,
        ownerUserID: String
    ) throws -> (deck: RBDeck, items: [RBDeckItem]) {
        guard let data = json.data(using: .utf8) else {
            throw ExportError.invalidJSON
        }

        let decoder = JSONDecoder()
        let exported = try decoder.decode(ExportedDeck.self, from: data)

        // Create deck
        var deck = RBDeck(
            ownerUserID: ownerUserID,
            title: exported.title ?? "Imported Deck",
            description: exported.description,
            legendChampionTag: exported.legend.championTag,
            legendDomains: exported.legend.domains,
            isPublic: false
        )

        // Create items
        var items: [RBDeckItem] = []

        for entry in exported.main {
            guard entry.count == 2,
                  let qty = Int(entry[1]) else {
                throw ExportError.invalidItemFormat
            }
            let item = RBDeckItem(
                deckID: deck.id,
                cardID: entry[0],
                section: .main,
                qty: qty
            )
            items.append(item)
        }

        for entry in exported.side {
            guard entry.count == 2,
                  let qty = Int(entry[1]) else {
                throw ExportError.invalidItemFormat
            }
            let item = RBDeckItem(
                deckID: deck.id,
                cardID: entry[0],
                section: .side,
                qty: qty
            )
            items.append(item)
        }

        for entry in exported.runes {
            guard entry.count == 2,
                  let qty = Int(entry[1]) else {
                throw ExportError.invalidItemFormat
            }
            let item = RBDeckItem(
                deckID: deck.id,
                cardID: entry[0],
                section: .rune,
                qty: qty
            )
            items.append(item)
        }

        // Update counts
        deck.countMain = items.filter { $0.section == "main" }.reduce(0) { $0 + $1.qty }
        deck.countSide = items.filter { $0.section == "side" }.reduce(0) { $0 + $1.qty }
        deck.countRunes = items.filter { $0.section == "rune" }.reduce(0) { $0 + $1.qty }

        return (deck, items)
    }
}

enum ExportError: LocalizedError {
    case encodingFailed
    case invalidJSON
    case invalidItemFormat

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode deck to JSON"
        case .invalidJSON:
            return "Invalid JSON format"
        case .invalidItemFormat:
            return "Invalid item format in imported deck"
        }
    }
}
