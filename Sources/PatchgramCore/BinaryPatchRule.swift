import Foundation
import CryptoKit

public enum BinaryPatchRuleKind: String, Codable, Sendable {
    case forceSerializedBool
    case poisonConstructor
    case unlockLimit
    case overrideDisplayedValue
    case overrideResponseValue
    case localPremium
    case visualBadge
    case botVerification
    case customLevelRating
    case hideSelfPhone
    case selfIdentityOverride
    case localPersonalChannel
    case fragmentPhone
    case customListUsernames
    case starGiftSpoof
    case showHiddenGifts
    case runtimeMemory
}

public enum BinaryReplacementMode: String, Codable, Sendable {
    case toggle
    case normalize
}

public struct BinaryPatchParameterChoice: Hashable, Sendable {
    public let value: UInt64
    public let label: String

    public init(value: UInt64, label: String) {
        self.value = value
        self.label = label
    }
}

public struct BinaryPatchParameterChoiceGroup: Hashable, Sendable {
    public let title: String
    public let choices: [BinaryPatchParameterChoice]

    public init(title: String, choices: [BinaryPatchParameterChoice]) {
        self.title = title
        self.choices = choices
    }
}

public enum BotVerificationTargetMode: String, CaseIterable, Codable, Hashable, Sendable {
    case all
    case allExceptSelf
    case onlySelf

    public var label: String {
        switch self {
        case .all:
            return "All"
        case .allExceptSelf:
            return "All except me"
        case .onlySelf:
            return "Only me"
        }
    }
}

public enum BotVerificationPreset: String, CaseIterable, Codable, Hashable, Sendable {
    case scaredCat
    case custom

    public var label: String {
        switch self {
        case .scaredCat:
            return "Scared Cat"
        case .custom:
            return "Custom"
        }
    }
}

public struct BotVerificationPatchConfig: Codable, Hashable, Sendable {
    public static let scaredCatEmojiId: UInt64 = 5_222_202_915_040_555_254
    public static let scaredCatDescription = "Meow"

    public static let defaultConfig = BotVerificationPatchConfig(
        targetMode: .all,
        preset: .scaredCat,
        customEmojiId: scaredCatEmojiId,
        description: scaredCatDescription,
        presetTitle: nil
    )

    public let targetMode: BotVerificationTargetMode
    public let preset: BotVerificationPreset
    public let customEmojiId: UInt64
    public let description: String
    public let presetTitle: String?

    public init(
        targetMode: BotVerificationTargetMode,
        preset: BotVerificationPreset,
        customEmojiId: UInt64,
        description: String,
        presetTitle: String? = nil
    ) {
        self.targetMode = targetMode
        self.preset = preset
        self.customEmojiId = customEmojiId
        self.description = description
        self.presetTitle = presetTitle
    }

    public var displayValue: String {
        "\(targetMode.label) - \(displayPresetLabel)"
    }

    public var displayPresetLabel: String {
        switch preset {
        case .scaredCat:
            return BotVerificationPreset.scaredCat.label
        case .custom:
            let title = presetTitle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return title.isEmpty ? BotVerificationPreset.custom.label : title
        }
    }

    public var normalized: BotVerificationPatchConfig {
        switch preset {
        case .scaredCat:
            return BotVerificationPatchConfig(
                targetMode: targetMode,
                preset: preset,
                customEmojiId: Self.scaredCatEmojiId,
                description: Self.scaredCatDescription,
                presetTitle: nil
            )
        case .custom:
            let title = presetTitle?.trimmingCharacters(in: .whitespacesAndNewlines)
            return BotVerificationPatchConfig(
                targetMode: targetMode,
                preset: preset,
                customEmojiId: customEmojiId,
                description: description,
                presetTitle: title?.isEmpty == true ? nil : title
            )
        }
    }
}

public struct CustomLevelRatingPatchConfig: Codable, Hashable, Sendable {
    public static let defaultConfig = CustomLevelRatingPatchConfig(
        targetMode: .all,
        level: 1,
        rating: 1_000,
        currentLevelRating: 0,
        nextLevelRating: 2_000
    )

    public let targetMode: BotVerificationTargetMode
    public let level: Int32
    public let rating: Int32
    public let currentLevelRating: Int32
    public let nextLevelRating: Int32

    public init(
        targetMode: BotVerificationTargetMode,
        level: Int32,
        rating: Int32,
        currentLevelRating: Int32,
        nextLevelRating: Int32
    ) {
        self.targetMode = targetMode
        self.level = level
        self.rating = rating
        self.currentLevelRating = currentLevelRating
        self.nextLevelRating = nextLevelRating
    }

    public var displayValue: String {
        "\(targetMode.label) - L\(level), rating \(rating)"
    }

    public var normalized: CustomLevelRatingPatchConfig {
        CustomLevelRatingPatchConfig(
            targetMode: targetMode,
            level: level,
            rating: max(0, rating),
            currentLevelRating: max(0, currentLevelRating),
            nextLevelRating: max(0, nextLevelRating)
        )
    }
}

public struct SelfIdentityPatchConfig: Codable, Hashable, Sendable {
    public static let defaultConfig = SelfIdentityPatchConfig(
        phone: "+10000000000",
        userId: "",
        phoneTargetMode: .onlySelf,
        userIdTargetMode: .onlySelf
    )

    public let phone: String
    public let userId: String
    public let phoneTargetMode: BotVerificationTargetMode
    public let userIdTargetMode: BotVerificationTargetMode

    public init(
        phone: String,
        userId: String,
        phoneTargetMode: BotVerificationTargetMode = .onlySelf,
        userIdTargetMode: BotVerificationTargetMode = .onlySelf
    ) {
        self.phone = phone
        self.userId = userId
        self.phoneTargetMode = phoneTargetMode
        self.userIdTargetMode = userIdTargetMode
    }

    private enum CodingKeys: String, CodingKey {
        case phone
        case userId
        case phoneTargetMode
        case userIdTargetMode
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        phone = try container.decodeIfPresent(String.self, forKey: .phone) ?? ""
        if let stringUserId = try? container.decode(String.self, forKey: .userId) {
            userId = stringUserId
        } else if let numericUserId = try? container.decode(UInt64.self, forKey: .userId) {
            userId = numericUserId == 0 ? "" : String(numericUserId)
        } else {
            userId = ""
        }
        phoneTargetMode = try container.decodeIfPresent(
            BotVerificationTargetMode.self,
            forKey: .phoneTargetMode
        ) ?? .onlySelf
        userIdTargetMode = try container.decodeIfPresent(
            BotVerificationTargetMode.self,
            forKey: .userIdTargetMode
        ) ?? .onlySelf
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(phone, forKey: .phone)
        try container.encode(userId, forKey: .userId)
        try container.encode(phoneTargetMode, forKey: .phoneTargetMode)
        try container.encode(userIdTargetMode, forKey: .userIdTargetMode)
    }

    public var displayValue: String {
        let phoneValue = normalized.phone.isEmpty ? "unchanged phone" : normalized.phone
        let userIdValue = normalized.userId.isEmpty ? "unchanged id" : "id \(normalized.userId)"
        return "\(phoneValue) (\(normalized.phoneTargetMode.label)), \(userIdValue) (\(normalized.userIdTargetMode.label))"
    }

    public var normalized: SelfIdentityPatchConfig {
        SelfIdentityPatchConfig(
            phone: phone.trimmingCharacters(in: .whitespacesAndNewlines),
            userId: userId.trimmingCharacters(in: .whitespacesAndNewlines),
            phoneTargetMode: phoneTargetMode,
            userIdTargetMode: userIdTargetMode
        )
    }
}

public struct LocalPersonalChannelPatchConfig: Codable, Hashable, Sendable {
    public static let defaultConfig = LocalPersonalChannelPatchConfig(
        channelReference: "",
        messageId: 0,
        targetMode: .onlySelf
    )

    public let channelReference: String
    public let messageId: Int32
    public let targetMode: BotVerificationTargetMode

    private enum CodingKeys: String, CodingKey {
        case channelReference
        case messageId
        case targetMode
    }

    public init(
        channelReference: String,
        messageId: Int32 = 0,
        targetMode: BotVerificationTargetMode = .onlySelf
    ) {
        self.channelReference = channelReference
        self.messageId = messageId
        self.targetMode = targetMode
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        channelReference = try container.decodeIfPresent(String.self, forKey: .channelReference) ?? ""
        messageId = try container.decodeIfPresent(Int32.self, forKey: .messageId) ?? 0
        targetMode = try container.decodeIfPresent(BotVerificationTargetMode.self, forKey: .targetMode) ?? .onlySelf
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(channelReference, forKey: .channelReference)
        try container.encode(messageId, forKey: .messageId)
        try container.encode(targetMode, forKey: .targetMode)
    }

    public var normalized: LocalPersonalChannelPatchConfig {
        LocalPersonalChannelPatchConfig(
            channelReference: channelReference.trimmingCharacters(in: .whitespacesAndNewlines),
            messageId: max(0, messageId),
            targetMode: targetMode
        )
    }

    public var channelId: UInt64? {
        let text = normalized.channelReference
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let lowered = text.lowercased()
        let candidate: String
        if lowered.contains("/c/") {
            let parts = text.split(separator: "/").map(String.init)
            if let cIndex = parts.firstIndex(where: { $0.lowercased() == "c" }),
               parts.indices.contains(cIndex + 1) {
                candidate = parts[cIndex + 1]
            } else {
                candidate = text
            }
        } else {
            candidate = text
        }
        let normalizedCandidate: String
        if candidate.hasPrefix("-100") {
            normalizedCandidate = String(candidate.dropFirst(4))
        } else if candidate.hasPrefix("100"), candidate.count > 10 {
            normalizedCandidate = String(candidate.dropFirst(3))
        } else {
            normalizedCandidate = candidate
        }
        guard let value = UInt64(normalizedCandidate), value > 0 else { return nil }
        return value
    }

    public var displayValue: String {
        let value = normalized.channelReference
        return value.isEmpty ? "unchanged channel" : "\(value) (\(normalized.targetMode.label))"
    }
}

public struct FragmentPhonePatchConfig: Codable, Hashable, Sendable {
    public static let defaultConfig = FragmentPhonePatchConfig(
        targetMode: .onlySelf,
        purchaseDateText: "0",
        currency: "USD",
        amount: 0,
        cryptoCurrency: "TON",
        cryptoAmount: 0,
        url: ""
    )

    public let targetMode: BotVerificationTargetMode
    public let purchaseDateText: String
    public let currency: String
    public let amount: Int64
    public let cryptoCurrency: String
    public let cryptoAmount: Int64
    public let url: String

    public init(
        targetMode: BotVerificationTargetMode = .onlySelf,
        purchaseDateText: String,
        currency: String,
        amount: Int64,
        cryptoCurrency: String,
        cryptoAmount: Int64,
        url: String
    ) {
        self.targetMode = targetMode
        self.purchaseDateText = purchaseDateText
        self.currency = currency
        self.amount = amount
        self.cryptoCurrency = cryptoCurrency
        self.cryptoAmount = cryptoAmount
        self.url = url
    }

    public var normalized: FragmentPhonePatchConfig {
        FragmentPhonePatchConfig(
            targetMode: targetMode,
            purchaseDateText: purchaseDateText.trimmingCharacters(in: .whitespacesAndNewlines),
            currency: currency.trimmingCharacters(in: .whitespacesAndNewlines),
            amount: max(0, amount),
            cryptoCurrency: cryptoCurrency.trimmingCharacters(in: .whitespacesAndNewlines),
            cryptoAmount: max(0, cryptoAmount),
            url: url.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    public var purchaseDateUnix: Int32? {
        let text = normalized.purchaseDateText
        if text.isEmpty {
            return 0
        }
        if let value = Int64(text), value >= 0, value <= Int64(Int32.max) {
            return Int32(value)
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "HH:mm:ss dd.MM.yyyy"
        guard let date = formatter.date(from: text) else { return nil }
        let timestamp = Int64(date.timeIntervalSince1970)
        guard timestamp >= 0, timestamp <= Int64(Int32.max) else { return nil }
        return Int32(timestamp)
    }

    public var displayValue: String {
        "\(normalized.targetMode.label) - \(normalized.cryptoAmount) \(normalized.cryptoCurrency), \(normalized.amount) \(normalized.currency)"
    }
}

/// Spoofs the star gifts shown on a profile by rewriting each savedStarGift in the
/// payments.savedStarGifts response. Each value is text so "0"/empty means "leave the original";
/// the dylib only overwrites fields with a non-zero configured value.
public struct StarGiftSpoofPatchConfig: Codable, Hashable, Sendable {
    public static let defaultConfig = StarGiftSpoofPatchConfig(
        targetMode: .onlySelf,
        senderIdText: "0",
        dateText: "0",
        giftIdText: "0",
        stickerEmojiIdText: "0",
        starsText: "0",
        caption: "",
        availableText: "0",
        totalText: "0",
        forceLimited: false,
        forceUpgrade: false,
        forceAuction: false,
        upgradePriceText: "0",
        auctionTitle: "",
        giftNumberText: "0",
        wasRefunded: false
    )

    public let targetMode: BotVerificationTargetMode
    public let senderIdText: String        // sender id; 0 = leave. Negative -100… = channel, -… = group, else user
    public let dateText: String            // "0" or "HH:mm:ss dd.MM.yyyy"; 0 = leave unchanged
    public let giftIdText: String          // gift id; 0 = leave unchanged
    public let stickerEmojiIdText: String  // custom emoji id for the sticker; 0 = leave unchanged
    public let starsText: String           // price in Stars; 0 = leave unchanged
    public let caption: String             // gift message/caption; empty = leave unchanged
    public let availableText: String       // availability_remains (supply left); 0 = leave unchanged
    public let totalText: String           // availability_total (total supply); 0 = leave unchanged
    public let forceLimited: Bool          // force the "limited" badge (adds availability if missing)
    public let forceUpgrade: Bool          // force "can upgrade" (can_upgrade + upgrade_stars)
    public let forceAuction: Bool          // force the "auction" badge
    public let upgradePriceText: String    // upgrade_stars price when forceUpgrade; 0 = default (25)
    public let auctionTitle: String        // starGift.title (auction gift name); empty = leave
    public let giftNumberText: String      // savedStarGift.gift_num (auction gift number); 0 = leave
    public let wasRefunded: Bool           // mark the gift refunded (savedStarGift.refunded)

    public init(
        targetMode: BotVerificationTargetMode = .onlySelf,
        senderIdText: String,
        dateText: String,
        giftIdText: String,
        stickerEmojiIdText: String = "0",
        starsText: String,
        caption: String = "",
        availableText: String = "0",
        totalText: String = "0",
        forceLimited: Bool = false,
        forceUpgrade: Bool = false,
        forceAuction: Bool = false,
        upgradePriceText: String = "0",
        auctionTitle: String = "",
        giftNumberText: String = "0",
        wasRefunded: Bool = false
    ) {
        self.targetMode = targetMode
        self.senderIdText = senderIdText
        self.dateText = dateText
        self.giftIdText = giftIdText
        self.stickerEmojiIdText = stickerEmojiIdText
        self.starsText = starsText
        self.caption = caption
        self.availableText = availableText
        self.totalText = totalText
        self.forceLimited = forceLimited
        self.forceUpgrade = forceUpgrade
        self.forceAuction = forceAuction
        self.upgradePriceText = upgradePriceText
        self.auctionTitle = auctionTitle
        self.giftNumberText = giftNumberText
        self.wasRefunded = wasRefunded
    }

    private enum CodingKeys: String, CodingKey {
        case targetMode, senderIdText, dateText, giftIdText, stickerEmojiIdText, starsText, caption
        case availableText, totalText, forceLimited, forceUpgrade, forceAuction, upgradePriceText
        case auctionTitle, giftNumberText, wasRefunded
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        targetMode = try c.decodeIfPresent(BotVerificationTargetMode.self, forKey: .targetMode) ?? .onlySelf
        senderIdText = try c.decodeIfPresent(String.self, forKey: .senderIdText) ?? "0"
        dateText = try c.decodeIfPresent(String.self, forKey: .dateText) ?? "0"
        giftIdText = try c.decodeIfPresent(String.self, forKey: .giftIdText) ?? "0"
        stickerEmojiIdText = try c.decodeIfPresent(String.self, forKey: .stickerEmojiIdText) ?? "0"
        starsText = try c.decodeIfPresent(String.self, forKey: .starsText) ?? "0"
        caption = try c.decodeIfPresent(String.self, forKey: .caption) ?? ""
        availableText = try c.decodeIfPresent(String.self, forKey: .availableText) ?? "0"
        totalText = try c.decodeIfPresent(String.self, forKey: .totalText) ?? "0"
        forceLimited = try c.decodeIfPresent(Bool.self, forKey: .forceLimited) ?? false
        forceUpgrade = try c.decodeIfPresent(Bool.self, forKey: .forceUpgrade) ?? false
        forceAuction = try c.decodeIfPresent(Bool.self, forKey: .forceAuction) ?? false
        upgradePriceText = try c.decodeIfPresent(String.self, forKey: .upgradePriceText) ?? "0"
        auctionTitle = try c.decodeIfPresent(String.self, forKey: .auctionTitle) ?? ""
        giftNumberText = try c.decodeIfPresent(String.self, forKey: .giftNumberText) ?? "0"
        wasRefunded = try c.decodeIfPresent(Bool.self, forKey: .wasRefunded) ?? false
    }

    public var normalized: StarGiftSpoofPatchConfig {
        StarGiftSpoofPatchConfig(
            targetMode: targetMode,
            senderIdText: senderIdText.trimmingCharacters(in: .whitespacesAndNewlines),
            dateText: dateText.trimmingCharacters(in: .whitespacesAndNewlines),
            giftIdText: giftIdText.trimmingCharacters(in: .whitespacesAndNewlines),
            stickerEmojiIdText: stickerEmojiIdText.trimmingCharacters(in: .whitespacesAndNewlines),
            starsText: starsText.trimmingCharacters(in: .whitespacesAndNewlines),
            caption: caption,
            availableText: availableText.trimmingCharacters(in: .whitespacesAndNewlines),
            totalText: totalText.trimmingCharacters(in: .whitespacesAndNewlines),
            forceLimited: forceLimited,
            forceUpgrade: forceUpgrade,
            forceAuction: forceAuction,
            upgradePriceText: upgradePriceText.trimmingCharacters(in: .whitespacesAndNewlines),
            auctionTitle: auctionTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            giftNumberText: giftNumberText.trimmingCharacters(in: .whitespacesAndNewlines),
            wasRefunded: wasRefunded
        )
    }

    private static func longValue(_ text: String) -> Int64 {
        Int64(text.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
    }

    /// Bot-API-style sender id (may be negative): positive = user, -100… = channel,
    /// other negative = basic group. 0 = leave the original sender.
    private var senderRaw: Int64 { Self.longValue(senderIdText) }
    public var senderPeerType: Int32 {   // 0 user, 1 channel, 2 chat
        let v = senderRaw
        if v >= 0 { return 0 }
        let s = senderIdText.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("-100"), Int64(s.dropFirst(4)) != nil { return 1 }
        return 2
    }
    public var senderId: Int64 {   // internal peer id (channel/chat id without the -100/- prefix)
        let v = senderRaw
        if v >= 0 { return v }
        let s = senderIdText.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("-100"), let id = Int64(s.dropFirst(4)) { return id }
        return -v
    }
    public var giftId: Int64 { max(0, Self.longValue(giftIdText)) }
    public var stickerEmojiId: Int64 { max(0, Self.longValue(stickerEmojiIdText)) }
    public var stars: Int64 { max(0, Self.longValue(starsText)) }
    public var available: Int32 { Int32(clamping: max(0, Self.longValue(availableText))) }
    public var total: Int32 { Int32(clamping: max(0, Self.longValue(totalText))) }
    public var upgradePrice: Int64 { max(0, Self.longValue(upgradePriceText)) }
    public var giftNumber: Int32 { Int32(clamping: max(0, Self.longValue(giftNumberText))) }

    /// nil → invalid (the prompt rejects it); 0 → leave the original date.
    public var dateUnix: Int32? {
        let text = normalized.dateText
        if text.isEmpty { return 0 }
        if let value = Int64(text), value >= 0, value <= Int64(Int32.max) {
            return Int32(value)
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "HH:mm:ss dd.MM.yyyy"
        guard let date = formatter.date(from: text) else { return nil }
        let timestamp = Int64(date.timeIntervalSince1970)
        guard timestamp >= 0, timestamp <= Int64(Int32.max) else { return nil }
        return Int32(timestamp)
    }

    public var displayValue: String {
        var parts: [String] = []
        if senderId != 0 {
            let kind = senderPeerType == 1 ? "channel " : senderPeerType == 2 ? "chat " : ""
            parts.append("from \(kind)\(senderId)")
        }
        if (dateUnix ?? 0) != 0 { parts.append("date \(dateUnix ?? 0)") }
        if giftId != 0 { parts.append("id \(giftId)") }
        if stickerEmojiId != 0 { parts.append("emoji \(stickerEmojiId)") }
        if stars != 0 { parts.append("\(stars)⭐") }
        if available != 0 || total != 0 { parts.append("supply \(available)/\(total)") }
        var badges: [String] = []
        if forceLimited { badges.append("limited") }
        if forceUpgrade { badges.append(upgradePrice > 0 ? "upgrade(\(upgradePrice)⭐)" : "upgrade") }
        if forceAuction {
            let titleTrim = auctionTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            var a = "auction"
            if !titleTrim.isEmpty { a += " “\(titleTrim.prefix(12))”" }
            if giftNumber != 0 { a += " #\(giftNumber)" }
            badges.append(a)
        }
        if wasRefunded { badges.append("refunded") }
        if !badges.isEmpty { parts.append(badges.joined(separator: "+")) }
        let trimmedCaption = caption.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedCaption.isEmpty { parts.append("“\(trimmedCaption.prefix(16))”") }
        let summary = parts.isEmpty ? "no overrides" : parts.joined(separator: ", ")
        return "\(normalized.targetMode.label) - \(summary)"
    }
}

public struct UsernameCollectibleInfoPatchConfig: Codable, Hashable, Sendable {
    public static let defaultConfig = UsernameCollectibleInfoPatchConfig(
        purchaseDateText: "0",
        currency: "USD",
        amount: 0,
        cryptoCurrency: "TON",
        cryptoAmount: 0,
        url: ""
    )

    public let purchaseDateText: String
    public let currency: String
    public let amount: Int64
    public let cryptoCurrency: String
    public let cryptoAmount: Int64
    public let url: String

    public init(
        purchaseDateText: String,
        currency: String,
        amount: Int64,
        cryptoCurrency: String,
        cryptoAmount: Int64,
        url: String
    ) {
        self.purchaseDateText = purchaseDateText
        self.currency = currency
        self.amount = amount
        self.cryptoCurrency = cryptoCurrency
        self.cryptoAmount = cryptoAmount
        self.url = url
    }

    public var normalized: UsernameCollectibleInfoPatchConfig {
        UsernameCollectibleInfoPatchConfig(
            purchaseDateText: purchaseDateText.trimmingCharacters(in: .whitespacesAndNewlines),
            currency: currency.trimmingCharacters(in: .whitespacesAndNewlines),
            amount: max(0, amount),
            cryptoCurrency: cryptoCurrency.trimmingCharacters(in: .whitespacesAndNewlines),
            cryptoAmount: max(0, cryptoAmount),
            url: url.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    public var purchaseDateUnix: Int32? {
        let text = normalized.purchaseDateText
        if text.isEmpty {
            return 0
        }
        if let value = Int64(text), value >= 0, value <= Int64(Int32.max) {
            return Int32(value)
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "HH:mm:ss dd.MM.yyyy"
        guard let date = formatter.date(from: text) else { return nil }
        let timestamp = Int64(date.timeIntervalSince1970)
        guard timestamp >= 0, timestamp <= Int64(Int32.max) else { return nil }
        return Int32(timestamp)
    }

    public var payloadFields: [String] {
        [
            String(purchaseDateUnix ?? 0),
            Self.payloadSafe(normalized.currency),
            String(normalized.amount),
            Self.payloadSafe(normalized.cryptoCurrency),
            String(normalized.cryptoAmount),
            Self.payloadSafe(normalized.url)
        ]
    }

    private static func payloadSafe(_ value: String) -> String {
        value.replacingOccurrences(of: "|", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
    }
}

public enum CustomUsernameStatus: String, CaseIterable, Codable, Hashable, Sendable {
    case `default`
    case collectible

    public var label: String {
        switch self {
        case .default:
            return "Default"
        case .collectible:
            return "Collectible"
        }
    }
}

public struct CustomUsernameEntryPatchConfig: Identifiable, Codable, Hashable, Sendable {
    public static let maxUsernameLength = 32

    public let id: UUID
    public let username: String
    public let status: CustomUsernameStatus
    public let isPrimary: Bool
    public let collectibleInfo: UsernameCollectibleInfoPatchConfig

    public init(
        id: UUID = UUID(),
        username: String,
        status: CustomUsernameStatus,
        isPrimary: Bool = false,
        collectibleInfo: UsernameCollectibleInfoPatchConfig = .defaultConfig
    ) {
        self.id = id
        self.username = username
        self.status = status
        self.isPrimary = isPrimary
        self.collectibleInfo = collectibleInfo
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case username
        case status
        case isPrimary
        case collectibleInfo
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        username = try container.decode(String.self, forKey: .username)
        status = try container.decodeIfPresent(CustomUsernameStatus.self, forKey: .status) ?? .default
        isPrimary = try container.decodeIfPresent(Bool.self, forKey: .isPrimary) ?? false
        collectibleInfo = try container.decodeIfPresent(
            UsernameCollectibleInfoPatchConfig.self,
            forKey: .collectibleInfo
        ) ?? .defaultConfig
    }

    public var normalized: CustomUsernameEntryPatchConfig? {
        let cleaned = Self.normalizedUsername(username)
        guard Self.isValidUsername(cleaned) else { return nil }
        return CustomUsernameEntryPatchConfig(
            id: id,
            username: cleaned,
            status: status,
            isPrimary: isPrimary,
            collectibleInfo: collectibleInfo.normalized
        )
    }

    public static func normalizedUsername(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "@"))
    }

    public static func isValidUsername(_ value: String) -> Bool {
        guard !value.isEmpty, value.count <= maxUsernameLength else { return false }
        var allowed = CharacterSet.letters
        allowed.formUnion(.decimalDigits)
        allowed.insert(charactersIn: "_.-")
        return value.unicodeScalars.allSatisfy { scalar in
            allowed.contains(scalar)
        }
    }
}

public struct CustomListUsernamesPatchConfig: Codable, Hashable, Sendable {
    public static let defaultConfig = CustomListUsernamesPatchConfig(
        entries: [],
        useSharedCollectibleInfo: true,
        sharedCollectibleInfo: .defaultConfig
    )

    public let entries: [CustomUsernameEntryPatchConfig]
    public let useSharedCollectibleInfo: Bool
    public let sharedCollectibleInfo: UsernameCollectibleInfoPatchConfig

    public init(
        entries: [CustomUsernameEntryPatchConfig],
        useSharedCollectibleInfo: Bool = true,
        sharedCollectibleInfo: UsernameCollectibleInfoPatchConfig = .defaultConfig
    ) {
        self.entries = entries
        self.useSharedCollectibleInfo = useSharedCollectibleInfo
        self.sharedCollectibleInfo = sharedCollectibleInfo
    }

    public var normalized: CustomListUsernamesPatchConfig {
        let rawEntries = entries.compactMap { entry -> CustomUsernameEntryPatchConfig? in
            guard let normalized = entry.normalized else { return nil }
            let info = useSharedCollectibleInfo
                ? sharedCollectibleInfo.normalized
                : normalized.collectibleInfo.normalized
            return CustomUsernameEntryPatchConfig(
                id: normalized.id,
                username: normalized.username,
                status: normalized.status,
                isPrimary: normalized.isPrimary,
                collectibleInfo: info
            )
        }
        let primaryIndex = rawEntries.firstIndex(where: \.isPrimary) ?? rawEntries.indices.first
        let normalizedEntries = rawEntries.enumerated()
            .map { index, entry in
                CustomUsernameEntryPatchConfig(
                    id: entry.id,
                    username: entry.username,
                    status: entry.status,
                    isPrimary: index == primaryIndex,
                    collectibleInfo: entry.collectibleInfo
                )
            }
            .sorted { lhs, rhs in
                if lhs.isPrimary != rhs.isPrimary {
                    return lhs.isPrimary
                }
                guard let leftIndex = rawEntries.firstIndex(where: { $0.id == lhs.id }),
                      let rightIndex = rawEntries.firstIndex(where: { $0.id == rhs.id }) else {
                    return false
                }
                return leftIndex < rightIndex
            }
        return CustomListUsernamesPatchConfig(
            entries: normalizedEntries,
            useSharedCollectibleInfo: useSharedCollectibleInfo,
            sharedCollectibleInfo: sharedCollectibleInfo.normalized
        )
    }

    public var displayValue: String {
        let normalized = normalized
        let collectibleCount = normalized.entries.filter { $0.status == .collectible }.count
        let first = normalized.entries.first?.username ?? "none"
        return "\(normalized.entries.count) usernames, \(collectibleCount) collectible, first @\(first)"
    }

    public var runtimePayload: String {
        normalized.entries.map { entry in
            let info = entry.collectibleInfo.normalized
            return ([
                entry.username,
                entry.status == .collectible ? "1" : "0"
            ] + info.payloadFields).joined(separator: "|")
        }.joined(separator: "\n")
    }
}

public struct MessageFactCheckPatchConfig: Codable, Hashable, Sendable {
    public static let defaultConfig = MessageFactCheckPatchConfig(
        text: "Fact checked locally",
        country: "",
        hash: 0,
        needCheck: false
    )

    public let text: String
    public let country: String
    public let hash: Int64
    public let needCheck: Bool

    private enum CodingKeys: String, CodingKey {
        case text
        case country
        case hash
        case needCheck
    }

    public init(text: String, country: String = "", hash: Int64 = 0, needCheck: Bool = false) {
        self.text = text
        self.country = country
        self.hash = hash
        self.needCheck = needCheck
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = try container.decode(String.self, forKey: .text)
        country = try container.decodeIfPresent(String.self, forKey: .country) ?? ""
        hash = try container.decodeIfPresent(Int64.self, forKey: .hash) ?? 0
        needCheck = try container.decodeIfPresent(Bool.self, forKey: .needCheck) ?? false
    }

    public var normalized: MessageFactCheckPatchConfig {
        MessageFactCheckPatchConfig(
            text: text.trimmingCharacters(in: .whitespacesAndNewlines),
            country: country.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
            hash: hash,
            needCheck: needCheck
        )
    }

    public var displayValue: String {
        let value = normalized.text
        let countryValue = normalized.country.isEmpty ? "no country" : normalized.country
        return value.isEmpty
            ? "empty fact check"
            : "\(value) - \(countryValue), hash \(normalized.hash), need_check \(normalized.needCheck ? "on" : "off")"
    }
}

public struct BinaryPatchParameter: Hashable, Sendable {
    public let title: String
    public let prompt: String
    public let defaultValue: UInt64
    public let minimumValue: UInt64
    public let maximumValue: UInt64
    public let unit: String
    public let choices: [BinaryPatchParameterChoice]
    public let choiceGroups: [BinaryPatchParameterChoiceGroup]

    public init(
        title: String,
        prompt: String,
        defaultValue: UInt64,
        minimumValue: UInt64,
        maximumValue: UInt64,
        unit: String,
        choices: [BinaryPatchParameterChoice] = [],
        choiceGroups: [BinaryPatchParameterChoiceGroup] = []
    ) {
        self.title = title
        self.prompt = prompt
        self.defaultValue = defaultValue
        self.minimumValue = minimumValue
        self.maximumValue = maximumValue
        self.unit = unit
        self.choices = choices
        self.choiceGroups = choiceGroups
    }

    public func displayValue(_ value: UInt64) -> String {
        if let groupedChoices = groupedChoices(for: value) {
            return groupedChoices.map(\.label).joined(separator: " - ")
        }
        if let choice = choices.first(where: { $0.value == value }) {
            return choice.label
        }
        return "\(value) \(unit)"
    }

    public func groupedChoices(for value: UInt64) -> [BinaryPatchParameterChoice]? {
        guard !choiceGroups.isEmpty else { return nil }
        var selected: [BinaryPatchParameterChoice] = []

        func select(groupIndex: Int, remainingValue: UInt64) -> Bool {
            if groupIndex == choiceGroups.count {
                return remainingValue == 0
            }
            for choice in choiceGroups[groupIndex].choices where choice.value <= remainingValue {
                selected.append(choice)
                if select(groupIndex: groupIndex + 1, remainingValue: remainingValue - choice.value) {
                    return true
                }
                selected.removeLast()
            }
            return false
        }

        return select(groupIndex: 0, remainingValue: value) ? selected : nil
    }
}

public enum BinaryPatchTemplate: String, Codable, Hashable, Sendable {
    case creditsStarsAmount
    case creditsTonAmount

    func render(parameterValue: UInt64?) -> Data {
        switch self {
        case .creditsStarsAmount:
            let amount = min(parameterValue ?? 999, UInt64.max >> 2)
            return Self.renderCreditsAmountReturn(
                encodedAmount: amount << 2,
                byteCount: 72,
                zeroRegisterOne: .moveWide
            )

        case .creditsTonAmount:
            let amount = min(parameterValue ?? 999, UInt64.max >> 2)
            return Self.renderCreditsAmountReturn(
                encodedAmount: (amount << 2) | 1,
                byteCount: 128,
                zeroRegisterOne: .moveFromZeroRegister
            )
        }
    }

    private static let arm64Nop = Data(hexString: "1f2003d5")
    private static let arm64Return = Data(hexString: "fd7bc1a8c0035fd6")

    private enum RegisterZeroMode {
        case moveWide
        case moveFromZeroRegister
    }

    private static func renderCreditsAmountReturn(
        encodedAmount: UInt64,
        byteCount: Int,
        zeroRegisterOne: RegisterZeroMode
    ) -> Data {
        var bytes = Data()
        bytes.append(arm64MovWide(register: 0, value: encodedAmount, bits: 64))
        bytes.append(arm64MovKeep(register: 0, value: encodedAmount >> 16, shift: 16, bits: 64))
        bytes.append(arm64MovKeep(register: 0, value: encodedAmount >> 32, shift: 32, bits: 64))
        bytes.append(arm64MovKeep(register: 0, value: encodedAmount >> 48, shift: 48, bits: 64))
        switch zeroRegisterOne {
        case .moveWide:
            bytes.append(arm64MovWide(register: 1, value: 0, bits: 64))
        case .moveFromZeroRegister:
            bytes.append(Data(hexString: "e1031faa"))
        }
        bytes.append(arm64Return)
        while bytes.count < byteCount {
            bytes.append(arm64Nop)
        }
        precondition(bytes.count == byteCount, "Rendered ARM64 replacement must keep byte length unchanged.")
        return bytes
    }

    private static func arm64MovWide(register: UInt32, value: UInt64, bits: UInt32) -> Data {
        let base: UInt32 = bits == 64 ? 0xD2800000 : 0x52800000
        return instruction(base | (UInt32(value & 0xffff) << 5) | register)
    }

    private static func arm64MovKeep(register: UInt32, value: UInt64, shift: UInt32, bits: UInt32) -> Data {
        let base: UInt32 = bits == 64 ? 0xF2800000 : 0x72800000
        let halfword = (shift / 16) << 21
        return instruction(base | halfword | (UInt32(value & 0xffff) << 5) | register)
    }

    private static func instruction(_ value: UInt32) -> Data {
        var littleEndian = value.littleEndian
        return Data(bytes: &littleEndian, count: MemoryLayout<UInt32>.size)
    }
}

public struct BinaryReplacement: Hashable, Sendable {
    public let id: String
    public let alternativeGroup: String
    public let original: Data
    /// Optional match mask (same length as `original`): 0xFF = byte must match, 0x00 = wildcard
    /// (version-variant byte such as an adrp/bl immediate or a struct offset). When present, the
    /// runtime memory patcher matches with the mask and writes ONLY the action bytes (where
    /// `patched` differs from `original`), leaving wildcard bytes untouched — so one masked
    /// pattern survives across Telegram builds instead of needing per-version `.vNNN` variants.
    public let originalMask: Data?
    public let expectedOccurrences: Int
    public let mode: BinaryReplacementMode
    public let template: BinaryPatchTemplate?
    public let enabledParameterValues: Set<UInt64>?
    private let fixedPatched: Data

    public var patched: Data {
        patchedData(parameterValue: nil)
    }

    public init(
        id: String,
        originalHex: String,
        patchedHex: String,
        maskHex: String? = nil,
        expectedOccurrences: Int = 1,
        mode: BinaryReplacementMode = .toggle,
        alternativeGroup: String? = nil,
        template: BinaryPatchTemplate? = nil,
        enabledParameterValues: [UInt64]? = nil
    ) {
        self.id = id
        self.alternativeGroup = alternativeGroup ?? id
        self.original = Data(hexString: originalHex)
        self.fixedPatched = Data(hexString: patchedHex)
        self.originalMask = maskHex.map(Data.init(hexString:))
        self.expectedOccurrences = expectedOccurrences
        self.mode = mode
        self.template = template
        self.enabledParameterValues = enabledParameterValues.map(Set.init)
        precondition(self.original.count == self.patched.count, "Binary patches must keep byte length unchanged.")
        if let mask = self.originalMask {
            precondition(mask.count == self.original.count, "Mask length must match the pattern length.")
        }
    }

    public func patchedData(parameterValue: UInt64?) -> Data {
        template?.render(parameterValue: parameterValue) ?? fixedPatched
    }

    func matchesPatchedData(_ data: Data) -> Bool {
        template?.matchesRenderedData(data) ?? (data == fixedPatched)
    }

    func isEnabled(for parameterValue: UInt64?) -> Bool {
        guard let enabledParameterValues else { return true }
        guard let parameterValue else { return false }
        return enabledParameterValues.contains(parameterValue)
    }

    var isParameterGated: Bool {
        enabledParameterValues != nil
    }

    var isEmptyPatch: Bool {
        original.isEmpty && fixedPatched.isEmpty
    }
}

private extension BinaryPatchTemplate {
    func matchesRenderedData(_ data: Data) -> Bool {
        switch self {
        case .creditsStarsAmount:
            return Self.matchesCreditsAmountReturn(
                data,
                byteCount: 72,
                zeroRegisterOneHex: "010080d2"
            )

        case .creditsTonAmount:
            return Self.matchesCreditsAmountReturn(
                data,
                byteCount: 128,
                zeroRegisterOneHex: "e1031faa"
            )
        }
    }

    private static func matchesCreditsAmountReturn(
        _ data: Data,
        byteCount: Int,
        zeroRegisterOneHex: String
    ) -> Bool {
        guard data.count == byteCount else { return false }
        let bytes = [UInt8](data)
        return matchesMoveWide(bytes, offset: 0, register: 0, bits: 64, shift: 0, keep: false)
            && matchesMoveWide(bytes, offset: 4, register: 0, bits: 64, shift: 16, keep: true)
            && matchesMoveWide(bytes, offset: 8, register: 0, bits: 64, shift: 32, keep: true)
            && matchesMoveWide(bytes, offset: 12, register: 0, bits: 64, shift: 48, keep: true)
            && Data(bytes[16..<20]) == Data(hexString: zeroRegisterOneHex)
            && Data(bytes[20..<28]) == Data(hexString: "fd7bc1a8c0035fd6")
            && matchesRepeatedNops(bytes, offset: 28, count: (byteCount - 28) / 4)
    }

    private static func matchesMoveWide(
        _ bytes: [UInt8],
        offset: Int,
        register: UInt32,
        bits: UInt32,
        shift: UInt32,
        keep: Bool
    ) -> Bool {
        guard offset + 4 <= bytes.count else { return false }
        let instruction = UInt32(bytes[offset])
            | (UInt32(bytes[offset + 1]) << 8)
            | (UInt32(bytes[offset + 2]) << 16)
            | (UInt32(bytes[offset + 3]) << 24)
        let base: UInt32
        if bits == 64 {
            base = keep ? 0xF2800000 : 0xD2800000
        } else {
            base = keep ? 0x72800000 : 0x52800000
        }
        let expected = base | ((shift / 16) << 21) | register
        return (instruction & 0xFFE0001F) == expected
    }

    private static func matchesRepeatedNops(_ bytes: [UInt8], offset: Int, count: Int) -> Bool {
        guard offset + count * 4 <= bytes.count else { return false }
        for index in 0..<count {
            let start = offset + index * 4
            if Data(bytes[start..<(start + 4)]) != arm64Nop {
                return false
            }
        }
        return true
    }
}

/// How a rule reaches Telegram. `nil` means "use the engine's built-in classification" (the existing
/// rules); a fetched/added rule sets `runtimeMemory` so it joins the dylib memory-patch table without
/// an app rebuild (the engine's hardcoded id sets can't know a brand-new rule's id).
public enum BinaryPatchDelivery: String, Codable, Hashable, Sendable {
    case runtimeMemory
    case disk
}

/// Which patcher-UI section a rule belongs to. Externalized in `patches.json` so a fetched update
/// can place brand-new patches into the right section without an app change. A `nil`/unknown value
/// is treated as `.misc` by the UI, so the membership is data-driven, never hardcoded in the UI.
public enum BinaryPatchCategory: String, Codable, Hashable, Sendable, CaseIterable {
    case accounts
    case messages
    case optimizations
    case gifts
    case misc
}

public struct BinaryPatchRule: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let methodName: String
    public let constructorId: String
    public let kind: BinaryPatchRuleKind
    public let summary: String
    public let disabledBehavior: String
    public let riskNote: String
    public let supportedBuildNote: String
    public let parameter: BinaryPatchParameter?
    public let replacements: [BinaryReplacement]
    public let delivery: BinaryPatchDelivery?
    public let category: BinaryPatchCategory?

    public init(
        id: String,
        title: String,
        methodName: String,
        constructorId: String,
        kind: BinaryPatchRuleKind,
        summary: String,
        disabledBehavior: String,
        riskNote: String,
        supportedBuildNote: String,
        parameter: BinaryPatchParameter? = nil,
        replacements: [BinaryReplacement],
        delivery: BinaryPatchDelivery? = nil,
        category: BinaryPatchCategory? = nil
    ) {
        self.id = id
        self.title = title
        self.methodName = methodName
        self.constructorId = constructorId.lowercased()
        self.kind = kind
        self.summary = summary
        self.disabledBehavior = disabledBehavior
        self.riskNote = riskNote
        self.supportedBuildNote = supportedBuildNote
        self.parameter = parameter
        self.replacements = replacements
        self.delivery = delivery
        self.category = category
    }

    /// Copy with a different category (used to stamp the built-in seed rules from a single mapping
    /// so they stay byte-identical to the categorized `patches.json`).
    public func withCategory(_ category: BinaryPatchCategory?) -> BinaryPatchRule {
        BinaryPatchRule(
            id: id, title: title, methodName: methodName, constructorId: constructorId, kind: kind,
            summary: summary, disabledBehavior: disabledBehavior, riskNote: riskNote,
            supportedBuildNote: supportedBuildNote, parameter: parameter, replacements: replacements,
            delivery: delivery, category: category
        )
    }

    /// Stable hash of what this rule would write (bytes/masks/structure), independent of user
    /// parameter choices. Recorded in the manifest at apply time; if a fetched update changes the
    /// definition while the rule is enabled, the new digest differs and the row offers "Update".
    public var definitionDigest: String {
        var hasher = SHA256()
        hasher.update(data: Data(id.utf8))
        if let delivery {
            hasher.update(data: Data(("delivery:" + delivery.rawValue).utf8))
        }
        for replacement in replacements {
            hasher.update(data: Data(replacement.id.utf8))
            hasher.update(data: replacement.original)
            hasher.update(data: replacement.patched)
            if let mask = replacement.originalMask {
                hasher.update(data: mask)
            }
            let meta = "|\(replacement.expectedOccurrences)|\(replacement.mode.rawValue)|\(replacement.alternativeGroup)|\(replacement.template?.rawValue ?? "")"
            hasher.update(data: Data(meta.utf8))
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }
}

public enum BinaryPatchRuleDefinitions {
    public static let unsupportedBuild = "Built-in ARM64 patterns were derived from Telegram Desktop 6.8.4 and 6.8.5. Other builds are patched only when the exact byte patterns match."

    private static let rawBuiltInRules: [BinaryPatchRule] = [
        // The base hook every runtime patch loads through. Enabling it installs the
        // DYLD_INSERT_LIBRARIES launcher wrapper that loads Patchgram.dylib into Telegram,
        // with no behavior change of its own (no byte patch — the empty-hex flag is a no-op,
        // and the dylib's hooks stay inert until a feature patch turns them on). Kept first in
        // the catalog so it reads as the foundation. delivery: .runtimeMemory classifies it as a
        // runtime rule so the engine wraps + compiles the dylib when it is enabled.
        BinaryPatchRule(
            id: "binary.dylib.inject",
            title: "Dylib injection",
            methodName: "DYLD_INSERT_LIBRARIES wrapper",
            constructorId: "dylib-inject",
            kind: .runtimeMemory,
            summary: "Injects Patchgram.dylib into Telegram Desktop through a DYLD_INSERT_LIBRARIES launcher wrapper. This is the base hook every runtime patch loads through; enabling it on its own loads the dylib with no behavior change so the runtime hooks are present.",
            disabledBehavior: "Removes the dylib launcher wrapper once no runtime patch still needs it, restoring the original Telegram executable launch.",
            riskNote: "The wrapper only sets DYLD_INSERT_LIBRARIES for Telegram; it does not modify Telegram's own bytes. The dylib's hooks stay inert until a feature patch enables them.",
            supportedBuildNote: "Dylib injection installs a DYLD_INSERT_LIBRARIES launcher wrapper and is independent of the Telegram Desktop build version.",
            replacements: [
                BinaryReplacement(
                    id: "dylib.inject.runtime_flag",
                    originalHex: "",
                    patchedHex: ""
                )
            ],
            delivery: .runtimeMemory
        ),
        // Native AppKit overlay drawn by Patchgram.dylib (runtime flag only — no bytes
        // patched). Enables the floating info button + half-transparent settings panel
        // (Animation toggle + .png picker) and the profile-popup "rain" animation.
        BinaryPatchRule(
            id: "binary.overlay.profile_rain",
            title: "Profile rain overlay",
            methodName: "AppKit overlay",
            constructorId: "overlay",
            kind: .runtimeMemory,
            summary: "Shows a native AppKit overlay inside Telegram: a floating button opens a panel where you pick a .png OR an animated .tgs sticker plus an animation style; with it on, the chosen image rains over an open profile and auto-follows it. Drawn by Patchgram.dylib — no Telegram bytes are patched.",
            disabledBehavior: "Removes the overlay button/panel from Telegram.",
            riskNote: "Cosmetic local overlay drawn by the injected dylib via AppKit; it does not modify Telegram's own bytes or data.",
            supportedBuildNote: "The overlay is a native AppKit window, independent of the Telegram Desktop build version.",
            replacements: [
                BinaryReplacement(
                    id: "overlay.profile_rain.runtime_flag",
                    originalHex: "",
                    patchedHex: ""
                )
            ],
            delivery: .runtimeMemory
        ),
        // Diagnostic MTProto logger drawn by Patchgram.dylib (runtime flag only — no bytes
        // patched). Reuses the dylib's existing send_prepared / try_to_receive hooks to append
        // every request + response to Resources/logs_mtproto_pg/log_<start>.log, opened in the
        // dylib constructor before Telegram sends its first packet.
        BinaryPatchRule(
            id: "binary.mtproto.logger",
            title: "MTProto request/response logger",
            methodName: "MTProto logger",
            constructorId: "mtproto-logger",
            kind: .runtimeMemory,
            summary: "Logs every MTProto request Telegram sends and every response it receives, each with a timestamp, to log_<start>.log files inside Telegram.app/Contents/Resources/logs_mtproto_pg. The logger opens its file in the injected dylib's constructor — before Telegram sends its first packet — so the trace is complete from launch. Each line records the direction, request id, TL constructor, and a hex preview of the body. Drawn by Patchgram.dylib — no Telegram bytes are patched.",
            disabledBehavior: "Stops writing MTProto logs (existing log files are kept). Takes effect on the next Telegram launch.",
            riskNote: "Diagnostic only: the dylib observes the request/response buffers it already hooks and appends them to local .log files; it does not modify Telegram's bytes or traffic. The logs can contain sensitive request/response data, so treat the files as private.",
            supportedBuildNote: "Uses the dylib's existing send/receive hooks; independent of byte-level signatures, so it is resilient across Telegram Desktop builds.",
            replacements: [
                BinaryReplacement(
                    id: "mtproto.logger.runtime_flag",
                    originalHex: "",
                    patchedHex: ""
                )
            ],
            delivery: .runtimeMemory
        ),
        BinaryPatchRule(
            id: "binary.presence.force_offline",
            title: "Always offline",
            methodName: "account.updateStatus",
            constructorId: "6628562c",
            kind: .forceSerializedBool,
            summary: "Patches the serialized account.updateStatus request so its offline Bool is always boolTrue.",
            disabledBehavior: "Restores the original load-and-branch instructions from the executable backup pattern.",
            riskNote: "This is version-sensitive binary patching; Patchgram refuses to patch when the expected instruction windows are not unique.",
            supportedBuildNote: unsupportedBuild,
            replacements: [
                BinaryReplacement(
                    id: "account.updateStatus.offline.load.first",
                    originalHex: "686e40b9e80f0034e0030091",
                    patchedHex: "a8b68e52482eb372e0030091"
                ),
                BinaryReplacement(
                    id: "account.updateStatus.offline.load.second",
                    originalHex: "686e40b908100034e81700b9",
                    patchedHex: "a8b68e52482eb372e81700b9"
                )
            ]
        ),
        BinaryPatchRule(
            id: "binary.activity.block_typing",
            title: "Block typing activity",
            methodName: "messages.setTyping",
            constructorId: "58943ee2",
            kind: .poisonConstructor,
            summary: "Changes the serialized messages.setTyping constructor id to an invalid id so the request cannot be accepted.",
            disabledBehavior: "Restores the original constructor-id load instructions.",
            riskNote: "The request can still be attempted locally, but the serialized MTProto method id is invalidated.",
            supportedBuildNote: unsupportedBuild,
            replacements: [
                BinaryReplacement(
                    id: "messages.setTyping.constructor",
                    originalHex: "48dc87528812ab72",
                    patchedHex: "280080522800be72"
                )
            ]
        ),
        BinaryPatchRule(
            id: "binary.read_receipts.block_history_read",
            title: "Block read messages",
            methodName: "messages.readHistory / channels.readHistory",
            constructorId: "e306d3a / cc104937",
            kind: .poisonConstructor,
            summary: "Invalidates messages.readHistory and channels.readHistory constructor ids in the serialized requests while keeping the local who-read menu gate available.",
            disabledBehavior: "Restores the original readHistory constructor-id load instructions and who-read menu gate.",
            riskNote: "Unread counters can still move locally; this prevents valid readHistory methods from being serialized and only bypasses the local unread check that hides the who-read context menu item.",
            supportedBuildNote: unsupportedBuild,
            replacements: [
                BinaryReplacement(
                    id: "channels.readHistory.constructor",
                    originalHex: "e82689520882b972",
                    patchedHex: "480080522800be72"
                ),
                BinaryReplacement(
                    id: "messages.readHistory.constructor",
                    originalHex: "48a78d5208c6a172",
                    patchedHex: "680080522800be72"
                ),
                BinaryReplacement(
                    id: "api.who_read_exists.unread_gate.keep_menu",
                    originalHex: "e00313aa17b78d94c0fc07372d000014",
                    patchedHex: "e00313aa17b78d941f2003d52d000014",
                    maskHex: "ffffffff000000ffffffffffffffffff",
                ),
            ]
        ),
        BinaryPatchRule(
            id: "binary.messages.settings",
            title: "Message settings",
            methodName: "messages.setTyping / messages.readHistory / messages.saveDraft / messages.getFactCheck",
            constructorId: "58943ee2 / e306d3a / cc104937 / 54ae308e / b9cdc5ee",
            kind: .poisonConstructor,
            summary: "Groups message privacy tweaks: block typing activity, block read receipts, keep drafts local, schedule sends locally, and locally inject custom Fact Check blocks.",
            disabledBehavior: "Restores Telegram's original message activity, read-history, draft-sync, scheduled-send, and Fact Check behavior.",
            riskNote: "These are client-side serialization patches. Telegram can still update local state; this prevents the patched requests from being serialized with valid MTProto method ids.",
            supportedBuildNote: unsupportedBuild,
            replacements: [
                BinaryReplacement(
                    id: "messages.setTyping.constructor",
                    originalHex: "48dc87528812ab72",
                    patchedHex: "280080522800be72",
                    alternativeGroup: "messages.typing.disable"
                ),
                BinaryReplacement(
                    id: "channels.readHistory.constructor",
                    originalHex: "e82689520882b972",
                    patchedHex: "480080522800be72",
                    alternativeGroup: "messages.read_receipts.channels_read_history"
                ),
                BinaryReplacement(
                    id: "messages.readHistory.constructor",
                    originalHex: "48a78d5208c6a172",
                    patchedHex: "680080522800be72",
                    alternativeGroup: "messages.read_receipts.messages_read_history"
                ),
                BinaryReplacement(
                    id: "api.who_read_exists.unread_gate.keep_menu",
                    originalHex: "e00313aa17b78d94c0fc07372d000014",
                    patchedHex: "e00313aa17b78d941f2003d52d000014",
                    alternativeGroup: "messages.read_receipts.who_read_gate"
                ),
                BinaryReplacement(
                    id: "messages.saveDraft.constructor",
                    originalHex: "c8118652c895aa72",
                    patchedHex: "880080522800be72",
                    alternativeGroup: "messages.drafts.local_only"
                ),
                // 6.9.0: messages.saveDraft constructor magic changed 0x54ae308e -> 0xad0fa15c
                // (schema added effect/suggested_post/rich_message). Same w8 register + same
                // no-op redirect (0xf0010004), so the patched bytes are unchanged.
                BinaryReplacement(
                    id: "messages.saveDraft.constructor.v690",
                    originalHex: "882b9452e8a1b572",
                    patchedHex: "880080522800be72",
                    alternativeGroup: "messages.drafts.local_only"
                ),
                BinaryReplacement(
                    id: "messages.scheduled_send.runtime_flag",
                    originalHex: "",
                    patchedHex: "",
                    alternativeGroup: "messages.scheduled_send.local"
                ),
                BinaryReplacement(
                    id: "messages.fact_check.runtime_flag",
                    originalHex: "",
                    patchedHex: "",
                    alternativeGroup: "messages.fact_check.local"
                ),
                // Runtime-flag subpatch (no on-disk bytes). Drives the createView
                // dylib hook to clear MessageFlag::NoForwards on each HistoryItem
                // (and the channel/chat NoForwards on its peer) so the forward path
                // and text selection see "allowed".
                BinaryReplacement(
                    id: "messages.noforwards.allow_copy.runtime_flag",
                    originalHex: "",
                    patchedHex: "",
                    alternativeGroup: "messages.noforwards.allow_copy"
                ),
                // Disable TTL. Runtime flag drives the createView hook to zero the
                // message ttl_period auto-delete (_ttlDestroyAt). The byte patch forces
                // view-once media (video/document) ttl_seconds to 0 at construction:
                // in create_media the read `LDRSW X9,[X19,#0x4C]` (ttl_seconds) becomes
                // `MOV X9,#0`, so the media is built without a self-destruct timer.
                // 6.9.1 window (unique); other builds harmlessly "not found".
                BinaryReplacement(
                    id: "messages.ttl.disable.runtime_flag",
                    originalHex: "",
                    patchedHex: "",
                    alternativeGroup: "messages.ttl.disable"
                ),
                BinaryReplacement(
                    id: "data.create_media.ttl_seconds.force_zero",
                    originalHex: "680e40b948001036694e80b9e96300f9",
                    patchedHex: "680e40b948001036090080d2e96300f9",
                    alternativeGroup: "messages.ttl.disable"
                ),
                // The "view this on your phone" tooltip for view-once video/voice/round
                // media is gated on `media->ttlSeconds() > 0` (and allowsForward()=!ttlSeconds()).
                // The construction patch above only affects NEWLY received media; this one
                // forces MediaFile::ttlSeconds() (the virtual getter @ vtable off_10C680818)
                // to always return 0 — `LDR X0,[X0,#0x20]` -> `MOV X0,#0` — so already-cached
                // view-once media also opens on desktop. 6.9.1 window includes the preceding
                // accessor for uniqueness; other builds harmlessly "not found".
                BinaryReplacement(
                    id: "data.media_file.ttl_seconds.force_zero",
                    originalHex: "00184139c0035fd6001040f9c0035fd6",
                    patchedHex: "00184139c0035fd6000080d2c0035fd6",
                    alternativeGroup: "messages.ttl.disable"
                )
            ]
        ),
        BinaryPatchRule(
            id: "binary.links.open_without_warning",
            title: "Open links without warning",
            methodName: "HiddenUrlClickHandler::Open / HiddenUrlRequiresConfirmation",
            constructorId: "local-hidden-url-confirmation",
            kind: .forceSerializedBool,
            summary: "Skips Telegram's hidden-url confirmation branch so links open directly without the Open this link? warning.",
            disabledBehavior: "Restores Telegram's original hidden-url confirmation branch.",
            riskNote: "This is a local UI patch. It bypasses Telegram's external-link confirmation dialog, including suspicious or mismatched display links.",
            supportedBuildNote: unsupportedBuild,
            replacements: [
                BinaryReplacement(
                    id: "core.hidden_url.confirmation.branch.skip",
                    originalHex: "e0e301916d030094a0080036",
                    patchedHex: "890000141f2003d51f2003d5"
                ),
                // 6.9.0 variant: identical window except the `bl HiddenUrlRequiresConfirmation`
                // PC-relative offset (6d030094 -> 73030094). The `add x0,sp,#0x78` and
                // `tbz w0,#0,+0x14` bytes and the relative `b +0x224` skip target are byte-stable
                // (verified: A+0x224 lands on the same continuation in both builds). Whichever
                // variant does not match the running build logs a harmless "not found".
                BinaryReplacement(
                    id: "core.hidden_url.confirmation.branch.skip.v690",
                    originalHex: "e0e3019173030094a0080036",
                    patchedHex: "890000141f2003d51f2003d5"
                )
            ]
        ),
        BinaryPatchRule(
            id: "binary.privacy.no_phone_on_add",
            title: "Don't share phone when adding contacts",
            methodName: "contacts.addContact",
            constructorId: "d9ba2e54",
            kind: .forceSerializedBool,
            summary: "Forces the serialized contacts.addContact flags to keep only f_note, preventing add_phone_privacy_exception from being sent.",
            disabledBehavior: "Keeps Telegram's original add-contact flags, including the add_phone_privacy_exception bit when Telegram sets it.",
            riskNote: "This is a client-side request serialization patch. It only affects the add-contact request path matched by the built-in ARM64 pattern.",
            supportedBuildNote: unsupportedBuild,
            replacements: [
                BinaryReplacement(
                    id: "contacts.addContact.flags.clear_phone_privacy_exception",
                    originalHex: "88ca85524837bb72e81f02b9010b40f9e2730891e00318aa147fd997080340f9880000b4080140b91f090071cb000054e00318aa01008052020080d2030080d2437fd997e8b342b9e81f02b9010b40f9",
                    patchedHex: "88ca85524837bb72e81f02b9010b40f9e2730891e00318aa147fd997080340f9880000b4080140b91f090071cb000054e00318aa01008052020080d2030080d2437fd99748008052e81f02b9010b40f9",
                    maskHex: "ffffffffffffffffffffffffffffffffffffffffffffffff0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000ffffffffffffffffffffffffffff",
                ),
            ]
        ),
        BinaryPatchRule(
            id: "binary.accounts.limit_999",
            title: "999 accounts",
            methodName: "Main::Domain / Storage::Domain",
            constructorId: "local-account-limit",
            kind: .unlockLimit,
            summary: "Raises Telegram's local account add/menu/storage checks from the upstream 6-account cap to 999 accounts.",
            disabledBehavior: "Restores the original 6-account add/menu/storage checks.",
            riskNote: "This only changes local client-side limits. Telegram server account/session rules still apply.",
            supportedBuildNote: unsupportedBuild,
            replacements: [
                BinaryReplacement(
                    id: "main.accounts.last_max.update_limit",
                    originalHex: "690080525f0d007149b1891a290d0011",
                    patchedHex: "e97c80521f2003d51f2003d51f2003d5",
                    expectedOccurrences: 2
                ),
                BinaryReplacement(
                    id: "main.accounts.add_activated.max_limit",
                    originalHex: "6d0080527f0d00716bb18d1a6b0d0011",
                    patchedHex: "eb7c80521f2003d51f2003d51f2003d5"
                ),
                BinaryReplacement(
                    id: "main.accounts.add.expect_limit",
                    originalHex: "5f4501f1822d0054",
                    patchedHex: "9f9d0ff1822d0054"
                ),
                BinaryReplacement(
                    id: "main.accounts.max_accounts.return_limit",
                    originalHex: "690080521f0d007108b1891a000d0011",
                    patchedHex: "e07c80521f2003d51f2003d51f2003d5"
                ),
                BinaryReplacement(
                    id: "storage.accounts.count.limit",
                    originalHex: "081d00511f1d0031",
                    patchedHex: "08a10f511fa10f31"
                ),
                BinaryReplacement(
                    id: "storage.accounts.index.limit",
                    originalHex: "3f140071c8feff54",
                    patchedHex: "3f980f71c8feff54"
                )
            ]
        ),
        BinaryPatchRule(
            id: "binary.inline.callback_hover",
            title: "Show bot callback-data on hover",
            methodName: "ReplyMarkupClickHandler::getUrlButton",
            constructorId: "local-callback-tooltip",
            kind: .overrideDisplayedValue,
            summary: "Treats bot callback, WebView, and SimpleWebView inline buttons as URL-like for hover/copy text so callback-data is visible locally.",
            disabledBehavior: "Restores Telegram's original URL/Auth-only inline button hover behavior.",
            riskNote: "This is a local UI patch only. It shows data already present in the message markup and does not send bot callbacks by itself.",
            supportedBuildNote: unsupportedBuild,
            replacements: [
                BinaryReplacement(
                    id: "history.reply_markup.tooltip.url_button_types",
                    originalHex: "080040391f3100710419417a80000054",
                    patchedHex: "08004039c9009a522825c81a88000037"
                ),
                BinaryReplacement(
                    id: "history.reply_markup.text.url_button_types",
                    originalHex: "080040391f3100710419417ac0000054",
                    patchedHex: "08004039c9009a522825c81ac8000037",
                    expectedOccurrences: 3
                )
            ]
        ),
        BinaryPatchRule(
            id: "binary.config.disable_monetization",
            title: "Disable Premium, Stars, TON & Gifts",
            methodName: "help.getAppConfig",
            constructorId: "61e3f854",
            kind: .runtimeMemory,
            summary: "Uses Patchgram.dylib to disable selected monetization config, gift/status requests, paid reactions, Premium effects, and local Premium/Stars/Gifts/Boost UI gates at runtime.",
            disabledBehavior: "Stops the runtime memory overrides and keeps the original on-disk Telegram executable bytes restored.",
            riskNote: "This is a local runtime patch. It scans known arm64 byte windows on startup/config reload instead of rewriting them on disk, so exact semantic coverage can still differ between Telegram Desktop versions until each path is replaced by a higher-level hook.",
            supportedBuildNote: unsupportedBuild,
            replacements: [
                BinaryReplacement(
                    id: "data.peer_premium_value.normalize_legacy_true",
                    originalHex: "081c40f9e80b00f9280080521f2003d5a8f31e38",
                    patchedHex: "081c40f9e80b00f9081942b908390e53a8f31e38",
                    expectedOccurrences: 2,
                    mode: .normalize
                ),
                BinaryReplacement(
                    id: "help.getAppConfig.constructor",
                    originalHex: "880a9f52683cac72",
                    patchedHex: "88468252e8efaf72"
                ),
                BinaryReplacement(
                    id: "data.peer_premium_value.force_false",
                    originalHex: "081c40f9e80b00f9081942b908390e53a8f31e38",
                    patchedHex: "081c40f9e80b00f9080080521f2003d5a8f31e38",
                    expectedOccurrences: 2
                ),
                BinaryReplacement(
                    id: "data.user_flags.premium.force_clear",
                    originalHex: "6c011a12ab0105124d011212ca011612",
                    patchedHex: "6c011a12ab010512ed031f2aca011612"
                ),
                BinaryReplacement(
                    id: "data.peer_color.collectible.force_empty",
                    originalHex: "280440f9155c41f9280600b4",
                    patchedHex: "080080d2155c41f9280600b4"
                ),
                BinaryReplacement(
                    id: "data.peer_profile_color.collectible.force_empty",
                    originalHex: "280440f915d041f9280600b4",
                    patchedHex: "080080d215d041f9280600b4"
                ),
                // 6.9.0 variant: the UserData collectible-profile-color field moved 0x3a0 -> 0x3a8
                // (15d041f9 -> 15d441f9), same field shift as setBotVerifyDetails. Rest stable.
                BinaryReplacement(
                    id: "data.peer_profile_color.collectible.force_empty.v690",
                    originalHex: "280440f915d441f9280600b4",
                    patchedHex: "080080d215d441f9280600b4"
                ),
                BinaryReplacement(
                    id: "data.stars_rating_value.force_empty",
                    originalHex: "0a0080520b1c40f9eb0b00f9686141f9696541f9cb0000b46c3940398c3d50d36c0000b56a6548394a1505530b7d60921f0500314ad59f1a5f0100716a119f9a0a7d40b3ea2702a9",
                    patchedHex: "0a0080520b1c40f9eb0b00f9ff7f02a91f2003d51f2003d51f2003d51f2003d51f2003d51f2003d51f2003d51f2003d51f2003d51f2003d51f2003d51f2003d51f2003d51f2003d5",
                    expectedOccurrences: 2
                ),
                BinaryReplacement(
                    id: "info.profile.emoji_status_value.force_empty",
                    originalHex: "091c40f9287d40f9e92301a9288540f92141c03de103823c880000b40821009129008052080129f8",
                    patchedHex: "091c40f9e97f01a9ff7f02a91f2003d51f2003d51f2003d51f2003d51f2003d51f2003d51f2003d5",
                    expectedOccurrences: 2
                ),
                BinaryReplacement(
                    id: "main.session.premium_possible_value.force_false",
                    originalHex: "081c40f9e80b00f9083140f9081942b908390e53",
                    patchedHex: "081c40f9e80b00f9083140f9080080521f2003d5",
                    expectedOccurrences: 2,
                    alternativeGroup: "main.session.premium_possible_value.force_false"
                ),
                BinaryReplacement(
                    id: "main.session.premium_possible_value.local_true_force_false",
                    originalHex: "081c40f9e80b00f9083140f9280080521f2003d5",
                    patchedHex: "081c40f9e80b00f9083140f9080080521f2003d5",
                    expectedOccurrences: 2,
                    alternativeGroup: "main.session.premium_possible_value.force_false"
                ),
                BinaryReplacement(
                    id: "settings.main.premium_section.skip",
                    originalHex: "683340f9086548396800303768e34439086d0036",
                    patchedHex: "6c0300141f2003d51f2003d51f2003d5086d0036"
                ),
                BinaryReplacement(
                    id: "settings.privacy.gifts.skip",
                    originalHex: "60d2029000d00891f4430291e8430291a1018052",
                    patchedHex: "4c0000141f2003d51f2003d51f2003d5a1018052"
                ),
                // 6.9.0: disambiguated by the adrp+add target deep-link string — the correct
                // site references "privacy/gifts" (the other candidate referenced "privacy/calls").
                // Same b+0x130 skip; verified the branch lands on the next settings row.
                BinaryReplacement(
                    id: "settings.privacy.gifts.skip.v690",
                    originalHex: "40d5029000581291f4430291e8430291a1018052",
                    patchedHex: "4c0000141f2003d51f2003d51f2003d5a1018052"
                ),
                BinaryReplacement(
                    id: "history.send_gift_toggle.force_false",
                    originalHex: "e80280521f01346ae8079f1ad3ffff17",
                    patchedHex: "080080521f2003d51f2003d5d3ffff17"
                ),
                BinaryReplacement(
                    id: "window.peer_menu.boost_chat_action.disable",
                    originalHex: "155c40f9a83a40394900e0d23fc108eba40a40fa80100054",
                    patchedHex: "890000141f2003d51f2003d51f2003d51f2003d51f2003d5"
                ),
                BinaryReplacement(
                    id: "info.profile.send_gift_action.skip",
                    originalHex: "755e40f9a83a40394900e0d23fc108eb",
                    patchedHex: "3c0100141f2003d51f2003d51f2003d5"
                ),
                BinaryReplacement(
                    id: "ui.peer_badge.premium_verified_branch.skip",
                    originalHex: "881640f9681100b5c6000014880188b7",
                    patchedHex: "881640f91f2003d5c6000014880188b7"
                ),
                BinaryReplacement(
                    id: "ui.peer_badge.premium_plain_branch.skip",
                    originalHex: "881640f9e80f00b5ba000014c8a24739",
                    patchedHex: "881640f91f2003d5ba000014c8a24739"
                ),
                BinaryReplacement(
                    id: "ui.peer_badge.premium_channel_branch.skip",
                    originalHex: "881640f9a80700b4c80a40f9",
                    patchedHex: "881640f93d000014c80a40f9"
                ),
                BinaryReplacement(
                    id: "window.main_menu.status_label.move_offscreen",
                    originalHex: "281003d015f145b9281003d016f545b9e00314aa088c42f8081540f900013fd6",
                    patchedHex: "281003d015f145b9281003d0f6ff8112e00314aa088c42f8081540f900013fd6"
                ),
                BinaryReplacement(
                    id: "window.main_menu.set_status_label.hide",
                    originalHex: "530065007400200045006d006f006a0069002000530074006100740075007300",
                    patchedHex: "0b200b200b200b200b200b200b200b200b200b200b200b200b200b200b200c20",
                    expectedOccurrences: 2
                ),
                BinaryReplacement(
                    id: "window.main_menu.change_status_label.hide",
                    originalHex: "4300680061006e0067006500200045006d006f006a0069002000530074006100740075007300",
                    patchedHex: "0b200b200b200b200b200b200b200b200b200b200b200b200b200b200b200b200b200b200d20"
                ),
                BinaryReplacement(
                    id: "data.allowed_reactions.paid.force_false",
                    originalHex: "8872003993760039e82f40f9a9270490290547f9290140f93f0108eb41020054",
                    patchedHex: "887200399f760039e82f40f9a9270490290547f9290140f93f0108eb41020054",
                    maskHex: "ffffffffffffffffffffffff0000ff00ff00ffffffffffffffffffffffffffff",
                ),
                BinaryReplacement(
                    id: "data.reaction_paid.decode_empty",
                    originalHex: "699d9452a947aa721f01096b00020054",
                    patchedHex: "699d9452a947aa721f01096ba0000054"
                ),
                BinaryReplacement(
                    id: "data.message_reactions.skip_empty_counts",
                    originalHex: "3a0200b4e803009140630091aa49f7975a2b40b9e1030091e00315aad907f8971a0000b9e81b40b91f05003100feff54287b68f8e0bf0091e103009100013fd6ebffff176908805248cf03b008393c910a6969385fbd0071000100545f710171c0000054290500d13f0500b121ffff54090080d20200001429050091a0d003d0001808910101098b62098052e46f19950e000014",
                    patchedHex: "7a0300b4e803009140630091aa49f797e81b40b928010035e90b40f9e90000b5287b68f8e0bf0091e103009100013fd61a008052eeffff175a2b40b9e1030091e00315aacf07f8971a0000b9e81b40b91f050031c0fcff54287b68f8e0bf0091e103009100013fd6e1ffff171a008052dfffff171f2003d51f2003d51f2003d51f2003d51f2003d51f2003d51f2003d51f2003d5"
                ),
                // NOTE: no `.v690` for message_reactions.skip_empty_counts. Unlike the other
                // v690 variants (single-instruction / branch-skip rewrites), this one is a
                // 148-byte in-place LOOP rewrite whose patched form contains relative branches
                // that target OUTSIDE the window. The auto byte-transfer (keep 6.8.5 patched
                // bytes where they differed) preserved those 6.8.5-relative offsets, which point
                // into garbage at the 6.9.0 location → corrupted control flow → crash
                // (PC=0x103fb7334, inside this region). Left inert on 6.9.0 (a minor cosmetic
                // "hide empty reaction counts"; paid reactions are still disabled by the other
                // patches). Re-deriving needs the branch offsets recomputed for the 6.9.0 layout.
                BinaryReplacement(
                    id: "api.who_read_exists.chat_threshold.default_100",
                    originalHex: "41281391e0c30091dcacf5972809e8d20001679e",
                    patchedHex: "41281391e0c30091dcacf597280be8d20001679e"
                ),
                BinaryReplacement(
                    id: "api.who_read_exists.chat_threshold.default_100.cstring_4ca",
                    originalHex: "41c004f021281391e0c30091dcacf5972809e8d20001679e",
                    patchedHex: "41c004f021281391e0c30091dcacf597280be8d20001679e",
                    maskHex: "0000000000000000ffffffff00000000ffffffffffffffff",
                    alternativeGroup: "api.who_read_exists.chat_threshold.default_100"
                ),
                BinaryReplacement(
                    id: "payments.getSavedStarGifts.constructor",
                    originalHex: "28ad9c522863b472e81700b9",
                    patchedHex: "2800805208eaad72e81700b9"
                ),
                BinaryReplacement(
                    id: "payments.getStarGifts.constructor",
                    originalHex: "08b28652c88ab872e87f00b9",
                    patchedHex: "4800805208eaad72e87f00b9"
                ),
                BinaryReplacement(
                    id: "payments.getSavedStarGift.constructor",
                    originalHex: "c8209452a88ab672e81700b9",
                    patchedHex: "6800805208eaad72e81700b9"
                ),
                BinaryReplacement(
                    id: "payments.getStarGiftCollections.constructor",
                    originalHex: "a83b92526803b372e86300b9",
                    patchedHex: "8800805208eaad72e86300b9"
                ),
                BinaryReplacement(
                    id: "payments.getUniqueStarGift.constructor",
                    originalHex: "48ae8952e832b472e8d701b9",
                    patchedHex: "a800805208eaad72e8d701b9"
                ),
                BinaryReplacement(
                    id: "payments.getResaleStarGifts.constructor",
                    originalHex: "c8469452e84baf72e84f01b9",
                    patchedHex: "c800805208eaad72e84f01b9"
                ),
                BinaryReplacement(
                    id: "payments.checkCanSendGift.constructor",
                    originalHex: "28b99d528818b872e81700b9",
                    patchedHex: "e800805208eaad72e81700b9"
                ),
                BinaryReplacement(
                    id: "payments.getStarGiftUpgradePreview.constructor",
                    originalHex: "289697524893b372e81700b9",
                    patchedHex: "0801805208eaad72e81700b9"
                ),
                BinaryReplacement(
                    id: "payments.toggleStarGiftsPinnedToTop.constructor",
                    originalHex: "08f69c5268a2a272e8c700b9",
                    patchedHex: "2801805208eaad72e8c700b9"
                ),
                BinaryReplacement(
                    id: "payments.saveStarGift.constructor",
                    originalHex: "882f8d524845a572e84f00b9",
                    patchedHex: "4801805208eaad72e84f00b9"
                ),
                BinaryReplacement(
                    id: "payments.transferStarGift.constructor",
                    originalHex: "48ed825208e3af72e88f00b9",
                    patchedHex: "6801805208eaad72e88f00b9"
                ),
                BinaryReplacement(
                    id: "payments.upgradeStarGift.constructor",
                    originalHex: "a89e9c52c8dab572e89f00b9",
                    patchedHex: "8801805208eaad72e89f00b9"
                ),
                BinaryReplacement(
                    id: "payments.createStarGiftCollection.constructor",
                    originalHex: "e8d0815248e9a372e85f01b9",
                    patchedHex: "a801805208eaad72e85f01b9"
                ),
                BinaryReplacement(
                    id: "payments.updateStarGiftCollection.constructor",
                    originalHex: "e8dc9752a8fba972e81700b9",
                    patchedHex: "c801805208eaad72e81700b9"
                ),
                BinaryReplacement(
                    id: "payments.deleteStarGiftCollection.constructor",
                    originalHex: "081d8952c8aab572e82700b9",
                    patchedHex: "e801805208eaad72e82700b9"
                ),
                BinaryReplacement(
                    id: "payments.reorderStarGiftCollections.constructor",
                    originalHex: "88999e524865b872e8af00b9",
                    patchedHex: "0802805208eaad72e8af00b9"
                ),
                BinaryReplacement(
                    id: "payments.getCraftStarGifts.constructor",
                    originalHex: "08a09b52a8a0bf72e8a700b9",
                    patchedHex: "2802805208eaad72e8a700b9"
                ),
                BinaryReplacement(
                    id: "messages.sendPaidReaction.constructor",
                    originalHex: "086a99526817ab72e85b00b9",
                    patchedHex: "4802805208eaad72e85b00b9"
                ),
                BinaryReplacement(
                    id: "messages.togglePaidReactionPrivacy.constructor",
                    originalHex: "a8b69052086ba872e88700b9",
                    patchedHex: "6802805208eaad72e88700b9"
                ),
                BinaryReplacement(
                    id: "account.updateEmojiStatus.constructor",
                    originalHex: "68cd9b52687abf72e85b00b9",
                    patchedHex: "8802805208eaad72e85b00b9"
                ),
                BinaryReplacement(
                    id: "channels.updateEmojiStatus.constructor",
                    originalHex: "08d59c52681abe72e86f00b9",
                    patchedHex: "a802805208eaad72e86f00b9"
                ),
                BinaryReplacement(
                    id: "account.getDefaultEmojiStatuses.constructor",
                    originalHex: "c8708652a8ceba72e81700b9",
                    patchedHex: "c802805208eaad72e81700b9"
                ),
                BinaryReplacement(
                    id: "account.getRecentEmojiStatuses.constructor",
                    originalHex: "a8209052e8eaa172e81700b9",
                    patchedHex: "e802805208eaad72e81700b9"
                ),
                BinaryReplacement(
                    id: "account.getCollectibleEmojiStatuses.constructor",
                    originalHex: "68a8885268cfa572e81700b9",
                    patchedHex: "0803805208eaad72e81700b9"
                ),
                BinaryReplacement(
                    id: "messages.getAvailableEffects.constructor",
                    originalHex: "2847815248d4bb72e81f00b9",
                    patchedHex: "2803805208eaad72e81f00b9"
                ),
                BinaryReplacement(
                    id: "core.url.premium_offer.route.disable",
                    originalHex: "5e007000720065006d00690075006d005f006f0066006600650072002f003f0028005c003f002e002b0029003f00280023007c0024002900",
                    patchedHex: "5e007800720065006d00690075006d005f006f0066006600650072002f003f0028005c003f002e002b0029003f00280023007c0024002900"
                ),
                BinaryReplacement(
                    id: "core.url.premium_multigift.route.disable",
                    originalHex: "5e007000720065006d00690075006d005f006d0075006c007400690067006900660074002f003f005c003f0028002e002b002900280023007c0024002900",
                    patchedHex: "5e007800720065006d00690075006d005f006d0075006c007400690067006900660074002f003f005c003f0028002e002b002900280023007c0024002900"
                ),
                BinaryReplacement(
                    id: "core.url.boost.route.disable",
                    originalHex: "5e0062006f006f00730074002f003f005c003f0028002e002b002900280023007c0024002900",
                    patchedHex: "5e0078006f006f00730074002f003f005c003f0028002e002b002900280023007c0024002900"
                ),
                BinaryReplacement(
                    id: "core.url.stars_topup.route.disable",
                    originalHex: "5e00730074006100720073005f0074006f007000750070002f003f005c003f0028002e002b002900280023007c0024002900",
                    patchedHex: "5e00780074006100720073005f0074006f007000750070002f003f005c003f0028002e002b002900280023007c0024002900"
                ),
                BinaryReplacement(
                    id: "core.url.nft_slug.route.disable",
                    originalHex: "5e006e00660074002f003f005c003f0073006c00750067003d0028005b0061002d007a0041002d005a0030002d0039005c002e005c005f005c002d005d002b002900280026007c0024002900",
                    patchedHex: "5e007800660074002f003f005c003f0073006c00750067003d0028005b0061002d007a0041002d005a0030002d0039005c002e005c005f005c002d005d002b002900280026007c0024002900"
                ),
                BinaryReplacement(
                    id: "core.url.stars.route.disable",
                    originalHex: "5e00730074006100720073002f003f0028005e005c003f002e002a0029003f00280023007c0024002900",
                    patchedHex: "5e00780074006100720073002f003f0028005e005c003f002e002a0029003f00280023007c0024002900"
                ),
                BinaryReplacement(
                    id: "core.url.ton.route.disable",
                    originalHex: "5e0074006f006e002f003f0028005e005c003f002e002a0029003f00280023007c0024002900",
                    patchedHex: "5e0078006f006e002f003f0028005e005c003f002e002a0029003f00280023007c0024002900"
                ),
                BinaryReplacement(
                    id: "core.url.nft_path.route.disable",
                    originalHex: "5e006e00660074002f0028005b0061002d007a0041002d005a0030002d0039005c002e005c005f005c002d005d002b00290028005c003f007c0024002900",
                    patchedHex: "5e007800660074002f0028005b0061002d007a0041002d005a0030002d0039005c002e005c005f005c002d005d002b00290028005c003f007c0024002900"
                ),
                BinaryReplacement(
                    id: "core.url.nft_redirect.disable",
                    originalHex: "740067003a002f002f006e00660074003f0073006c00750067003d00",
                    patchedHex: "740067003a002f002f007800660074003f0073006c00750067003d00"
                ),
                BinaryReplacement(
                    id: "core.url.giftcode.domain.disable",
                    originalHex: "670069006600740063006f0064006500",
                    patchedHex: "780069006600740063006f0064006500",
                    expectedOccurrences: 6
                ),
                BinaryReplacement(
                    id: "core.url.boost_channel.redirect.disable",
                    originalHex: "740067003a002f002f0062006f006f00730074003f006300680061006e006e0065006c003d00",
                    patchedHex: "740067003a002f002f0078006f006f00730074003f006300680061006e006e0065006c003d00"
                ),
                BinaryReplacement(
                    id: "core.url.boost_domain.redirect.disable",
                    originalHex: "740067003a002f002f0062006f006f00730074003f0064006f006d00610069006e003d00",
                    patchedHex: "740067003a002f002f0078006f006f00730074003f0064006f006d00610069006e003d00"
                ),
                BinaryReplacement(
                    id: "core.url.boost_redirect.disable",
                    originalHex: "740067003a002f002f0062006f006f00730074003f000000",
                    patchedHex: "740067003a002f002f0078006f006f00730074003f000000"
                ),
                BinaryReplacement(
                    id: "core.theme.gift_token_prefix.disable",
                    originalHex: "67006900660074003a00",
                    patchedHex: "78006900660074003a00",
                    expectedOccurrences: 3
                ),
                BinaryReplacement(
                    id: "settings.deep_link.send_gift.disable",
                    originalHex: "730065006e0064002d006700690066007400",
                    patchedHex: "780065006e0064002d006700690066007400",
                    expectedOccurrences: 3
                ),
                BinaryReplacement(
                    id: "settings.deep_link.my_gifts.disable",
                    originalHex: "6d0079002d00700072006f00660069006c0065002f0067006900660074007300",
                    patchedHex: "6d0079002d00700072006f00660069006c0065002f0078006900660074007300"
                ),
                BinaryReplacement(
                    id: "settings.deep_link.privacy_gifts.disable",
                    originalHex: "70007200690076006100630079002f0067006900660074007300",
                    patchedHex: "70007200690076006100630079002f0078006900660074007300",
                    expectedOccurrences: 5
                ),
                BinaryReplacement(
                    id: "settings.deep_link.stars_gift.disable",
                    originalHex: "730074006100720073002f006700690066007400",
                    patchedHex: "730074006100720073002f007800690066007400"
                ),
                BinaryReplacement(
                    id: "settings.deep_link.profile_gift.disable",
                    originalHex: "700072006f00660069006c0065002d0063006f006c006f0072002f00700072006f00660069006c0065002f007500730065002d006700690066007400",
                    patchedHex: "700072006f00660069006c0065002d0063006f006c006f0072002f00700072006f00660069006c0065002f007500730065002d007800690066007400"
                ),
                BinaryReplacement(
                    id: "settings.deep_link.name_gift.disable",
                    originalHex: "700072006f00660069006c0065002d0063006f006c006f0072002f006e0061006d0065002f007500730065002d006700690066007400",
                    patchedHex: "700072006f00660069006c0065002d0063006f006c006f0072002f006e0061006d0065002f007500730065002d007800690066007400"
                )
            ]
        ),
        BinaryPatchRule(
            id: "binary.premium.local",
            title: "Local Telegram Premium",
            methodName: "Main::Session::premiumPossibleValue",
            constructorId: "local-premium",
            kind: .localPremium,
            summary: "Forces the current session's local Premium availability stream to report true for UI gates, following 's localPremium behavior.",
            disabledBehavior: "Restores Telegram's original local Premium availability stream.",
            riskNote: "This is a local UI patch only. Server-side Premium entitlements, payments, boosts, and account state are unchanged.",
            supportedBuildNote: unsupportedBuild,
            replacements: [
                BinaryReplacement(
                    id: "data.peer_premium_value.restore_user_flag",
                    originalHex: "081c40f9e80b00f9280080521f2003d5",
                    patchedHex: "081c40f9e80b00f9081942b908390e53",
                    expectedOccurrences: 2,
                    mode: .normalize
                ),
                BinaryReplacement(
                    id: "main.session.premium_possible_value.user_flag",
                    originalHex: "081c40f9e80b00f9083140f9081942b908390e53",
                    patchedHex: "081c40f9e80b00f9083140f9280080521f2003d5",
                    expectedOccurrences: 2,
                    alternativeGroup: "main.session.premium_possible_value.user_flag"
                ),
                BinaryReplacement(
                    id: "main.session.premium_possible_value.config_false_to_user_flag",
                    originalHex: "081c40f9e80b00f9083140f9080080521f2003d5",
                    patchedHex: "081c40f9e80b00f9083140f9280080521f2003d5",
                    expectedOccurrences: 2,
                    alternativeGroup: "main.session.premium_possible_value.user_flag"
                )
            ]
        ),
        BinaryPatchRule(
            id: "binary.display.custom_ton",
            title: "Custom TON value",
            methodName: "CreditsAmountFromTL(MTPstarsTonAmount)",
            constructorId: "payments.getStarsTransactions#69da4557 / payments.StarsStatus.balance",
            kind: .overrideResponseValue,
            summary: "Overrides Telegram's local conversion of TON balances from payments.StarsStatus responses, including My TON and payments.getStarsTransactions results.",
            disabledBehavior: "Restores Telegram's original MTPstarsTonAmount to CreditsAmount conversion.",
            riskNote: "This is still a local display patch; it rewrites the decoded balance amount in the built app and does not change server-side TON data.",
            supportedBuildNote: unsupportedBuild,
            parameter: BinaryPatchParameter(
                title: "TON value",
                prompt: "Enter the TON amount to show in My TON and transaction status responses.",
                defaultValue: 999,
                minimumValue: 0,
                maximumValue: 9_000_000_000,
                unit: "TON"
            ),
            replacements: [
                BinaryReplacement(
                    id: "credits.amount_from_tl.ton.value",
                    originalHex: "e00500b4080840f909fd49d36a4a8bd26a13b4f2ea05d7f28a08e0f2297dca9b29fd4bd3eb3f9992ab8cb8f22c210b9b2d008052a90909aaed0308cbadfd49d3aa7dca9b4afd4bd34b7d0b9b0d4099524d73a7720b010beb6b010d8beb038b9a4d008092ad159f9aaa090acb1f0141f220018a9a81018b9afd7bc1a8c0035fd6",
                    patchedHex: "010080d2010080f20100a0f20100c0f2e1031faafd7bc1a8c0035fd61f2003d51f2003d51f2003d51f2003d51f2003d51f2003d51f2003d51f2003d51f2003d51f2003d51f2003d51f2003d51f2003d51f2003d51f2003d51f2003d51f2003d51f2003d51f2003d51f2003d51f2003d51f2003d51f2003d51f2003d51f2003d51f2003d51f2003d51f2003d5",
                    template: .creditsTonAmount
                )
            ]
        ),
        BinaryPatchRule(
            id: "binary.display.custom_stars",
            title: "Custom Stars value",
            methodName: "CreditsAmountFromTL(MTPstarsAmount)",
            constructorId: "payments.getStarsTransactions#69da4557 / payments.StarsStatus.balance",
            kind: .overrideResponseValue,
            summary: "Overrides Telegram's local conversion of Stars balances from payments.StarsStatus responses, including My Stars and payments.getStarsTransactions results.",
            disabledBehavior: "Restores Telegram's original MTPstarsAmount to CreditsAmount conversion.",
            riskNote: "This is still a local display patch; it rewrites the decoded balance amount in the built app and does not change server-side Stars data.",
            supportedBuildNote: unsupportedBuild,
            parameter: BinaryPatchParameter(
                title: "Stars value",
                prompt: "Enter the Stars amount to show in My Stars and transaction status responses.",
                defaultValue: 999,
                minimumValue: 0,
                maximumValue: 4_294_967_295,
                unit: "Stars"
            ),
            replacements: [
                BinaryReplacement(
                    id: "credits.amount_from_tl.stars.value",
                    originalHex: "200800b4080840f9011880b9e105f837e93f99524973a7723f00096be9060054297c09536a7089528a00a072297daa9b29fd67d3ea3f9992aa8cb8f221052a9b0801098b2d000014",
                    patchedHex: "000080d2000080f20000a0f20000c0f2010080d2fd7bc1a8c0035fd61f2003d51f2003d51f2003d51f2003d51f2003d51f2003d51f2003d51f2003d51f2003d51f2003d51f2003d51f2003d5",
                    template: .creditsStarsAmount
                )
            ]
        ),
        BinaryPatchRule(
            id: "binary.visual.peer_badge",
            title: "Visual peer badge",
            methodName: "UserData::setFlags / ChannelData::setFlags",
            constructorId: "local-peer-badge",
            kind: .visualBadge,
            summary: "Forces a local verification-status flag on peers. Choose Verified, Scam, or Fake, then apply it to all peers, all except your own user, or only your own user.",
            disabledBehavior: "Restores Telegram's original user/channel verification-status flags.",
            riskNote: "This rewrites local client peer flags only. Server-side account state and Telegram trust labels are unchanged.",
            supportedBuildNote: unsupportedBuild,
            parameter: BinaryPatchParameter(
                title: "Peer badge",
                prompt: "Choose the local peer badge and target mode to force.",
                defaultValue: 1,
                minimumValue: 1,
                maximumValue: 23,
                unit: "badge mode",
                choiceGroups: [
                    BinaryPatchParameterChoiceGroup(
                        title: "Mode",
                        choices: [
                            BinaryPatchParameterChoice(value: 0, label: "All"),
                            BinaryPatchParameterChoice(value: 10, label: "All except me"),
                            BinaryPatchParameterChoice(value: 20, label: "Only me")
                        ]
                    ),
                    BinaryPatchParameterChoiceGroup(
                        title: "Badge",
                        choices: [
                            BinaryPatchParameterChoice(value: 1, label: "Verified"),
                            BinaryPatchParameterChoice(value: 2, label: "Scam"),
                            BinaryPatchParameterChoice(value: 3, label: "Fake")
                        ]
                    )
                ]
            ),
            replacements: [
                BinaryReplacement(
                    id: "data.user.verification_status.force_verified.all",
                    originalHex: "297804121f0100f13701811a",
                    patchedHex: "29701a1229011d32f703092a",
                    alternativeGroup: "data.user.verification_status.force_badge",
                    enabledParameterValues: [1]
                ),
                BinaryReplacement(
                    id: "data.user.verification_status.force_scam.all",
                    originalHex: "297804121f0100f13701811a",
                    patchedHex: "29701a1229011c32f703092a",
                    alternativeGroup: "data.user.verification_status.force_badge",
                    enabledParameterValues: [2]
                ),
                BinaryReplacement(
                    id: "data.user.verification_status.force_fake.all",
                    originalHex: "297804121f0100f13701811a",
                    patchedHex: "29701a1229011b32f703092a",
                    alternativeGroup: "data.user.verification_status.force_badge",
                    enabledParameterValues: [3]
                ),
                BinaryReplacement(
                    id: "data.user.verification_status.force_verified.except_self",
                    originalHex: "297804121f0100f13701811a",
                    patchedHex: "3f00137237001d323710971a",
                    alternativeGroup: "data.user.verification_status.force_badge",
                    enabledParameterValues: [11]
                ),
                BinaryReplacement(
                    id: "data.user.verification_status.force_scam.except_self",
                    originalHex: "297804121f0100f13701811a",
                    patchedHex: "3f00137237001c323710971a",
                    alternativeGroup: "data.user.verification_status.force_badge",
                    enabledParameterValues: [12]
                ),
                BinaryReplacement(
                    id: "data.user.verification_status.force_fake.except_self",
                    originalHex: "297804121f0100f13701811a",
                    patchedHex: "3f00137237001b323710971a",
                    alternativeGroup: "data.user.verification_status.force_badge",
                    enabledParameterValues: [13]
                ),
                BinaryReplacement(
                    id: "data.user.verification_status.force_verified.only_self",
                    originalHex: "297804121f0100f13701811a",
                    patchedHex: "3f00137237001d32f712811a",
                    alternativeGroup: "data.user.verification_status.force_badge",
                    enabledParameterValues: [21]
                ),
                BinaryReplacement(
                    id: "data.user.verification_status.force_scam.only_self",
                    originalHex: "297804121f0100f13701811a",
                    patchedHex: "3f00137237001c32f712811a",
                    alternativeGroup: "data.user.verification_status.force_badge",
                    enabledParameterValues: [22]
                ),
                BinaryReplacement(
                    id: "data.user.verification_status.force_fake.only_self",
                    originalHex: "297804121f0100f13701811a",
                    patchedHex: "3f00137237001b32f712811a",
                    alternativeGroup: "data.user.verification_status.force_badge",
                    enabledParameterValues: [23]
                ),
                BinaryReplacement(
                    id: "data.channel.verification_status.force_verified",
                    originalHex: "09f968921f0159f21701899a",
                    patchedHex: "09f1779229017ab2f70309aa",
                    alternativeGroup: "data.channel.verification_status.force_badge",
                    enabledParameterValues: [1, 11]
                ),
                BinaryReplacement(
                    id: "data.channel.verification_status.force_scam",
                    originalHex: "09f968921f0159f21701899a",
                    patchedHex: "09f17792290179b2f70309aa",
                    alternativeGroup: "data.channel.verification_status.force_badge",
                    enabledParameterValues: [2, 12]
                ),
                BinaryReplacement(
                    id: "data.channel.verification_status.force_fake",
                    originalHex: "09f968921f0159f21701899a",
                    patchedHex: "09f17792290178b2f70309aa",
                    alternativeGroup: "data.channel.verification_status.force_badge",
                    enabledParameterValues: [3, 13]
                )
            ]
        ),
        BinaryPatchRule(
            id: "binary.visual.bot_verification",
            title: "Bot verification",
            methodName: "UserData::setBotVerifyDetails / ChannelData::setBotVerifyDetails",
            constructorId: "botVerification#f93cd45c",
            kind: .botVerification,
            summary: "Installs a local runtime hook for Telegram's bot verification details. Choose who receives the local bot verification and which preset to use.",
            disabledBehavior: "Removes the Patchgram runtime hook and restores Telegram's original executable entry point.",
            riskNote: "This is a local client-side runtime patch. It does not change Telegram server-side verification state.",
            supportedBuildNote: unsupportedBuild,
            replacements: []
        ),
        BinaryPatchRule(
            id: "binary.visual.custom_level_rating",
            title: "Custom level rating",
            methodName: "UserData::setStarsRating",
            constructorId: "starsRating#1f74f5c6 / userFull.stars_rating",
            kind: .customLevelRating,
            summary: "Installs a local runtime hook for Telegram's user Stars rating. Choose who receives the local rating and set level, rating, current_level_rating, and next_level_rating.",
            disabledBehavior: "Removes the Patchgram runtime hook and restores Telegram's original executable entry point when no other runtime patches are enabled.",
            riskNote: "This is a local client-side display patch. It does not change Telegram server-side Stars rating data.",
            supportedBuildNote: unsupportedBuild,
            replacements: []
        ),
        BinaryPatchRule(
            id: "binary.visual.hide_self_phone",
            title: "Hide self phone",
            methodName: "Info::Profile::PhoneOrHiddenValue",
            constructorId: "profile phone row",
            kind: .hideSelfPhone,
            summary: "Installs a local runtime hook that returns an empty profile phone value for your own user, causing Telegram Desktop to omit the mobile phone row in the self-profile.",
            disabledBehavior: "Keeps Telegram's original profile phone value handling.",
            riskNote: "This is a local client-side display patch. It does not change your Telegram account phone number or privacy settings.",
            supportedBuildNote: unsupportedBuild,
            replacements: []
        ),
        BinaryPatchRule(
            id: "binary.visual.self_identity_override",
            title: "Self identity override",
            methodName: "UserData::phone / local display user id",
            constructorId: "local self identity",
            kind: .selfIdentityOverride,
            summary: "Installs a local runtime hook that overrides the phone string stored on your own UserData and provides a local display-only user id for Patchgram visual details.",
            disabledBehavior: "Keeps Telegram's original self phone and user id display values.",
            riskNote: "This is a local client-side display patch. It does not change your Telegram account phone, real PeerId, authorization, or server state.",
            supportedBuildNote: unsupportedBuild,
            replacements: []
        ),
        BinaryPatchRule(
            id: "binary.visual.local_personal_channel",
            title: "Local attached channel",
            methodName: "UserData::personalChannelId",
            constructorId: "local-personal-channel",
            kind: .localPersonalChannel,
            summary: "Installs a local runtime hook that writes a display-only personal channel id into your own UserData so Telegram Desktop shows it as attached in the self-profile.",
            disabledBehavior: "Keeps Telegram's original personal channel value.",
            riskNote: "This is a local client-side display patch. It does not attach a channel to your Telegram account or change server-side profile data.",
            supportedBuildNote: unsupportedBuild,
            replacements: []
        ),
        BinaryPatchRule(
            id: "binary.visual.fragment_phone",
            title: "Fragment phone",
            methodName: "Info::Profile::IsCollectiblePhone / fragment.getCollectibleInfo",
            constructorId: "fragment.getCollectibleInfo#be1e85ba / fragment.collectibleInfo#6ebdff91",
            kind: .fragmentPhone,
            summary: "Installs a local runtime hook that makes selected phone rows look collectible and stores local fragment.collectibleInfo values for the phone collectible dialog.",
            disabledBehavior: "Keeps Telegram's original Fragment phone collectible detection and response data.",
            riskNote: "This is a local client-side display patch. It does not mint or transfer a Fragment collectible phone number.",
            supportedBuildNote: unsupportedBuild,
            replacements: []
        ),
        BinaryPatchRule(
            id: "binary.gifts.spoof_profile",
            title: "Spoof profile gifts",
            methodName: "payments.getSavedStarGifts / payments.savedStarGifts",
            constructorId: "payments.savedStarGifts#95f389b1 / savedStarGift#41df43fc",
            kind: .starGiftSpoof,
            summary: "Installs a local runtime hook that rewrites the saved star gifts in the payments.savedStarGifts response before Telegram reads it, so a profile's gifts show the sender, date, gift id and Stars price you configure. Each value is optional (0 = leave the original).",
            disabledBehavior: "Keeps Telegram's original star gifts and their data.",
            riskNote: "This is a local client-side display patch on the gift list response. It does not move, mint or change any gift server-side; only what your client displays changes.",
            supportedBuildNote: "Hooks the MTProto gift-list response and rewrites it with the in-dylib TL walker, so it is independent of byte-level signatures across Telegram builds.",
            replacements: []
        ),
        BinaryPatchRule(
            id: "binary.gifts.show_hidden",
            title: "Show hidden gifts",
            methodName: "payments.getStarGifts / payments.starGifts",
            constructorId: "payments.getStarGifts#c4563590 / payments.starGifts#2ed82995",
            kind: .showHiddenGifts,
            summary: "Installs a local runtime hook that appends extra star gifts (price 50 Stars, not limited) to the payments.starGifts response, so they appear in the gift purchase menu. Their stickers use the matching custom emoji (resolved from api.changes.tg).",
            disabledBehavior: "Shows only the gifts Telegram returns.",
            riskNote: "Local client-side display patch on the available-gifts response. The extra gifts are shown locally; buying a gift that the server doesn't actually offer will still fail server-side.",
            supportedBuildNote: "Hooks the MTProto available-gifts response and appends entries with the in-dylib TL walker, independent of byte-level signatures.",
            replacements: []
        ),
        BinaryPatchRule(
            id: "binary.visual.custom_list_usernames",
            title: "Custom list usernames",
            methodName: "Data::UsernamesInfo / fragment.getCollectibleInfo",
            constructorId: "inputCollectibleUsername#e39460a9 / fragment.collectibleInfo#6ebdff91",
            kind: .customListUsernames,
            summary: "Installs a local runtime hook that replaces the usernames list shown for your self-profile and returns local Fragment collectible info for configured collectible usernames.",
            disabledBehavior: "Keeps Telegram's original self-profile usernames and Fragment username collectible response data.",
            riskNote: "This is a local client-side display patch. It does not reserve, mint, buy, or assign Telegram usernames on the server.",
            supportedBuildNote: unsupportedBuild,
            replacements: []
        ),
        BinaryPatchRule(
            id: "binary.visual.no_premium_anim",
            title: "Disable premium effects",
            methodName: "HistoryView::Sticker::checkPremiumEffectStart",
            constructorId: "local-premium-effects",
            kind: .runtimeMemory,
            summary: "Installs a runtime memory patch that returns from Sticker::checkPremiumEffectStart before Telegram can start premium sticker effects.",
            disabledBehavior: "Keeps Telegram's original premium sticker effect start behavior.",
            riskNote: "This is a local visual patch. It does not change sticker, Premium, or account state on Telegram servers.",
            supportedBuildNote: unsupportedBuild,
            replacements: [
                BinaryReplacement(
                    id: "history.sticker.premium_effect_start.return",
                    originalHex: "fd7bbfa9fd03009108504978490280521f01096a60000054fd7bc1a8c0035fd6090c40f92a5144798aff4f362a1d40b95f0d007121ffff54291141f9e9feffb4",
                    patchedHex: "c0035fd6fd03009108504978490280521f01096a60000054fd7bc1a8c0035fd6090c40f92a5144798aff4f362a1d40b95f0d007121ffff54291141f9e9feffb4"
                )
            ]
        ),
        BinaryPatchRule(
            id: "binary.visual.disable_spoilers",
            title: "Disable media spoilers",
            methodName: "Data::CreateMedia / HistoryView media spoilers",
            constructorId: "media spoiler flags",
            kind: .runtimeMemory,
            summary: "Installs runtime memory patches that suppress local media spoiler flags and rendering, so spoiler-marked photos and videos are shown normally.",
            disabledBehavior: "Keeps Telegram's original media spoiler behavior.",
            riskNote: "This is a local client-side media display patch. It does not change spoiler metadata already stored on Telegram servers.",
            supportedBuildNote: unsupportedBuild,
            replacements: [
                BinaryReplacement(
                    id: "api.message_entity_spoiler.parse.skip",
                    originalHex: "e00319aae1031aaa821904f042b43a9183028052240080525ecf9397400b0034",
                    patchedHex: "e00319aae1031aaa821904f042b43a9183028052240080525ecf93971f2003d5",
                    alternativeGroup: "spoilers.text.parse.disable"
                ),
                // 6.9.0: the messageEntitySpoiler cstring copy used by parse moved
                // (adrp+add shifted); the comparison/skip structure is unchanged.
                BinaryReplacement(
                    id: "api.message_entity_spoiler.parse.skip.v690",
                    originalHex: "e00319aae1031aaae21e04d042e80c918302805224008052848c9397400b0034",
                    patchedHex: "e00319aae1031aaae21e04d042e80c918302805224008052848c93971f2003d5",
                    alternativeGroup: "spoilers.text.parse.disable"
                ),
                BinaryReplacement(
                    id: "api.message_entity_spoiler.parse.skip.v691",
                    originalHex: "e00319aae1031aaa821e04f042a80d918302805224008052848c9397400b0034",
                    patchedHex: "e00319aae1031aaa821e04f042a80d918302805224008052848c93971f2003d5",
                    expectedOccurrences: 1,
                    alternativeGroup: "spoilers.text.parse.disable"
                ),
                BinaryReplacement(
                    id: "api.message_entity_spoiler.serialize.force_unknown",
                    originalHex: "48008052e8bb00f9e0a30391e2830591a11904b021b43a911c040094",
                    patchedHex: "e8031f2ae8bb00f9e0a30391e2830591a11904b021b43a911c040094",
                    alternativeGroup: "spoilers.text.serialize.disable"
                ),
                // 6.9.0: serialize structure identical, only the adrp+add to the moved
                // cstring shifted; patch still forces the entity type to 0 (mov w8, wzr).
                BinaryReplacement(
                    id: "api.message_entity_spoiler.serialize.force_unknown.v690",
                    originalHex: "48008052e8bb00f9e0a30391e2830591011f04b021e80c911c040094",
                    patchedHex: "e8031f2ae8bb00f9e0a30391e2830591011f04b021e80c911c040094",
                    alternativeGroup: "spoilers.text.serialize.disable"
                ),
                BinaryReplacement(
                    id: "api.message_entity_spoiler.serialize.force_unknown.v691",
                    originalHex: "48008052e8bb00f9e0a30391e2830591a11e04d021a80d911c040094",
                    patchedHex: "e8031f2ae8bb00f9e0a30391e2830591a11e04d021a80d911c040094",
                    expectedOccurrences: 1,
                    alternativeGroup: "spoilers.text.serialize.disable"
                ),
                BinaryReplacement(
                    id: "data.create_media.photo_spoiler_flag.force_false",
                    originalHex: "4c640595f62b00b4f50300aa630e0353e10314aae20316aa",
                    patchedHex: "4c640595f62b00b4f50300aa03008052e10314aae20316aa",
                    maskHex: "000000ffffffffffffffffffffffffffffffffffffffffff",
                    alternativeGroup: "spoilers.media.create.photo.disable"
                ),
                BinaryReplacement(
                    id: "data.create_media.document_spoiler_flag.force_false",
                    // FIX: messageMediaDocument spoiler is flags.4 (bit 4), not flags.3 (that's
                    // nopremium). The old patch zeroed bit 3 — copied from the photo patch where
                    // spoiler IS flags.3 — so document/video spoilers were never cleared. Now zero
                    // the bit-4 extraction (ubfx w8,w8,#4,#1 -> mov w8,#0). Bytes are identical on
                    // 6.8.5/6.9.0; the schema bit is stable, so this corrects both builds.
                    originalHex: "3f0100f1e9079f1ae9530339090d0353e957033908110453",
                    patchedHex: "3f0100f1e9079f1ae9530339090d0353e957033908008052",
                    alternativeGroup: "spoilers.media.create.document.disable"
                ),
                BinaryReplacement(
                    id: "history.media_spoiler.skip.first",
                    originalHex: "230d0094a87249391f050071a1460054f49742f9c15802b021003691",
                    patchedHex: "230d0094a87249391f05007135020014f49742f9c15802b021003691",
                    maskHex: "ffffffffffffffffffffffffffffffffffffffff0000ff00ff0000ff",
                    alternativeGroup: "spoilers.media.skip.first"
                ),
                BinaryReplacement(
                    id: "history.media_spoiler.skip.second",
                    originalHex: "a81243391f05007101030054f49742f9c158029021003691e0431391",
                    patchedHex: "a81243391f05007118000014f49742f9c158029021003691e0431391",
                    maskHex: "ffffffffffffffffffffffffffffffff0000ff00ff0000ffffffffff",
                    alternativeGroup: "spoilers.media.skip.second"
                ),
                BinaryReplacement(
                    id: "history.media_spoiler.skip.third",
                    originalHex: "680a46391f05007121030054880a40f9130140f9815802d021003691",
                    patchedHex: "680a46391f05007119000014880a40f9130140f9815802d021003691",
                    maskHex: "ffffffffffffffffffffffffffffffffffffffff0000ff00ff0000ff",
                    alternativeGroup: "spoilers.media.skip.third"
                ),
                BinaryReplacement(
                    id: "history.media_spoiler.skip.fourth",
                    originalHex: "683240391f050071815e0054a80e40f9130140f9415802b021003691",
                    patchedHex: "683240391f050071f4020014a80e40f9130140f9415802b021003691",
                    maskHex: "ffffffffffffffffffffffffffffffffffffffff0000ff00ff0000ff",
                    alternativeGroup: "spoilers.media.skip.fourth"
                ),
            ]
        ),
        BinaryPatchRule(
            id: "binary.messages.scheduled_send",
            title: "Scheduled send",
            methodName: "local scheduled send setting",
            constructorId: "local-useScheduledMessages",
            kind: .runtimeMemory,
            summary: "Adds a Patchgram runtime flag for local scheduled sending, intended to schedule outgoing messages locally instead of sending them immediately.",
            disabledBehavior: "Keeps Telegram's original immediate-send behavior.",
            riskNote: "This is a local client-side runtime feature controlled by Patchgram's scheduled-send setting.",
            supportedBuildNote: unsupportedBuild,
            replacements: []
        ),
        BinaryPatchRule(
            id: "binary.visual.sensitive_blur",
            title: "Sensitive blur",
            methodName: "Data::UnavailableReason::IgnoreSensitiveMark / HistoryItem::isMediaSensitive",
            constructorId: "sensitive-content",
            kind: .runtimeMemory,
            summary: "Installs a runtime memory patch for local sensitive-content blur suppression, forcing media sensitivity checks to return false locally.",
            disabledBehavior: "Keeps Telegram's original sensitive media blur behavior.",
            riskNote: "This is a local display behavior change. It does not change Telegram server-side content metadata.",
            supportedBuildNote: unsupportedBuild,
            replacements: [
                BinaryReplacement(
                    id: "history.item.is_media_sensitive.force_false",
                    originalHex: "ff8301d1f44f04a9fd7b05a9fd430191f30300aa091440f9080840f9c90078b7",
                    patchedHex: "00008052c0035fd61f2003d51f2003d51f2003d51f2003d51f2003d51f2003d5"
                )
            ]
        ),
        // Raises kRecentDisplayLimit (StickersListWidget::collectRecentStickers) from 20 to 200 so
        // the Recent row shows many more recently-used stickers (the same cap AyuGram lifts). The
        // signature is the size()>=20 site (sub/asr#5/×(1/3) magic/cmp x10,#0x14); only the cmp
        // immediate changes (0x14 → 0xc8). Runtime memory patch — no Telegram file bytes on disk.
        BinaryPatchRule(
            id: "binary.stickers.recent_limit",
            title: "More recent stickers",
            methodName: "StickersListWidget::collectRecentStickers (kRecentDisplayLimit)",
            constructorId: "recent-stickers-limit",
            kind: .runtimeMemory,
            summary: "Raises the recent stickers display limit from Telegram's default 20 to 200, so the \"Recent\" row in the sticker panel shows many more recently-used stickers. Runtime memory patch on the kRecentDisplayLimit comparison in StickersListWidget::collectRecentStickers.",
            disabledBehavior: "Restores Telegram's default limit of 20 recent stickers in the panel.",
            riskNote: "Local display-only change to the in-panel recent-sticker cap; it does not change server data. The number actually shown is still bounded by how many recent stickers exist (server limit ~200).",
            supportedBuildNote: "Derived from Telegram Desktop 6.9.3 (arm64). Other builds are patched only when the exact byte pattern matches.",
            replacements: [
                BinaryReplacement(
                    id: "stickers.recent_display_limit.raise_to_200",
                    originalHex: "2a0108cb4afd4593ebf301b26b5595f24a7d0b9b5f5100f1",
                    patchedHex: "2a0108cb4afd4593ebf301b26b5595f24a7d0b9b5f2103f1"
                )
            ],
            delivery: .runtimeMemory
        ),
        BinaryPatchRule(
            id: "binary.stories.hide",
            title: "Hide stories",
            methodName: "stories.* / PeerData::setStoriesState",
            constructorId: "stories",
            kind: .poisonConstructor,
            summary: "Clears local stories state on users/channels and invalidates the known story fetch/read/view request constructors.",
            disabledBehavior: "Restores Telegram's original stories state handling and request constructor ids.",
            riskNote: "This blocks the known local receive/fetch paths for stories in the selected ARM64 build. Telegram may add new story request paths in future builds.",
            supportedBuildNote: unsupportedBuild,
            replacements: [
                BinaryReplacement(
                    id: "data.user.stories_state.force_none",
                    originalHex: "141842b93f0800716c010054",
                    patchedHex: "141842b9210080521f2003d5"
                ),
                BinaryReplacement(
                    id: "data.peer.stories_state.force_none",
                    originalHex: "74f640f93f080071ac010054",
                    patchedHex: "74f640f9210080521f2003d5"
                ),
                BinaryReplacement(
                    id: "stories.getAllStories.constructor",
                    originalHex: "a8c49a5208d6bd72e85700b9",
                    patchedHex: "08608052a8d5bb72e85700b9"
                ),
                BinaryReplacement(
                    id: "stories.getPinnedStories.constructor",
                    originalHex: "88bb94522804ab72e82f00b9",
                    patchedHex: "28608052a8d5bb72e82f00b9"
                ),
                BinaryReplacement(
                    id: "stories.getStoriesArchive.constructor",
                    originalHex: "c8028452a886b672e82f00b9",
                    patchedHex: "48608052a8d5bb72e82f00b9"
                ),
                BinaryReplacement(
                    id: "stories.getStoriesByID.constructor",
                    originalHex: "884e995288eeaa72e81700b9",
                    patchedHex: "68608052a8d5bb72e81700b9"
                ),
                BinaryReplacement(
                    id: "stories.readStories.constructor",
                    originalHex: "08599b52c8aab472",
                    patchedHex: "88608052a8d5bb72"
                ),
                BinaryReplacement(
                    id: "stories.incrementStoryViews.constructor",
                    originalHex: "685f91524840b672",
                    patchedHex: "a8608052a8d5bb72"
                ),
                BinaryReplacement(
                    id: "stories.getStoryViewsList.constructor",
                    originalHex: "e88a875248daaf72e85f00b9",
                    patchedHex: "c8608052a8d5bb72e85f00b9"
                ),
                BinaryReplacement(
                    id: "stories.getStoriesViews.constructor",
                    originalHex: "08998d52281ca572e85f00b9",
                    patchedHex: "e8608052a8d5bb72e85f00b9"
                ),
                BinaryReplacement(
                    id: "stories.getPeerStories.constructor",
                    originalHex: "084a9b524889a572e82f00b9",
                    patchedHex: "08618052a8d5bb72e82f00b9"
                ),
                BinaryReplacement(
                    id: "stories.getAllReadPeerStories.constructor",
                    originalHex: "28ff9c52486bb372",
                    patchedHex: "28618052a8d5bb72"
                ),
                BinaryReplacement(
                    id: "stories.getPeerMaxIDs.constructor",
                    originalHex: "092e92522909af72",
                    patchedHex: "c9618052a9d5bb72"
                ),
                // 6.9.0: same magic 0x78499170, just loaded into w10 instead of w9.
                BinaryReplacement(
                    id: "stories.getPeerMaxIDs.constructor.v690",
                    originalHex: "0a2e92522a09af72",
                    patchedHex: "ca618052aad5bb72"
                ),
                BinaryReplacement(
                    id: "stories.getChatsToSend.constructor",
                    originalHex: "086c915248adb472",
                    patchedHex: "48618052a8d5bb72"
                ),
                BinaryReplacement(
                    id: "stories.getStoryReactionsList.constructor",
                    originalHex: "e80391524836b772e8c700b9",
                    patchedHex: "68618052a8d5bb72e8c700b9"
                ),
                BinaryReplacement(
                    id: "stories.searchPosts.constructor",
                    originalHex: "e82081522830ba72",
                    patchedHex: "e8618052a8d5bb72"
                ),
                BinaryReplacement(
                    id: "stories.getAlbums.constructor",
                    originalHex: "e8589d5268b6a472e82f00b9",
                    patchedHex: "88618052a8d5bb72e82f00b9"
                ),
                BinaryReplacement(
                    id: "stories.getAlbumStories.constructor",
                    originalHex: "28ac8d520890b572e82f00b9",
                    patchedHex: "a8618052a8d5bb72e82f00b9"
                )
            ]
        ),
        BinaryPatchRule(
            id: "binary.ads.disable_sponsored",
            title: "Disable ads",
            methodName: "messages.getSponsoredMessages",
            constructorId: "3d6ce850",
            kind: .poisonConstructor,
            summary: "Disables Telegram Ads and proxy sponsor promotion surfaces.",
            disabledBehavior: "Restores Telegram Ads and proxy sponsor promotion behavior.",
            riskNote: "Telegram Ads are blocked through the sponsored-message request path. Proxy sponsor is handled as a separate top-promotion surface and may need a new byte window if Telegram changes its promo flow.",
            supportedBuildNote: unsupportedBuild,
            replacements: [
                BinaryReplacement(
                    id: "messages.getSponsoredMessages.constructor",
                    originalHex: "080a9d5288ada772",
                    patchedHex: "2800905208c0b772",
                    alternativeGroup: "ads.telegram_ads.disable"
                ),
                BinaryReplacement(
                    id: "help.getPromoData.schema",
                    originalHex: "7b2068656c705f67657450726f6d6f44617461207d",
                    patchedHex: "7b2068656c705f6e6f50726f6d6f4461746121207d",
                    alternativeGroup: "ads.proxy_sponsor.schema"
                ),
                BinaryReplacement(
                    id: "help.getPromoData.constructor",
                    originalHex: "28848e52e812b872",
                    patchedHex: "280180522800be72",
                    alternativeGroup: "ads.proxy_sponsor.constructor"
                )
            ]
        )
    ]

    /// The bundled catalog, with each rule stamped with its UI section from `category(forRuleId:)`.
    public static let builtInRules: [BinaryPatchRule] = rawBuiltInRules.map { $0.withCategory(category(forRuleId: $0.id)) }

    /// Section membership for the BUILT-IN rules. `patches.json` carries the same per-rule `category`
    /// so a fetched update can categorize NEW patches with no app change; this only keeps the bundled
    /// seed in sync with the (categorized) bundled patches.json. Unlisted ids fall back to `.misc`.
    static func category(forRuleId id: String) -> BinaryPatchCategory {
        switch id {
        case "binary.presence.force_offline", "binary.accounts.limit_999", "binary.visual.hide_self_phone",
             "binary.account.custom_settings", "binary.activity.block_typing", "binary.privacy.no_phone_on_add",
             "binary.premium.local", "binary.display.custom_ton", "binary.display.custom_stars",
             "binary.visual.peer_badge", "binary.visual.bot_verification", "binary.visual.custom_level_rating",
             "binary.visual.self_identity_override", "binary.visual.local_personal_channel",
             "binary.visual.fragment_phone", "binary.visual.custom_list_usernames":
            return .accounts
        case "binary.messages.settings", "binary.inline.callback_hover", "binary.visual.sensitive_blur",
             "binary.links.open_without_warning", "binary.visual.disable_spoilers",
             "binary.read_receipts.block_history_read", "binary.messages.scheduled_send",
             "binary.stickers.recent_limit":
            return .messages
        case "binary.config.disable_monetization", "binary.visual.no_premium_anim",
             "binary.stories.hide", "binary.ads.disable_sponsored":
            return .optimizations
        case "binary.gifts.spoof_profile", "binary.gifts.show_hidden":
            return .gifts
        default:
            return .misc
        }
    }

    public static func rules(withIds ids: [String]) -> [BinaryPatchRule] {
        // Resolve against the loaded catalog (patches.json) so modules reflect fetched updates.
        let rulesById = Dictionary(BinaryPatchRuleCatalog.rules.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return ids.compactMap { rulesById[$0] }
    }
}

extension Data {
    init(hexString: String) {
        let compact = hexString.filter { !$0.isWhitespace }
        precondition(compact.count.isMultiple(of: 2), "Hex strings must contain full bytes.")
        var bytes: [UInt8] = []
        bytes.reserveCapacity(compact.count / 2)
        var index = compact.startIndex
        while index < compact.endIndex {
            let next = compact.index(index, offsetBy: 2)
            let byte = UInt8(compact[index..<next], radix: 16) ?? 0
            bytes.append(byte)
            index = next
        }
        self = Data(bytes)
    }

    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Codable (externalized patch catalog)

extension BinaryPatchParameterChoice: Codable {}
extension BinaryPatchParameterChoiceGroup: Codable {}
extension BinaryPatchParameter: Codable {}
extension BinaryPatchRule: Codable {}

extension BinaryReplacement: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, originalHex, patchedHex, maskHex, expectedOccurrences, mode, alternativeGroup, template, enabledParameterValues
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try c.decode(String.self, forKey: .id),
            originalHex: try c.decode(String.self, forKey: .originalHex),
            patchedHex: try c.decode(String.self, forKey: .patchedHex),
            maskHex: try c.decodeIfPresent(String.self, forKey: .maskHex),
            expectedOccurrences: try c.decodeIfPresent(Int.self, forKey: .expectedOccurrences) ?? 1,
            mode: try c.decodeIfPresent(BinaryReplacementMode.self, forKey: .mode) ?? .toggle,
            alternativeGroup: try c.decodeIfPresent(String.self, forKey: .alternativeGroup),
            template: try c.decodeIfPresent(BinaryPatchTemplate.self, forKey: .template),
            enabledParameterValues: try c.decodeIfPresent([UInt64].self, forKey: .enabledParameterValues)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(original.hexString, forKey: .originalHex)
        // Encode the STORED patched bytes (fixedPatched), never the template-rendered `patched`,
        // so template replacements round-trip to their template instead of a baked default value.
        try c.encode(fixedPatched.hexString, forKey: .patchedHex)
        try c.encodeIfPresent(originalMask?.hexString, forKey: .maskHex)
        try c.encode(expectedOccurrences, forKey: .expectedOccurrences)
        try c.encode(mode, forKey: .mode)
        try c.encode(alternativeGroup, forKey: .alternativeGroup)
        try c.encodeIfPresent(template, forKey: .template)
        try c.encodeIfPresent(enabledParameterValues.map { $0.sorted() }, forKey: .enabledParameterValues)
    }
}
