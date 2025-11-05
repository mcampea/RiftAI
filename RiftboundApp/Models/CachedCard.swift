import Foundation
import SwiftData

@Model
final class CachedCard {
    @Attribute(.unique) var id: String
    var number: String
    var name: String
    var type: String
    var domains: [String]
    var energyCost: Int?
    var powerCostJSON: String?
    var might: Int?
    var keywords: [String]
    var tags: [String]
    var rulesText: String
    var isSignature: Bool
    var championTag: String?
    var isBattlefield: Bool
    var isRune: Bool
    var setCode: String
    var rarity: String?
    var lastSynced: Date

    init(from card: RBCard) {
        self.id = card.id
        self.number = card.number
        self.name = card.name
        self.type = card.type
        self.domains = card.domains
        self.energyCost = card.energyCost
        self.powerCostJSON = card.powerCostJSON
        self.might = card.might
        self.keywords = card.keywords
        self.tags = card.tags
        self.rulesText = card.rulesText
        self.isSignature = card.isSignature
        self.championTag = card.championTag
        self.isBattlefield = card.isBattlefield
        self.isRune = card.isRune
        self.setCode = card.setCode
        self.rarity = card.rarity
        self.lastSynced = Date()
    }

    func toRBCard() -> RBCard {
        RBCard(
            id: id,
            number: number,
            name: name,
            type: type,
            domains: domains,
            energyCost: energyCost,
            powerCostJSON: powerCostJSON,
            might: might,
            keywords: keywords,
            tags: tags,
            rulesText: rulesText,
            isSignature: isSignature,
            championTag: championTag,
            isBattlefield: isBattlefield,
            isRune: isRune,
            setCode: setCode,
            rarity: rarity
        )
    }
}

extension RBCard {
    init(id: String, number: String, name: String, type: String, domains: [String],
         energyCost: Int?, powerCostJSON: String?, might: Int?, keywords: [String],
         tags: [String], rulesText: String, isSignature: Bool, championTag: String?,
         isBattlefield: Bool, isRune: Bool, setCode: String, rarity: String?) {
        self.id = id
        self.number = number
        self.name = name
        self.type = type
        self.domains = domains
        self.energyCost = energyCost
        self.powerCostJSON = powerCostJSON
        self.might = might
        self.keywords = keywords
        self.tags = tags
        self.rulesText = rulesText
        self.isSignature = isSignature
        self.championTag = championTag
        self.isBattlefield = isBattlefield
        self.isRune = isRune
        self.setCode = setCode
        self.rarity = rarity
    }
}
