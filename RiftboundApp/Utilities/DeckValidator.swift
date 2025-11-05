import Foundation

struct DeckValidator {
    // MARK: - Validation Result

    struct ValidationResult {
        var isValid: Bool
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []

        static var valid: ValidationResult {
            ValidationResult(isValid: true)
        }
    }

    enum ValidationError: Identifiable {
        case mainDeckTooSmall(current: Int, minimum: Int)
        case tooManyCopies(cardName: String, section: String, count: Int, limit: Int)
        case domainMismatch(cardName: String, cardDomains: [String], legendDomains: [String])
        case tooManySignatures(count: Int, limit: Int)
        case runeDeckWrongSize(current: Int, required: Int)
        case runeDomainMismatch(cardName: String, cardDomains: [String], legendDomains: [String])

        var id: String {
            switch self {
            case .mainDeckTooSmall: return "main_deck_size"
            case .tooManyCopies(let name, let section, _, _): return "copies_\(name)_\(section)"
            case .domainMismatch(let name, _, _): return "domain_\(name)"
            case .tooManySignatures: return "signature_count"
            case .runeDeckWrongSize: return "rune_deck_size"
            case .runeDomainMismatch(let name, _, _): return "rune_domain_\(name)"
            }
        }

        var description: String {
            switch self {
            case .mainDeckTooSmall(let current, let minimum):
                return "Main deck has \(current) cards, but must have at least \(minimum)"
            case .tooManyCopies(let name, let section, let count, let limit):
                return "\(name) has \(count) copies in \(section), exceeding limit of \(limit)"
            case .domainMismatch(let name, let cardDomains, let legendDomains):
                return "\(name) has domains \(cardDomains.joined(separator: ", ")) which don't match legend domains \(legendDomains.joined(separator: ", "))"
            case .tooManySignatures(let count, let limit):
                return "Deck has \(count) Signature cards, exceeding limit of \(limit)"
            case .runeDeckWrongSize(let current, let required):
                return "Rune deck has \(current) runes, but must have exactly \(required)"
            case .runeDomainMismatch(let name, let cardDomains, let legendDomains):
                return "Rune \(name) has domains \(cardDomains.joined(separator: ", ")) which don't match legend domains \(legendDomains.joined(separator: ", "))"
            }
        }

        var rule: String {
            switch self {
            case .mainDeckTooSmall:
                return "Main deck must have at least \(AppConfig.DECK_MINIMUM_MAIN) cards"
            case .tooManyCopies:
                return "Maximum \(AppConfig.DECK_COPY_LIMIT) copies of any card per section"
            case .domainMismatch:
                return "All cards must match legend's domain identity"
            case .tooManySignatures:
                return "Maximum \(AppConfig.SIGNATURE_CAP) Signature cards matching legend's champion tag"
            case .runeDeckWrongSize:
                return "Rune deck must have exactly \(AppConfig.RUNE_DECK_SIZE) runes"
            case .runeDomainMismatch:
                return "All runes must match legend's domain identity"
            }
        }
    }

    enum ValidationWarning: Identifiable {
        case multipleBattlefields(count: Int)
        case sideboardNotEmpty(count: Int)

        var id: String {
            switch self {
            case .multipleBattlefields: return "multiple_battlefields"
            case .sideboardNotEmpty: return "sideboard_not_empty"
            }
        }

        var description: String {
            switch self {
            case .multipleBattlefields(let count):
                return "Deck has \(count) battlefields. You'll choose 1 at game start."
            case .sideboardNotEmpty(let count):
                return "Sideboard has \(count) cards (informational - not enforced in v1)"
            }
        }
    }

    // MARK: - Validation

    static func validate(
        mainCards: [DeckCard],
        sideCards: [DeckCard],
        runeCards: [DeckCard],
        legendChampionTag: String,
        legendDomains: [String]
    ) -> ValidationResult {
        var result = ValidationResult(isValid: true)

        // 1. Main deck size check
        let mainCount = mainCards.reduce(0) { $0 + $1.quantity }
        if mainCount < AppConfig.DECK_MINIMUM_MAIN {
            result.errors.append(.mainDeckTooSmall(current: mainCount, minimum: AppConfig.DECK_MINIMUM_MAIN))
            result.isValid = false
        }

        // 2. Copy limit check (per section)
        validateCopyLimits(cards: mainCards, section: "Main", result: &result)
        validateCopyLimits(cards: sideCards, section: "Sideboard", result: &result)
        validateCopyLimits(cards: runeCards, section: "Runes", result: &result)

        // 3. Domain identity check (non-rune cards)
        validateDomainIdentity(
            cards: mainCards,
            legendDomains: legendDomains,
            result: &result
        )
        validateDomainIdentity(
            cards: sideCards,
            legendDomains: legendDomains,
            result: &result
        )

        // 4. Signature cap check
        var signatureCount = 0
        for card in mainCards where card.card.isSignature && card.card.championTag == legendChampionTag {
            signatureCount += card.quantity
        }

        if !AppConfig.SIGNATURE_INCLUDES_SIDEBOARD {
            // Separate count for sideboard (informational)
            var sideSignatureCount = 0
            for card in sideCards where card.card.isSignature && card.card.championTag == legendChampionTag {
                sideSignatureCount += card.quantity
            }
            // In v1, we only enforce main deck signature cap
        } else {
            // Global signature count
            for card in sideCards where card.card.isSignature && card.card.championTag == legendChampionTag {
                signatureCount += card.quantity
            }
        }

        if signatureCount > AppConfig.SIGNATURE_CAP {
            result.errors.append(.tooManySignatures(count: signatureCount, limit: AppConfig.SIGNATURE_CAP))
            result.isValid = false
        }

        // 5. Rune deck validation
        let runeCount = runeCards.reduce(0) { $0 + $1.quantity }
        if runeCount != AppConfig.RUNE_DECK_SIZE {
            result.errors.append(.runeDeckWrongSize(current: runeCount, required: AppConfig.RUNE_DECK_SIZE))
            result.isValid = false
        }

        // Rune domain check
        for deckCard in runeCards {
            if !deckCard.card.isRune {
                continue
            }

            let cardDomains = Set(deckCard.card.domains)
            let legendDomainsSet = Set(legendDomains)

            if !cardDomains.isSubset(of: legendDomainsSet) {
                result.errors.append(.runeDomainMismatch(
                    cardName: deckCard.card.name,
                    cardDomains: deckCard.card.domains,
                    legendDomains: legendDomains
                ))
                result.isValid = false
            }
        }

        // 6. Warnings
        let battlefieldCount = mainCards.filter { $0.card.isBattlefield }.reduce(0) { $0 + $1.quantity }
        if battlefieldCount > 1 {
            result.warnings.append(.multipleBattlefields(count: battlefieldCount))
        }

        let sideCount = sideCards.reduce(0) { $0 + $1.quantity }
        if sideCount > 0, let maxSide = AppConfig.SIDEBOARD_MAX, sideCount > maxSide {
            // Future: enforce sideboard max
        }

        return result
    }

    // MARK: - Helper Validators

    private static func validateCopyLimits(
        cards: [DeckCard],
        section: String,
        result: inout ValidationResult
    ) {
        let cardCounts = Dictionary(grouping: cards, by: { $0.card.name })
            .mapValues { $0.reduce(0) { $0 + $1.quantity } }

        for (cardName, count) in cardCounts {
            if count > AppConfig.DECK_COPY_LIMIT {
                result.errors.append(.tooManyCopies(
                    cardName: cardName,
                    section: section,
                    count: count,
                    limit: AppConfig.DECK_COPY_LIMIT
                ))
                result.isValid = false
            }
        }
    }

    private static func validateDomainIdentity(
        cards: [DeckCard],
        legendDomains: [String],
        result: inout ValidationResult
    ) {
        let legendDomainsSet = Set(legendDomains)

        for deckCard in cards {
            // Skip runes for domain identity check
            if deckCard.card.isRune {
                continue
            }

            let cardDomains = Set(deckCard.card.domains)

            // Card domains must be subset of legend domains
            if !cardDomains.isSubset(of: legendDomainsSet) {
                result.errors.append(.domainMismatch(
                    cardName: deckCard.card.name,
                    cardDomains: deckCard.card.domains,
                    legendDomains: legendDomains
                ))
                result.isValid = false
            }
        }
    }
}

// MARK: - Supporting Types

struct DeckCard: Identifiable {
    let id: String
    let card: RBCard
    var quantity: Int

    init(card: RBCard, quantity: Int) {
        self.id = card.id
        self.card = card
        self.quantity = quantity
    }
}
