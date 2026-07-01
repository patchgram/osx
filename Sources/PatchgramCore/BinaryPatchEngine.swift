import Foundation
import CryptoKit

public struct AppInspection: Hashable, Sendable {
    public let appURL: URL
    public let executableURL: URL
    public let bundleIdentifier: String
    public let bundleVersion: String
    public let executableSize: UInt64

    public init(
        appURL: URL,
        executableURL: URL,
        bundleIdentifier: String,
        bundleVersion: String,
        executableSize: UInt64
    ) {
        self.appURL = appURL
        self.executableURL = executableURL
        self.bundleIdentifier = bundleIdentifier
        self.bundleVersion = bundleVersion
        self.executableSize = executableSize
    }
}

public struct BinaryRuleStatus: Identifiable, Hashable, Sendable {
    public var id: String { rule.id }
    public let rule: BinaryPatchRule
    public let state: RuleApplicationState
    public let detail: String
    /// True when this rule is applied but its definition changed since (e.g. a fetched patch update);
    /// the row should offer "Update" to re-apply the new definition cleanly.
    public let definitionChanged: Bool

    public init(rule: BinaryPatchRule, state: RuleApplicationState, detail: String, definitionChanged: Bool = false) {
        self.rule = rule
        self.state = state
        self.detail = detail
        self.definitionChanged = definitionChanged
    }
}

public struct BinaryPatchApplicationReport: Hashable, Sendable {
    public let changedExecutable: Bool
    public let messages: [String]

    public init(changedExecutable: Bool, messages: [String]) {
        self.changedExecutable = changedExecutable
        self.messages = messages
    }
}

private struct RuntimeHookSyncResult {
    let changed: Bool
    let changedExecutable: Bool
}

private struct BinaryPatchManifest: Codable {
    var updatedAt: Date
    var enabledRuleIds: [String]
    var parameterValues: [String: UInt64] = [:]
    var botVerificationConfigs: [String: BotVerificationPatchConfig] = [:]
    var customLevelRatingConfigs: [String: CustomLevelRatingPatchConfig] = [:]
    var selfIdentityConfigs: [String: SelfIdentityPatchConfig] = [:]
    var localPersonalChannelConfigs: [String: LocalPersonalChannelPatchConfig] = [:]
    var fragmentPhoneConfigs: [String: FragmentPhonePatchConfig] = [:]
    var customListUsernamesConfigs: [String: CustomListUsernamesPatchConfig] = [:]
    var messageFactCheckConfigs: [String: MessageFactCheckPatchConfig] = [:]
    var starGiftSpoofConfig: StarGiftSpoofPatchConfig? = nil
    var starGiftUniqueSpoofConfig: StarGiftUniqueSpoofPatchConfig? = nil
    var enabledAlternativeGroups: [String: [String]] = [:]
    /// ruleId → definitionDigest at the time it was applied; lets a rescan detect that a fetched
    /// update changed an enabled rule's definition and surface a per-patch "Update".
    var appliedDefinitionHashes: [String: String] = [:]

    init(
        updatedAt: Date,
        enabledRuleIds: [String],
        parameterValues: [String: UInt64] = [:],
        botVerificationConfigs: [String: BotVerificationPatchConfig] = [:],
        customLevelRatingConfigs: [String: CustomLevelRatingPatchConfig] = [:],
        selfIdentityConfigs: [String: SelfIdentityPatchConfig] = [:],
        localPersonalChannelConfigs: [String: LocalPersonalChannelPatchConfig] = [:],
        fragmentPhoneConfigs: [String: FragmentPhonePatchConfig] = [:],
        customListUsernamesConfigs: [String: CustomListUsernamesPatchConfig] = [:],
        messageFactCheckConfigs: [String: MessageFactCheckPatchConfig] = [:],
        starGiftSpoofConfig: StarGiftSpoofPatchConfig? = nil,
        starGiftUniqueSpoofConfig: StarGiftUniqueSpoofPatchConfig? = nil,
        enabledAlternativeGroups: [String: [String]] = [:],
        appliedDefinitionHashes: [String: String] = [:]
    ) {
        self.appliedDefinitionHashes = appliedDefinitionHashes
        self.starGiftSpoofConfig = starGiftSpoofConfig
        self.starGiftUniqueSpoofConfig = starGiftUniqueSpoofConfig
        self.updatedAt = updatedAt
        self.enabledRuleIds = enabledRuleIds
        self.parameterValues = parameterValues
        self.botVerificationConfigs = botVerificationConfigs
        self.customLevelRatingConfigs = customLevelRatingConfigs
        self.selfIdentityConfigs = selfIdentityConfigs
        self.localPersonalChannelConfigs = localPersonalChannelConfigs
        self.fragmentPhoneConfigs = fragmentPhoneConfigs
        self.customListUsernamesConfigs = customListUsernamesConfigs
        self.messageFactCheckConfigs = messageFactCheckConfigs
        self.enabledAlternativeGroups = enabledAlternativeGroups
    }

    private enum CodingKeys: String, CodingKey {
        case updatedAt
        case enabledRuleIds
        case parameterValues
        case botVerificationConfigs
        case customLevelRatingConfigs
        case selfIdentityConfigs
        case localPersonalChannelConfigs
        case fragmentPhoneConfigs
        case customListUsernamesConfigs
        case messageFactCheckConfigs
        case starGiftSpoofConfig
        case starGiftUniqueSpoofConfig
        case enabledAlternativeGroups
        case appliedDefinitionHashes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        enabledRuleIds = try container.decode([String].self, forKey: .enabledRuleIds)
        parameterValues = try container.decodeIfPresent([String: UInt64].self, forKey: .parameterValues) ?? [:]
        botVerificationConfigs = try container.decodeIfPresent(
            [String: BotVerificationPatchConfig].self,
            forKey: .botVerificationConfigs
        ) ?? [:]
        customLevelRatingConfigs = try container.decodeIfPresent(
            [String: CustomLevelRatingPatchConfig].self,
            forKey: .customLevelRatingConfigs
        ) ?? [:]
        selfIdentityConfigs = try container.decodeIfPresent(
            [String: SelfIdentityPatchConfig].self,
            forKey: .selfIdentityConfigs
        ) ?? [:]
        localPersonalChannelConfigs = try container.decodeIfPresent(
            [String: LocalPersonalChannelPatchConfig].self,
            forKey: .localPersonalChannelConfigs
        ) ?? [:]
        fragmentPhoneConfigs = try container.decodeIfPresent(
            [String: FragmentPhonePatchConfig].self,
            forKey: .fragmentPhoneConfigs
        ) ?? [:]
        customListUsernamesConfigs = try container.decodeIfPresent(
            [String: CustomListUsernamesPatchConfig].self,
            forKey: .customListUsernamesConfigs
        ) ?? [:]
        messageFactCheckConfigs = try container.decodeIfPresent(
            [String: MessageFactCheckPatchConfig].self,
            forKey: .messageFactCheckConfigs
        ) ?? [:]
        starGiftSpoofConfig = try container.decodeIfPresent(
            StarGiftSpoofPatchConfig.self,
            forKey: .starGiftSpoofConfig
        )
        starGiftUniqueSpoofConfig = try container.decodeIfPresent(
            StarGiftUniqueSpoofPatchConfig.self,
            forKey: .starGiftUniqueSpoofConfig
        )
        enabledAlternativeGroups = try container.decodeIfPresent(
            [String: [String]].self,
            forKey: .enabledAlternativeGroups
        ) ?? [:]
        appliedDefinitionHashes = try container.decodeIfPresent(
            [String: String].self,
            forKey: .appliedDefinitionHashes
        ) ?? [:]
    }
}

private struct PatchgramRuntimeConfigFile: Codable {
    let version: Int
    let enabledRuleIds: [String]
    let enabledAlternativeGroups: [String: [String]]
    let parameterValues: [String: UInt64]
    let botVerificationEnabled: Bool
    let botVerificationTargetMode: BotVerificationTargetMode
    let botVerificationCustomEmojiId: UInt64
    let botVerificationDescription: String
    let customLevelRatingEnabled: Bool
    let customLevelRatingTargetMode: BotVerificationTargetMode
    let customLevelRatingLevel: Int32
    let customLevelRatingRating: Int32
    let customLevelRatingCurrentLevelRating: Int32
    let customLevelRatingNextLevelRating: Int32
    let hideSelfPhoneEnabled: Bool
    let selfIdentityOverrideEnabled: Bool
    let customPhoneNumberEnabled: Bool
    let customPhoneNumberTargetMode: BotVerificationTargetMode
    let customUserIdEnabled: Bool
    let customUserIdTargetMode: BotVerificationTargetMode
    let selfIdentityOverridePhone: String
    let selfIdentityOverrideUserId: String
    let localPersonalChannelEnabled: Bool
    let localPersonalChannelTargetMode: BotVerificationTargetMode
    let localPersonalChannelReference: String
    let localPersonalChannelId: UInt64
    let localPersonalChannelMessageId: Int32
    let fragmentPhoneEnabled: Bool
    let fragmentPhoneTargetMode: BotVerificationTargetMode
    let fragmentPhonePurchaseDate: Int32
    let fragmentPhoneCurrency: String
    let fragmentPhoneAmount: Int64
    let fragmentPhoneCryptoCurrency: String
    let fragmentPhoneCryptoAmount: Int64
    let fragmentPhoneUrl: String
    let giftSpoofEnabled: Bool
    let giftSpoofTargetMode: BotVerificationTargetMode
    let giftSpoofSenderId: Int64
    let giftSpoofSenderPeerType: Int32
    let giftSpoofDate: Int32
    let giftSpoofGiftId: Int64
    let giftSpoofStickerId: Int64
    let giftSpoofStars: Int64
    let giftSpoofConvertStars: Int64
    let giftSpoofCaption: String
    let giftSpoofAvailable: Int32
    let giftSpoofTotal: Int32
    let giftSpoofLimited: Bool
    let giftSpoofUpgrade: Bool
    let giftSpoofAuction: Bool
    let giftSpoofUpgradePrice: Int64
    let giftSpoofAuctionTitle: String
    let giftSpoofGiftNum: Int32
    let giftSpoofWasRefunded: Bool
    let giftFakeTransferEnabled: Bool
    let giftUniqueEnabled: Bool
    let giftUniqueTargetMode: BotVerificationTargetMode
    let giftUniqueGiftName: String
    let giftUniqueTitle: String
    let giftUniqueNum: Int32
    let giftUniqueHasBackdrop: Bool
    let giftUniqueBackdropName: String
    let giftUniqueBackdropCenter: Int32
    let giftUniqueBackdropEdge: Int32
    let giftUniqueBackdropPattern: Int32
    let giftUniqueBackdropText: Int32
    let giftUniqueBackdropRarity: Int32
    let giftUniqueModelName: String
    let giftUniqueModelEmojiId: Int64
    let giftUniqueModelRarity: Int32
    let giftUniqueSymbolName: String
    let giftUniqueSymbolEmojiId: Int64
    let giftUniqueSymbolRarity: Int32
    let giftUniqueTotalUpgraded: Int32
    let giftUniqueMaxUpgraded: Int32
    let giftUniqueDate: Int32
    let giftUniqueSenderId: Int64
    let giftUniqueSenderPeerType: Int32
    let giftUniqueOwnerId: Int64
    let giftUniqueOwnerPeerType: Int32
    let giftUniqueHostId: Int64
    let giftUniqueHostPeerType: Int32
    let giftUniqueOwnerAddress: String
    let giftUniqueValueAmount: Int64
    let giftUniqueValueUsdAmount: Int64
    let giftUniqueValueCurrency: String
    let giftUniqueLastResaleAmount: Int64
    let giftUniqueLastResaleCurrency: String
    let giftUniqueLastResaleDate: Int32
    let giftShowHiddenEnabled: Bool
    let customListUsernamesEnabled: Bool
    let customListUsernamesPayload: String
    let visualPeerBadgeEnabled: Bool
    let visualPeerBadgeValue: UInt64
    let noPremiumAnimEnabled: Bool
    let disableSpoilersEnabled: Bool
    let customTonEnabled: Bool
    let customTonValue: UInt64
    let customStarsEnabled: Bool
    let customStarsValue: UInt64
    let forceOfflineEnabled: Bool
    let openLinksWithoutWarningEnabled: Bool
    let noPhoneOnAddEnabled: Bool
    let callbackHoverEnabled: Bool
    let blockTypingEnabled: Bool
    let blockReadMessagesEnabled: Bool
    let hideBlockedEnabled: Bool
    let messageSettingsEnabled: Bool
    let messageTypingEnabled: Bool
    let messageReadReceiptsEnabled: Bool
    let messageLocalDraftsEnabled: Bool
    let messageFactCheckEnabled: Bool
    let messageFactCheckText: String
    let messageFactCheckCountry: String
    let messageFactCheckHash: Int64
    let messageFactCheckNeedCheck: Bool
    let messageNoForwardsCopyEnabled: Bool
    let messageDisableTtlEnabled: Bool
    let overlayEnabled: Bool
    let mtprotoLoggerEnabled: Bool
    let localPremiumEnabled: Bool
    let accountFreezeEnabled: Bool
    let disableMonetizationEnabled: Bool
    let disableMonetizationAppConfigEnabled: Bool
    let disableMonetizationPremiumUIEnabled: Bool
    let disableMonetizationGiftsEnabled: Bool
    let disableMonetizationPaidReactionsEnabled: Bool
    let disableMonetizationEmojiStatusesEnabled: Bool
    let disableMonetizationStarsTonCollectiblesEnabled: Bool
    let disableMonetizationBoostsEnabled: Bool
    let disableMonetizationReadReceiptsEnabled: Bool
    let scheduledSendEnabled: Bool
    let sensitiveBlurEnabled: Bool
    let hideStoriesEnabled: Bool
    let disableAdsEnabled: Bool
    let disableTelegramAdsEnabled: Bool
    let disableProxySponsorEnabled: Bool
}

public struct BinaryPatchRuleChange: Hashable, Sendable {
    public let rule: BinaryPatchRule
    public let enabled: Bool
    public let parameterValue: UInt64?
    public let botVerificationConfig: BotVerificationPatchConfig?
    public let customLevelRatingConfig: CustomLevelRatingPatchConfig?
    public let selfIdentityConfig: SelfIdentityPatchConfig?
    public let localPersonalChannelConfig: LocalPersonalChannelPatchConfig?
    public let fragmentPhoneConfig: FragmentPhonePatchConfig?
    public let starGiftSpoofConfig: StarGiftSpoofPatchConfig?
    public let starGiftUniqueSpoofConfig: StarGiftUniqueSpoofPatchConfig?
    public let customListUsernamesConfig: CustomListUsernamesPatchConfig?
    public let messageFactCheckConfig: MessageFactCheckPatchConfig?
    public let enabledAlternativeGroups: Set<String>?

    public init(
        rule: BinaryPatchRule,
        enabled: Bool,
        parameterValue: UInt64? = nil,
        botVerificationConfig: BotVerificationPatchConfig? = nil,
        customLevelRatingConfig: CustomLevelRatingPatchConfig? = nil,
        selfIdentityConfig: SelfIdentityPatchConfig? = nil,
        localPersonalChannelConfig: LocalPersonalChannelPatchConfig? = nil,
        fragmentPhoneConfig: FragmentPhonePatchConfig? = nil,
        starGiftSpoofConfig: StarGiftSpoofPatchConfig? = nil,
        starGiftUniqueSpoofConfig: StarGiftUniqueSpoofPatchConfig? = nil,
        customListUsernamesConfig: CustomListUsernamesPatchConfig? = nil,
        messageFactCheckConfig: MessageFactCheckPatchConfig? = nil,
        enabledAlternativeGroups: Set<String>? = nil
    ) {
        self.rule = rule
        self.enabled = enabled
        self.parameterValue = parameterValue
        self.botVerificationConfig = botVerificationConfig
        self.customLevelRatingConfig = customLevelRatingConfig
        self.selfIdentityConfig = selfIdentityConfig
        self.localPersonalChannelConfig = localPersonalChannelConfig
        self.fragmentPhoneConfig = fragmentPhoneConfig
        self.starGiftSpoofConfig = starGiftSpoofConfig
        self.starGiftUniqueSpoofConfig = starGiftUniqueSpoofConfig
        self.customListUsernamesConfig = customListUsernamesConfig
        self.messageFactCheckConfig = messageFactCheckConfig
        self.enabledAlternativeGroups = enabledAlternativeGroups
    }
}

private struct BinaryToggleReplacementGroup {
    let id: String
    let replacements: [BinaryReplacement]

    var isParameterGated: Bool {
        replacements.contains { $0.isParameterGated }
    }

    func activeReplacements(for parameterValue: UInt64?) -> [BinaryReplacement] {
        replacements.filter { $0.isEnabled(for: parameterValue) }
    }

    func isEnabled(for parameterValue: UInt64?) -> Bool {
        replacements.contains { $0.isEnabled(for: parameterValue) }
    }
}

private final class BinaryPatternMatchCache {
    private let data: Data
    private var rangesByNeedle: [Data: [Range<Data.Index>]] = [:]

    init(data: Data) {
        self.data = data
    }

    func ranges(of needle: Data) -> [Range<Data.Index>] {
        if let cached = rangesByNeedle[needle] {
            return cached
        }
        let ranges = data.nonOverlappingRanges(of: needle)
        rangesByNeedle[needle] = ranges
        return ranges
    }

    func count(of needle: Data) -> Int {
        ranges(of: needle).count
    }
}

public final class BinaryPatchEngine {
    private static let wrapperMarker = "# PATCHGRAM DYLIB WRAPPER"
    private static let wrappedExecutableSuffix = ".patchgram-bin"
    private static let botVerificationRuleId = "binary.visual.bot_verification"
    private static let customLevelRatingRuleId = "binary.visual.custom_level_rating"
    private static let hideSelfPhoneRuleId = "binary.visual.hide_self_phone"
    private static let selfIdentityOverrideRuleId = "binary.visual.self_identity_override"
    private static let localPersonalChannelRuleId = "binary.visual.local_personal_channel"
    private static let fragmentPhoneRuleId = "binary.visual.fragment_phone"
    private static let starGiftSpoofRuleId = "binary.gifts.spoof_profile"
    private static let starGiftUniqueSpoofRuleId = "binary.gifts.spoof_unique"
    private static let giftFakeTransferRuleId = "binary.gifts.fake_transfer"
    private static let showHiddenGiftsRuleId = "binary.gifts.show_hidden"
    private static let customListUsernamesRuleId = "binary.visual.custom_list_usernames"
    private static let visualPeerBadgeRuleId = "binary.visual.peer_badge"
    private static let noPremiumAnimRuleId = "binary.visual.no_premium_anim"
    private static let disableSpoilersRuleId = "binary.visual.disable_spoilers"
    private static let forceOfflineRuleId = "binary.presence.force_offline"
    private static let noPhoneOnAddRuleId = "binary.privacy.no_phone_on_add"
    private static let openLinksWithoutWarningRuleId = "binary.links.open_without_warning"
    private static let callbackHoverRuleId = "binary.inline.callback_hover"
    private static let customTonRuleId = "binary.display.custom_ton"
    private static let customStarsRuleId = "binary.display.custom_stars"
    private static let blockTypingRuleId = "binary.activity.block_typing"
    private static let blockReadMessagesRuleId = "binary.read_receipts.block_history_read"
    private static let hideBlockedRuleId = "binary.messages.hide_blocked"
    private static let messageSettingsRuleId = "binary.messages.settings"
    private static let messageTypingAlternativeGroup = "messages.typing.disable"
    private static let messageReadReceiptsAlternativeGroupPrefix = "messages.read_receipts."
    private static let messageLocalDraftsAlternativeGroup = "messages.drafts.local_only"
    private static let scheduledSendAlternativeGroup = "messages.scheduled_send.local"
    private static let messageFactCheckAlternativeGroup = "messages.fact_check.local"
    private static let messageNoForwardsAllowCopyAlternativeGroup = "messages.noforwards.allow_copy"
    private static let messageTtlDisableAlternativeGroup = "messages.ttl.disable"
    private static let disableMonetizationRuleId = "binary.config.disable_monetization"
    private static let localPremiumRuleId = "binary.premium.local"
    private static let accountFreezeRuleId = "binary.account.freeze"
    // When account freeze is on it drives its own (only-me) bot verification, so the two are mutually
    // exclusive in the UI and freeze's fixed values override any user bot-verification config.
    private static let accountFreezeBotVerificationEmojiId: UInt64 = 5_449_449_325_434_266_744
    private static let accountFreezeBotVerificationDescription = "The account was frozen"
    private static let overlayRuleId = "binary.overlay.profile_rain"
    private static let mtprotoLoggerRuleId = "binary.mtproto.logger"
    private static let scheduledSendRuleId = "binary.messages.scheduled_send"
    private static let sensitiveBlurRuleId = "binary.visual.sensitive_blur"
    private static let hideStoriesRuleId = "binary.stories.hide"
    private static let disableAdsRuleId = "binary.ads.disable_sponsored"
    private static let disableTelegramAdsAlternativeGroup = "ads.telegram_ads.disable"
    private static let disableProxySponsorAlternativeGroupPrefix = "ads.proxy_sponsor."
    // Built-in classification of the shipped rules. A fetched/added rule that carries
    // `delivery == .runtimeMemory` is unioned in at runtime (see the computed sets below), so new
    // memory-patch rules apply without an app rebuild.
    private static let baseRuntimeMemoryPatchRuleIds: Set<String> = [
        forceOfflineRuleId,
        openLinksWithoutWarningRuleId,
        callbackHoverRuleId,
        customTonRuleId,
        customStarsRuleId,
        blockTypingRuleId,
        blockReadMessagesRuleId,
        messageSettingsRuleId,
        disableMonetizationRuleId,
        localPremiumRuleId,
        visualPeerBadgeRuleId,
        selfIdentityOverrideRuleId,
        noPremiumAnimRuleId,
        disableSpoilersRuleId,
        sensitiveBlurRuleId,
        hideStoriesRuleId,
        disableAdsRuleId,
        noPhoneOnAddRuleId
    ]
    // Hook-driven runtime rules (handled by trampoline hooks in the engine C; can't be added by
    // data since the hooks themselves are compiled in).
    private static let baseRuntimeHookRuleIds: Set<String> = [
        botVerificationRuleId,
        customLevelRatingRuleId,
        hideSelfPhoneRuleId,
        selfIdentityOverrideRuleId,
        localPersonalChannelRuleId,
        fragmentPhoneRuleId,
        starGiftSpoofRuleId,
        starGiftUniqueSpoofRuleId,
        giftFakeTransferRuleId,
        showHiddenGiftsRuleId,
        accountFreezeRuleId,
        customListUsernamesRuleId,
        visualPeerBadgeRuleId,
        scheduledSendRuleId,
        sensitiveBlurRuleId
    ]

    private static var deliveryRuntimeMemoryRuleIds: Set<String> {
        Set(BinaryPatchRuleCatalog.rules.lazy.filter { $0.delivery == .runtimeMemory }.map(\.id))
    }
    private static var runtimeMemoryPatchRuleIds: Set<String> {
        baseRuntimeMemoryPatchRuleIds.union(deliveryRuntimeMemoryRuleIds)
    }
    private static var runtimeRuleIds: Set<String> {
        runtimeMemoryPatchRuleIds.union(baseRuntimeHookRuleIds)
    }

    private static func isProxySponsorAlternativeGroup(_ group: String) -> Bool {
        group.hasPrefix(disableProxySponsorAlternativeGroupPrefix)
    }

    private static func isMessageReadReceiptsAlternativeGroup(_ group: String) -> Bool {
        group.hasPrefix(messageReadReceiptsAlternativeGroupPrefix)
    }

    private static func disableMonetizationSubpatchId(for group: String) -> String {
        if group == "help.getAppConfig.constructor" {
            return "app_config"
        }
        if group == "api.who_read_exists.chat_threshold.default_100" {
            return "read_receipts"
        }
        if group.contains("paidReaction")
            || group.contains("reaction_paid")
            || group.contains("allowed_reactions.paid")
            || group.contains("message_reactions.skip_empty") {
            return "paid_reactions"
        }
        if group.contains("boost") {
            return "boosts"
        }
        if group.contains("gift") || group.contains("Gift") {
            return "gifts"
        }
        if group.contains("emoji_status")
            || group.contains("EmojiStatus")
            || group.contains("main_menu.status")
            || group.contains("AvailableEffects") {
            return "emoji_statuses"
        }
        if group.contains("stars")
            || group.contains("Stars")
            || group.contains("ton")
            || group.contains("nft")
            || group.contains("collectible") {
            return "stars_ton_collectibles"
        }
        return "premium_ui"
    }
    private static let botVerificationRuntimeHookDylibName = "Patchgram.dylib"
    private static let deprecatedBotVerificationRuntimeHookDylibName = "PatchgramBotVerificationHook.dylib"
    private static let deprecatedBotVerificationRuntimeHookSourceName = "PatchgramBotVerificationHook.c"
    private static let runtimeConfigName = "PatchgramRuntime.json"
    private static let deprecatedBotVerificationRuntimeConfigName = "PatchgramBotVerification.json"
    private static let legacyRuntimeHookDylibName = "PatchgramDeletedIconHook.dylib"
    private static let legacyRuntimeHookSourceName = "PatchgramDeletedIconHook.c"
    // The build marker is now CONTENT-DERIVED: a stable prefix plus a short SHA-256 of the
    // generated dylib source template. Any change to what goes into the dylib — hook bodies,
    // signatures, struct offsets, or memory-patch byte windows — changes the hash, so the
    // staleness check in compileRuntimeHook recompiles automatically. No more manual bumps
    // (forgetting one left the running dylib with stale patterns even though the source changed).
    private static let runtimeHookMarkerPrefix = "PATCHGRAM_RUNTIME_BUILD_"
    private static let runtimeHookMarkerPlaceholder = "__PATCHGRAM_BUILD_MARKER_PLACEHOLDER__"
    /// Sentinel in `engine.c.template` where the rule-derived memory-patch table is injected at
    /// apply time (so the engine source stays a static resource while the table follows the rules).
    private static let runtimeHookMemoryPatchTablePlaceholder = "__PATCHGRAM_MEMORY_PATCH_TABLE_PLACEHOLDER__"
    /// Sentinel in `engine.c.template` where the generated TL-schema tables (for the in-dylib MTProto
    /// decoder) are injected at apply time from the bundled `tl_schema.c.inc`.
    private static let runtimeHookTLSchemaPlaceholder = "__PATCHGRAM_TL_SCHEMA_PLACEHOLDER__"
    /// Compiles when no schema resource is present (older app): an empty table → every TL constructor
    /// reads back as `unknown#<id>` instead of failing the build.
    private static let tlSchemaStub = """
    static const char g_tl_strpool[] = "";
    static const struct PatchgramTLCtor g_tl_ctors[] = { {0,0,0,0} };
    static const unsigned g_tl_ctor_count = 0;
    static const struct PatchgramTLParam g_tl_params[] = { {0,0,0,0,0} };
    """
    private static let patchLogName = "PatchgramPatch.log"
    private static let hookLogName = "PatchgramHook.log"

    private let fileManager: FileManager
    private let processRunner: ProcessRunning

    public init(
        fileManager: FileManager = .default,
        processRunner: ProcessRunning = FoundationProcessRunner()
    ) {
        self.fileManager = fileManager
        self.processRunner = processRunner
    }

    public func inspect(appURL: URL) throws -> AppInspection {
        guard appURL.pathExtension == "app" else {
            throw PatchgramError.invalidAppBundle(appURL.path)
        }
        let infoURL = appURL.appendingPathComponent("Contents/Info.plist")
        guard let info = NSDictionary(contentsOf: infoURL) as? [String: Any] else {
            throw PatchgramError.invalidAppBundle(appURL.path)
        }
        guard let executableName = info["CFBundleExecutable"] as? String, !executableName.isEmpty else {
            throw PatchgramError.invalidAppBundle(appURL.path)
        }
        let bundleIdentifier = info["CFBundleIdentifier"] as? String ?? "unknown.bundle"
        guard bundleIdentifier == "com.tdesktop.Telegram" else {
            throw PatchgramError.unsupportedAppBundle(bundleIdentifier)
        }
        let executableURL = appURL.appendingPathComponent("Contents/MacOS/")
            .appendingPathComponent(executableName)
        guard fileManager.fileExists(atPath: executableURL.path) else {
            throw PatchgramError.missingExecutable(executableURL.path)
        }
        let preliminaryInspection = AppInspection(
            appURL: appURL,
            executableURL: executableURL,
            bundleIdentifier: bundleIdentifier,
            bundleVersion: (info["CFBundleShortVersionString"] as? String)
                ?? (info["CFBundleVersion"] as? String)
                ?? "unknown",
            executableSize: 0
        )
        let targetURL = patchTargetExecutableURL(for: preliminaryInspection)
        let attributes = try fileManager.attributesOfItem(atPath: targetURL.path)
        let size = (attributes[.size] as? NSNumber)?.uint64Value ?? 0
        return AppInspection(
            appURL: appURL,
            executableURL: executableURL,
            bundleIdentifier: preliminaryInspection.bundleIdentifier,
            bundleVersion: preliminaryInspection.bundleVersion,
            executableSize: size
        )
    }

    public func copyApp(source: URL, destination: URL) throws -> AppInspection {
        _ = try inspect(appURL: source)
        if fileManager.fileExists(atPath: destination.path) {
            throw PatchgramError.destinationExists(destination.path)
        }
        try fileManager.copyItem(at: source, to: destination)
        return try inspect(appURL: destination)
    }

    public func statuses(
        appURL: URL,
        rules: [BinaryPatchRule] = BinaryPatchRuleCatalog.rules,
        parameterValues: [String: UInt64] = [:],
        botVerificationConfigs: [String: BotVerificationPatchConfig] = [:],
        customLevelRatingConfigs: [String: CustomLevelRatingPatchConfig] = [:],
        selfIdentityConfigs: [String: SelfIdentityPatchConfig] = [:],
        localPersonalChannelConfigs: [String: LocalPersonalChannelPatchConfig] = [:],
        fragmentPhoneConfigs: [String: FragmentPhonePatchConfig] = [:],
        customListUsernamesConfigs: [String: CustomListUsernamesPatchConfig] = [:],
        messageFactCheckConfigs: [String: MessageFactCheckPatchConfig] = [:]
    ) throws -> [BinaryRuleStatus] {
        let inspection = try inspect(appURL: appURL)
        let manifest = try readManifest(appURL: appURL)
        let data = try Data(contentsOf: patchTargetExecutableURL(for: inspection))
        let matchCache = BinaryPatternMatchCache(data: data)
        let computed = rules.map { rule -> BinaryRuleStatus in
            if isRuntimeRule(rule) {
                return runtimeStatus(
                    for: rule,
                    inspection: inspection,
                    manifest: manifest,
                    data: data,
                    matchCache: matchCache,
                    parameterValue: parameterValues[rule.id],
                    requestedBotVerificationConfig: botVerificationConfigs[rule.id],
                    requestedCustomLevelRatingConfig: customLevelRatingConfigs[rule.id],
                    requestedSelfIdentityConfig: selfIdentityConfigs[rule.id],
                    requestedLocalPersonalChannelConfig: localPersonalChannelConfigs[rule.id],
                    requestedFragmentPhoneConfig: fragmentPhoneConfigs[rule.id],
                    requestedCustomListUsernamesConfig: customListUsernamesConfigs[rule.id],
                    requestedMessageFactCheckConfig: messageFactCheckConfigs[rule.id]
                )
            }
            return status(
                for: rule,
                data: data,
                matchCache: matchCache,
                parameterValue: parameterValues[rule.id]
            )
        }
        return markDefinitionChanges(computed, manifest: manifest)
    }

    public func manifestStatuses(
        appURL: URL,
        rules: [BinaryPatchRule] = BinaryPatchRuleCatalog.rules
    ) throws -> [BinaryRuleStatus]? {
        guard let manifest = try readManifest(appURL: appURL) else { return nil }
        let enabled = Set(manifest.enabledRuleIds)
        let statuses = rules.map { rule -> BinaryRuleStatus in
            let state: RuleApplicationState = enabled.contains(rule.id) ? .applied : .notApplied
            let detail: String
            if rule.kind == .botVerification,
               let config = manifest.botVerificationConfigs[rule.id] {
                detail = state.isEnabled
                    ? "Recorded in Patchgram manifest: \(config.displayValue)."
                    : "Not recorded in Patchgram manifest."
            } else if rule.kind == .customLevelRating,
                      let config = manifest.customLevelRatingConfigs[rule.id] {
                detail = state.isEnabled
                    ? "Recorded in Patchgram manifest: \(config.displayValue)."
                    : "Not recorded in Patchgram manifest."
            } else if rule.kind == .selfIdentityOverride,
                      let config = manifest.selfIdentityConfigs[rule.id] {
                detail = state.isEnabled
                    ? "Recorded in Patchgram manifest: \(config.displayValue)."
                    : "Not recorded in Patchgram manifest."
            } else if rule.kind == .localPersonalChannel,
                      let config = manifest.localPersonalChannelConfigs[rule.id] {
                detail = state.isEnabled
                    ? "Recorded in Patchgram manifest: \(config.displayValue)."
                    : "Not recorded in Patchgram manifest."
            } else if rule.kind == .fragmentPhone,
                      let config = manifest.fragmentPhoneConfigs[rule.id] {
                detail = state.isEnabled
                    ? "Recorded in Patchgram manifest: \(config.displayValue)."
                    : "Not recorded in Patchgram manifest."
            } else if rule.kind == .customListUsernames,
                      let config = manifest.customListUsernamesConfigs[rule.id] {
                detail = state.isEnabled
                    ? "Recorded in Patchgram manifest: \(config.displayValue)."
                    : "Not recorded in Patchgram manifest."
            } else if rule.id == Self.messageSettingsRuleId,
                      let config = manifest.messageFactCheckConfigs[rule.id],
                      manifest.enabledAlternativeGroups[rule.id]?.contains(Self.messageFactCheckAlternativeGroup) == true {
                detail = state.isEnabled
                    ? "Recorded in Patchgram manifest: \(config.displayValue)."
                    : "Not recorded in Patchgram manifest."
            } else if isRuntimeRule(rule) {
                detail = state.isEnabled ? "Recorded in Patchgram manifest as a runtime rule." : "Not recorded in Patchgram manifest."
            } else {
                detail = state.isEnabled ? "Recorded in Patchgram manifest." : "Not recorded in Patchgram manifest."
            }
            return BinaryRuleStatus(rule: rule, state: state, detail: detail)
        }
        return markDefinitionChanges(statuses, manifest: manifest)
    }

    /// Marks each applied rule whose recorded definition digest differs from the current rule —
    /// the signal that a fetched update changed an enabled patch and it should offer "Update".
    private func markDefinitionChanges(
        _ statuses: [BinaryRuleStatus],
        manifest: BinaryPatchManifest?
    ) -> [BinaryRuleStatus] {
        guard let manifest, !manifest.appliedDefinitionHashes.isEmpty else { return statuses }
        return statuses.map { status in
            guard status.state.isEnabled,
                  let applied = manifest.appliedDefinitionHashes[status.rule.id],
                  applied != status.rule.definitionDigest else {
                return status
            }
            return BinaryRuleStatus(
                rule: status.rule,
                state: status.state,
                detail: status.detail + " Definition updated — re-apply to refresh.",
                definitionChanged: true
            )
        }
    }

    public func assumedUnappliedStatuses(
        rules: [BinaryPatchRule] = BinaryPatchRuleCatalog.rules
    ) -> [BinaryRuleStatus] {
        rules.map { rule in
            BinaryRuleStatus(
                rule: rule,
                state: .notApplied,
                detail: "Not checked yet. Exact bytes are verified when the patch is applied."
            )
        }
    }

    public func manifestParameterValues(appURL: URL) throws -> [String: UInt64] {
        try readManifest(appURL: appURL)?.parameterValues ?? [:]
    }

    public func manifestBotVerificationConfigs(appURL: URL) throws -> [String: BotVerificationPatchConfig] {
        try readManifest(appURL: appURL)?.botVerificationConfigs ?? [:]
    }

    public func manifestCustomLevelRatingConfigs(appURL: URL) throws -> [String: CustomLevelRatingPatchConfig] {
        try readManifest(appURL: appURL)?.customLevelRatingConfigs ?? [:]
    }

    public func manifestSelfIdentityConfigs(appURL: URL) throws -> [String: SelfIdentityPatchConfig] {
        try readManifest(appURL: appURL)?.selfIdentityConfigs ?? [:]
    }

    public func manifestLocalPersonalChannelConfigs(appURL: URL) throws -> [String: LocalPersonalChannelPatchConfig] {
        try readManifest(appURL: appURL)?.localPersonalChannelConfigs ?? [:]
    }

    public func manifestFragmentPhoneConfigs(appURL: URL) throws -> [String: FragmentPhonePatchConfig] {
        try readManifest(appURL: appURL)?.fragmentPhoneConfigs ?? [:]
    }

    public func manifestCustomListUsernamesConfigs(appURL: URL) throws -> [String: CustomListUsernamesPatchConfig] {
        try readManifest(appURL: appURL)?.customListUsernamesConfigs ?? [:]
    }

    public func manifestMessageFactCheckConfigs(appURL: URL) throws -> [String: MessageFactCheckPatchConfig] {
        try readManifest(appURL: appURL)?.messageFactCheckConfigs ?? [:]
    }

    public func appendDiagnosticLog(_ message: String, appURL: URL) {
        appendPatchLog(message, appURL: appURL)
    }

    public func runtimeHookSupportsLiveReload(appURL: URL) throws -> Bool {
        let inspection = try inspect(appURL: appURL)
        guard runtimeHookInstalled(for: inspection) else { return false }
        let dylibURL = botVerificationRuntimeHookDylibURL(for: appURL)
        guard let data = try? Data(contentsOf: dylibURL) else { return false }
        // "Is this a Patchgram dylib at all" — match the stable prefix, not the content hash.
        return data.range(of: Data(Self.runtimeHookMarkerPrefix.utf8)) != nil
    }

    public func verifyPatchWriteAccess(appURL: URL) throws {
        let inspection = try inspect(appURL: appURL)
        try verifyPatchWriteAccess(for: inspection)
    }

    public func applyDesiredStates(
        _ desired: [String: Bool],
        appURL: URL,
        parameterValues: [String: UInt64] = [:],
        botVerificationConfigs: [String: BotVerificationPatchConfig] = [:],
        customLevelRatingConfigs: [String: CustomLevelRatingPatchConfig] = [:],
        selfIdentityConfigs: [String: SelfIdentityPatchConfig] = [:],
        localPersonalChannelConfigs: [String: LocalPersonalChannelPatchConfig] = [:],
        fragmentPhoneConfigs: [String: FragmentPhonePatchConfig] = [:],
        starGiftSpoofConfig: StarGiftSpoofPatchConfig? = nil,
        starGiftUniqueSpoofConfig: StarGiftUniqueSpoofPatchConfig? = nil,
        customListUsernamesConfigs: [String: CustomListUsernamesPatchConfig] = [:],
        messageFactCheckConfigs: [String: MessageFactCheckPatchConfig] = [:],
        signAfterPatch: Bool = true
    ) throws -> BinaryPatchApplicationReport {
        let changes = try desired
            .sorted(by: { $0.key < $1.key })
            .map { ruleId, enabled -> BinaryPatchRuleChange in
                guard let rule = BinaryPatchRuleCatalog.rule(id: ruleId) else {
                    throw PatchgramError.unknownRule(ruleId)
                }
                return BinaryPatchRuleChange(
                    rule: rule,
                    enabled: enabled,
                    parameterValue: parameterValues[rule.id],
                    botVerificationConfig: botVerificationConfigs[rule.id],
                    customLevelRatingConfig: customLevelRatingConfigs[rule.id],
                    selfIdentityConfig: selfIdentityConfigs[rule.id],
                    localPersonalChannelConfig: localPersonalChannelConfigs[rule.id],
                    fragmentPhoneConfig: fragmentPhoneConfigs[rule.id],
                    starGiftSpoofConfig: rule.kind == .starGiftSpoof ? starGiftSpoofConfig : nil,
                    starGiftUniqueSpoofConfig: rule.kind == .starGiftUniqueSpoof ? starGiftUniqueSpoofConfig : nil,
                    customListUsernamesConfig: customListUsernamesConfigs[rule.id],
                    messageFactCheckConfig: messageFactCheckConfigs[rule.id]
                )
            }
        return try applyRuleChanges(changes, appURL: appURL, signAfterPatch: signAfterPatch)
    }

    public func applyRuleChanges(
        _ changes: [BinaryPatchRuleChange],
        appURL: URL,
        signAfterPatch: Bool = true
    ) throws -> BinaryPatchApplicationReport {
        let inspection = try inspect(appURL: appURL)
        try verifyPatchWriteAccess(for: inspection)
        let executableURL = patchTargetExecutableURL(for: inspection)
        try ensureBackup(for: inspection, executableURL: executableURL)

        var data = try Data(contentsOf: executableURL)
        let operationStart = Date()
        let desiredDescription = changes
            .map { "\($0.rule.id)=\($0.enabled)" }
            .joined(separator: ", ")
        appendPatchLog(
            "BEGIN Apply binary rule changes\nAPP: \(inspection.bundleIdentifier) \(inspection.bundleVersion)\nTARGET: \(executableURL.path)\nCHANGES: \(desiredDescription.isEmpty ? "<empty>" : desiredDescription)",
            appURL: appURL
        )
        var changed = false
        var executableChanged = false
        var messages: [String] = []

        do {
            for change in changes where !isRuntimeRule(change.rule) {
                let ruleStart = Date()
                let before = data
                data = try transform(
                    data: data,
                    rule: change.rule,
                    enabled: change.enabled,
                    parameterValue: change.parameterValue,
                    enabledAlternativeGroups: change.enabledAlternativeGroups
                )
                if data == before {
                    messages.append(change.enabled ? "\(change.rule.title) was already enabled." : "\(change.rule.title) was already disabled.")
                } else {
                    changed = true
                    executableChanged = true
                    messages.append(change.enabled ? "Enabled \(change.rule.title)." : "Disabled \(change.rule.title).")
                }
                appendPatchLog(
                    "STEP Transform rule\nRULE: \(change.rule.id)=\(change.enabled)\nCHANGED: \(data != before)\nDURATION: \(durationString(since: ruleStart))",
                    appURL: appURL
                )
            }
            for change in changes where isRuntimeMemoryRule(change.rule) {
                let ruleStart = Date()
                let before = data
                data = try normalizeRuntimeRuleDiskBytes(
                    data: data,
                    rule: change.rule,
                    parameterValue: change.parameterValue
                )
                if data != before {
                    changed = true
                    executableChanged = true
                    messages.append("Migrated \(change.rule.title) from on-disk bytes to Patchgram.dylib.")
                }
                appendPatchLog(
                    "STEP Normalize runtime rule disk bytes\nRULE: \(change.rule.id)\nCHANGED: \(data != before)\nDURATION: \(durationString(since: ruleStart))",
                    appURL: appURL
                )
            }
        } catch {
            appendPatchLog(
                "ERROR Apply binary rule changes\nERROR: \(error.localizedDescription)\nSTATUSES:\n\(diagnosticStatuses(data: data, inspection: inspection, parameterValues: parameterValues(from: changes)))",
                appURL: appURL
            )
            throw error
        }

        if changed {
            let writeStart = Date()
            try data.write(to: executableURL, options: .atomic)
            try makeExecutable(at: executableURL)
            appendPatchLog("STEP Write executable\nDURATION: \(durationString(since: writeStart))", appURL: appURL)
        }

        let runtimeChanges = changes.filter { isRuntimeRule($0.rule) }
        if !runtimeChanges.isEmpty {
            let ruleStart = Date()
            let nextManifest = try manifest(appURL: appURL, applying: changes)
            let runtimeSync = try synchronizeRuntimeHook(for: inspection, manifest: nextManifest)
            changed = changed || runtimeSync.changed
            executableChanged = executableChanged || runtimeSync.changedExecutable
            for change in runtimeChanges {
                messages.append(runtimeRuleMessage(for: change, changed: runtimeSync.changed))
            }
            appendPatchLog(
                "STEP Runtime rules\nRULES: \(runtimeChanges.map { "\($0.rule.id)=\($0.enabled)" }.joined(separator: ", "))\nCHANGED: \(runtimeSync.changed)\nEXECUTABLE_CHANGED: \(runtimeSync.changedExecutable)\nDURATION: \(durationString(since: ruleStart))",
                appURL: appURL
            )
        }

        if try removeLegacyRuntimeHook(for: inspection) {
            changed = true
            executableChanged = true
            messages.append("Removed legacy deleted-message runtime hook.")
        }

        if !changes.isEmpty {
            try updateManifest(appURL: appURL, applying: changes)
        }

        if executableChanged {
            if signAfterPatch {
                try sign(appURL: appURL)
                messages.append("Re-signed app with ad-hoc identity.")
            }
        }

        appendPatchLog(
            "END Apply binary rule changes\nCHANGED: \(changed)\nEXECUTABLE_CHANGED: \(executableChanged)\nDURATION: \(durationString(since: operationStart))\nMESSAGES: \(messages.joined(separator: " "))",
            appURL: appURL
        )

        return BinaryPatchApplicationReport(changedExecutable: executableChanged, messages: messages)
    }

    public func setRule(
        _ rule: BinaryPatchRule,
        enabled: Bool,
        appURL: URL,
        parameterValue: UInt64? = nil,
        botVerificationConfig: BotVerificationPatchConfig? = nil,
        customLevelRatingConfig: CustomLevelRatingPatchConfig? = nil,
        selfIdentityConfig: SelfIdentityPatchConfig? = nil,
        localPersonalChannelConfig: LocalPersonalChannelPatchConfig? = nil,
        fragmentPhoneConfig: FragmentPhonePatchConfig? = nil,
        starGiftSpoofConfig: StarGiftSpoofPatchConfig? = nil,
        starGiftUniqueSpoofConfig: StarGiftUniqueSpoofPatchConfig? = nil,
        customListUsernamesConfig: CustomListUsernamesPatchConfig? = nil,
        messageFactCheckConfig: MessageFactCheckPatchConfig? = nil,
        signAfterPatch: Bool = true
    ) throws -> BinaryPatchApplicationReport {
        let inspection = try inspect(appURL: appURL)
        try verifyPatchWriteAccess(for: inspection)
        let executableURL = patchTargetExecutableURL(for: inspection)
        try ensureBackup(for: inspection, executableURL: executableURL)

        let data = try Data(contentsOf: executableURL)
        let operationStart = Date()
        appendPatchLog(
            "BEGIN Set binary rule\nAPP: \(inspection.bundleIdentifier) \(inspection.bundleVersion)\nTARGET: \(executableURL.path)\nRULE: \(rule.id)=\(enabled)",
            appURL: appURL
        )
        var next = data
        if isRuntimeMemoryRule(rule) {
            next = try normalizeRuntimeRuleDiskBytes(data: next, rule: rule, parameterValue: parameterValue)
        } else if !isRuntimeRule(rule) {
            do {
                next = try transform(data: data, rule: rule, enabled: enabled, parameterValue: parameterValue)
            } catch {
                appendPatchLog(
                    "ERROR Set binary rule\nRULE: \(rule.id)=\(enabled)\nERROR: \(error.localizedDescription)\nSTATUSES:\n\(diagnosticStatuses(data: data, inspection: inspection, parameterValues: [rule.id: parameterValue].compactMapValues { $0 }))",
                    appURL: appURL
                )
                throw error
            }
        }
        let bytesChanged = next != data

        if bytesChanged {
            let writeStart = Date()
            try next.write(to: executableURL, options: .atomic)
            try makeExecutable(at: executableURL)
            appendPatchLog("STEP Write executable\nDURATION: \(durationString(since: writeStart))", appURL: appURL)
        }

        let runtimeSync: RuntimeHookSyncResult
        if isRuntimeRule(rule) {
            let change = BinaryPatchRuleChange(
                rule: rule,
                enabled: enabled,
                parameterValue: parameterValue,
                botVerificationConfig: botVerificationConfig,
                customLevelRatingConfig: customLevelRatingConfig,
                selfIdentityConfig: selfIdentityConfig,
                localPersonalChannelConfig: localPersonalChannelConfig,
                fragmentPhoneConfig: fragmentPhoneConfig,
                starGiftSpoofConfig: starGiftSpoofConfig,
                starGiftUniqueSpoofConfig: starGiftUniqueSpoofConfig,
                customListUsernamesConfig: customListUsernamesConfig,
                messageFactCheckConfig: messageFactCheckConfig
            )
            let nextManifest = try manifest(
                appURL: appURL,
                applying: [change]
            )
            runtimeSync = try synchronizeRuntimeHook(for: inspection, manifest: nextManifest)
        } else {
            let legacyChanged = try removeLegacyRuntimeHook(for: inspection)
            runtimeSync = RuntimeHookSyncResult(changed: legacyChanged, changedExecutable: legacyChanged)
        }
        try updateManifest(
            appURL: appURL,
            applying: [
                BinaryPatchRuleChange(
                    rule: rule,
                    enabled: enabled,
                    parameterValue: parameterValue,
                    botVerificationConfig: botVerificationConfig,
                    customLevelRatingConfig: customLevelRatingConfig,
                    selfIdentityConfig: selfIdentityConfig,
                    localPersonalChannelConfig: localPersonalChannelConfig,
                    fragmentPhoneConfig: fragmentPhoneConfig,
                starGiftSpoofConfig: starGiftSpoofConfig,
                    starGiftUniqueSpoofConfig: starGiftUniqueSpoofConfig,
                    customListUsernamesConfig: customListUsernamesConfig,
                    messageFactCheckConfig: messageFactCheckConfig
                )
            ]
        )

        guard bytesChanged || runtimeSync.changed else {
            appendPatchLog(
                "END Set binary rule\nRULE: \(rule.id)=\(enabled)\nCHANGED: false\nDURATION: \(durationString(since: operationStart))",
                appURL: appURL
            )
            return BinaryPatchApplicationReport(
                changedExecutable: false,
                messages: [enabled ? "\(rule.title) was already enabled." : "\(rule.title) was already disabled."]
            )
        }

        var messages = [enabled ? "Enabled \(rule.title)." : "Disabled \(rule.title)."]
        if runtimeSync.changed && !isRuntimeRule(rule) {
            messages.append("Removed legacy deleted-message runtime hook.")
        }
        let executableChanged = bytesChanged || runtimeSync.changedExecutable
        if executableChanged && signAfterPatch {
            try sign(appURL: appURL)
            messages.append("Re-signed app with ad-hoc identity.")
        }
        appendPatchLog(
            "END Set binary rule\nRULE: \(rule.id)=\(enabled)\nCHANGED: true\nEXECUTABLE_CHANGED: \(executableChanged)\nDURATION: \(durationString(since: operationStart))\nMESSAGES: \(messages.joined(separator: " "))",
            appURL: appURL
        )
        return BinaryPatchApplicationReport(changedExecutable: executableChanged, messages: messages)
    }

    public func restoreOriginalExecutable(appURL: URL, signAfterRestore: Bool = true) throws -> BinaryPatchApplicationReport {
        let inspection = try inspect(appURL: appURL)
        try verifyPatchWriteAccess(for: inspection)
        let backup = backupURL(for: inspection)
        guard fileManager.fileExists(atPath: backup.path) else {
            return BinaryPatchApplicationReport(changedExecutable: false, messages: ["No Patchgram backup found."])
        }
        let executableURL = patchTargetExecutableURL(for: inspection)
        let data = try Data(contentsOf: backup)
        try data.write(to: executableURL, options: .atomic)
        try makeExecutable(at: executableURL)
        _ = try removeRuntimeHook(for: inspection)
        _ = try removeLegacyRuntimeHook(for: inspection)
        try updateManifest(appURL: appURL, desired: [:])
        var messages = ["Restored original executable from Patchgram backup."]
        if signAfterRestore {
            try sign(appURL: appURL)
            messages.append("Re-signed app with ad-hoc identity.")
        }
        return BinaryPatchApplicationReport(changedExecutable: true, messages: messages)
    }

    private func status(
        for rule: BinaryPatchRule,
        data: Data,
        matchCache: BinaryPatternMatchCache,
        parameterValue: UInt64? = nil
    ) -> BinaryRuleStatus {
        let parameterValue = parameterValue ?? rule.parameter?.defaultValue
        var originalHits = 0
        var configuredHits = 0
        var patchedHits = 0
        var missing: [String] = []
        var ambiguous: [String] = []
        var pendingNormalizations: [String] = []
        for replacement in rule.replacements {
            guard replacement.mode == .normalize else { continue }
            let original = matchCache.count(of: replacement.original)
            if original >= replacement.expectedOccurrences {
                pendingNormalizations.append(replacement.id)
            }
        }

        let toggleGroups = Self.toggleReplacementGroups(for: rule)
        let hasAnyActiveToggleGroup = toggleGroups.contains { group in
            !group.isParameterGated || !group.activeReplacements(for: parameterValue).isEmpty
        }
        var toggleCount = 0
        var parameterMismatches: [String] = []
        for group in toggleGroups {
            if group.isParameterGated {
                let active = group.activeReplacements(for: parameterValue)
                if active.isEmpty {
                    toggleCount += 1
                    let originalMatches = group.replacements.filter {
                        matchCache.count(of: $0.original) >= $0.expectedOccurrences
                    }
                    if !originalMatches.isEmpty {
                        originalHits += 1
                        if hasAnyActiveToggleGroup {
                            configuredHits += 1
                        }
                        continue
                    }
                    if group.replacements.contains(where: {
                        matchCache.count(of: $0.patchedData(parameterValue: parameterValue)) >= $0.expectedOccurrences
                    }) {
                        parameterMismatches.append(group.id)
                        patchedHits += 1
                        continue
                    }
                    missing.append(group.id)
                    continue
                }
            }
            toggleCount += 1
            let groupEnabled = group.isEnabled(for: parameterValue)
            let replacements = group.isParameterGated
                ? group.activeReplacements(for: parameterValue)
                : group.replacements
            let originalMatches = replacements.filter {
                matchCache.count(of: $0.original) >= $0.expectedOccurrences
            }
            let patchedExactMatches = replacements.filter {
                matchCache.count(of: $0.patchedData(parameterValue: parameterValue)) >= $0.expectedOccurrences
            }
            let inactivePatchedMatches = group.isParameterGated
                ? group.replacements.filter { replacement in
                    !replacement.isEnabled(for: parameterValue)
                        && matchCache.count(of: replacement.patchedData(parameterValue: parameterValue)) >= replacement.expectedOccurrences
                }
                : []
            let patchedFlexibleMatches = originalMatches.isEmpty && patchedExactMatches.isEmpty
                ? replacements.filter {
                    flexiblePatchedRanges(for: $0, in: data, matchCache: matchCache).count >= $0.expectedOccurrences
                }
                : []
            let patchedMatches = patchedExactMatches + patchedFlexibleMatches
            if patchedMatches.isEmpty, !inactivePatchedMatches.isEmpty {
                parameterMismatches.append(group.id)
            }
            switch (originalMatches.isEmpty, patchedMatches.isEmpty) {
            case (true, true):
                missing.append(group.id)
            case (false, true):
                originalHits += 1
                if !groupEnabled {
                    configuredHits += 1
                }
            case (true, false):
                patchedHits += 1
                if groupEnabled {
                    configuredHits += 1
                }
                if patchedExactMatches.isEmpty {
                    parameterMismatches.append(group.id)
                }
            case (false, false):
                ambiguous.append(group.id)
            }
        }
        if !ambiguous.isEmpty {
            return BinaryRuleStatus(
                rule: rule,
                state: .partial,
                detail: "Multiple alternative windows matched: \(ambiguous.joined(separator: ", "))."
            )
        }
        if !pendingNormalizations.isEmpty {
            return BinaryRuleStatus(
                rule: rule,
                state: .partial,
                detail: "Legacy bytes need migration: \(pendingNormalizations.joined(separator: ", "))."
            )
        }
        if !parameterMismatches.isEmpty, patchedHits == toggleCount {
            return BinaryRuleStatus(
                rule: rule,
                state: .partial,
                detail: "Patched with a different parameter value: \(parameterMismatches.joined(separator: ", "))."
            )
        }
        if configuredHits == toggleCount {
            return BinaryRuleStatus(rule: rule, state: .applied, detail: "All binary windows are patched.")
        }
        if originalHits == toggleCount {
            return BinaryRuleStatus(rule: rule, state: .notApplied, detail: "All binary windows match the original bytes.")
        }
        if !missing.isEmpty {
            return BinaryRuleStatus(rule: rule, state: .unavailable, detail: "Missing: \(missing.joined(separator: ", ")).")
        }
        if configuredHits == toggleCount {
            return BinaryRuleStatus(rule: rule, state: .applied, detail: "All binary windows are patched.")
        }
        if originalHits == toggleCount {
            return BinaryRuleStatus(rule: rule, state: .notApplied, detail: "All binary windows match the original bytes.")
        }
        return BinaryRuleStatus(rule: rule, state: .partial, detail: "Some binary windows are patched and some are original.")
    }

    private func runtimeStatus(
        for rule: BinaryPatchRule,
        inspection: AppInspection,
        manifest: BinaryPatchManifest?,
        data: Data,
        matchCache: BinaryPatternMatchCache,
        parameterValue: UInt64?,
        requestedBotVerificationConfig: BotVerificationPatchConfig?,
        requestedCustomLevelRatingConfig: CustomLevelRatingPatchConfig?,
        requestedSelfIdentityConfig: SelfIdentityPatchConfig?,
        requestedLocalPersonalChannelConfig: LocalPersonalChannelPatchConfig?,
        requestedFragmentPhoneConfig: FragmentPhonePatchConfig?,
        requestedCustomListUsernamesConfig: CustomListUsernamesPatchConfig?,
        requestedMessageFactCheckConfig: MessageFactCheckPatchConfig?
    ) -> BinaryRuleStatus {
        let manifestEnabled = manifest?.enabledRuleIds.contains(rule.id) == true
        let installed = runtimeHookInstalled(for: inspection)
        let manifestBotVerificationConfig = (
            manifest?.botVerificationConfigs[rule.id]
                ?? BotVerificationPatchConfig.defaultConfig
        ).normalized
        let config = (requestedBotVerificationConfig ?? manifestBotVerificationConfig).normalized
        let manifestCustomLevelRatingConfig = (
            manifest?.customLevelRatingConfigs[rule.id]
                ?? CustomLevelRatingPatchConfig.defaultConfig
        ).normalized
        let ratingConfig = (requestedCustomLevelRatingConfig ?? manifestCustomLevelRatingConfig).normalized
        let manifestSelfIdentityConfig = (
            manifest?.selfIdentityConfigs[rule.id]
                ?? SelfIdentityPatchConfig.defaultConfig
        ).normalized
        let selfIdentityConfig = (requestedSelfIdentityConfig ?? manifestSelfIdentityConfig).normalized
        let manifestLocalPersonalChannelConfig = (
            manifest?.localPersonalChannelConfigs[rule.id]
                ?? LocalPersonalChannelPatchConfig.defaultConfig
        ).normalized
        let localPersonalChannelConfig = (
            requestedLocalPersonalChannelConfig ?? manifestLocalPersonalChannelConfig
        ).normalized
        let manifestFragmentPhoneConfig = (
            manifest?.fragmentPhoneConfigs[rule.id]
                ?? FragmentPhonePatchConfig.defaultConfig
        ).normalized
        let fragmentPhoneConfig = (
            requestedFragmentPhoneConfig ?? manifestFragmentPhoneConfig
        ).normalized
        let manifestCustomListUsernamesConfig = (
            manifest?.customListUsernamesConfigs[rule.id]
                ?? CustomListUsernamesPatchConfig.defaultConfig
        ).normalized
        let customListUsernamesConfig = (
            requestedCustomListUsernamesConfig ?? manifestCustomListUsernamesConfig
        ).normalized
        let manifestMessageFactCheckConfig = (
            manifest?.messageFactCheckConfigs[rule.id]
                ?? MessageFactCheckPatchConfig.defaultConfig
        ).normalized
        let messageFactCheckConfig = (
            requestedMessageFactCheckConfig ?? manifestMessageFactCheckConfig
        ).normalized

        if Self.runtimeMemoryPatchRuleIds.contains(rule.id),
           !manifestEnabled,
           runtimeRuleHasLegacyDiskPatch(
            rule,
            data: data,
            matchCache: matchCache,
            parameterValue: parameterValue ?? rule.parameter?.defaultValue
           ) {
            return BinaryRuleStatus(
                rule: rule,
                state: .partial,
                detail: "Legacy on-disk binary bytes are patched; apply/disable this rule once to migrate it into Patchgram.dylib."
            )
        }

        let installedDetail: String
        if rule.kind == .botVerification {
            installedDetail = "Runtime hook installed: \(config.displayValue)."
        } else if rule.kind == .customLevelRating {
            installedDetail = "Runtime hook installed: \(ratingConfig.displayValue)."
        } else if rule.kind == .hideSelfPhone {
            installedDetail = "Runtime hook installed."
        } else if rule.kind == .selfIdentityOverride {
            installedDetail = "Runtime hook installed: \(selfIdentityConfig.displayValue)."
        } else if rule.kind == .localPersonalChannel {
            installedDetail = "Runtime hook installed: \(localPersonalChannelConfig.displayValue)."
        } else if rule.kind == .fragmentPhone {
            installedDetail = "Runtime hook installed: \(fragmentPhoneConfig.displayValue)."
        } else if rule.kind == .customListUsernames {
            installedDetail = "Runtime hook installed: \(customListUsernamesConfig.displayValue)."
        } else if rule.id == Self.messageSettingsRuleId,
                  manifest?.enabledAlternativeGroups[rule.id]?.contains(Self.messageFactCheckAlternativeGroup) == true {
            installedDetail = "Runtime memory patch installed: \(messageFactCheckConfig.displayValue)."
        } else if let parameter = rule.parameter {
            let value = parameterValue
                ?? manifest?.parameterValues[rule.id]
                ?? parameter.defaultValue
            installedDetail = "Runtime memory patch installed: \(parameter.displayValue(value))."
        } else {
            installedDetail = "Runtime memory patch installed."
        }

        if manifestEnabled && installed {
            if rule.kind == .botVerification,
               let requestedBotVerificationConfig,
               requestedBotVerificationConfig.normalized != manifestBotVerificationConfig {
                return BinaryRuleStatus(
                    rule: rule,
                    state: .partial,
                    detail: "Runtime hook is installed with a different bot verification config."
                )
            }
            if rule.kind == .customLevelRating,
               let requestedCustomLevelRatingConfig,
               requestedCustomLevelRatingConfig.normalized != manifestCustomLevelRatingConfig {
                return BinaryRuleStatus(
                    rule: rule,
                    state: .partial,
                    detail: "Runtime hook is installed with a different custom level rating config."
                )
            }
            if rule.kind == .selfIdentityOverride,
               let requestedSelfIdentityConfig,
               requestedSelfIdentityConfig.normalized != manifestSelfIdentityConfig {
                return BinaryRuleStatus(
                    rule: rule,
                    state: .partial,
                    detail: "Runtime hook is installed with a different self identity config."
                )
            }
            if rule.kind == .localPersonalChannel,
               let requestedLocalPersonalChannelConfig,
               requestedLocalPersonalChannelConfig.normalized != manifestLocalPersonalChannelConfig {
                return BinaryRuleStatus(
                    rule: rule,
                    state: .partial,
                    detail: "Runtime hook is installed with a different local attached channel config."
                )
            }
            if rule.kind == .fragmentPhone,
               let requestedFragmentPhoneConfig,
               requestedFragmentPhoneConfig.normalized != manifestFragmentPhoneConfig {
                return BinaryRuleStatus(
                    rule: rule,
                    state: .partial,
                    detail: "Runtime hook is installed with a different Fragment phone config."
                )
            }
            if rule.kind == .customListUsernames,
               let requestedCustomListUsernamesConfig,
               requestedCustomListUsernamesConfig.normalized != manifestCustomListUsernamesConfig {
                return BinaryRuleStatus(
                    rule: rule,
                    state: .partial,
                    detail: "Runtime hook is installed with a different custom usernames config."
                )
            }
            if rule.id == Self.messageSettingsRuleId,
               manifest?.enabledAlternativeGroups[rule.id]?.contains(Self.messageFactCheckAlternativeGroup) == true,
               let requestedMessageFactCheckConfig,
               requestedMessageFactCheckConfig.normalized != manifestMessageFactCheckConfig {
                return BinaryRuleStatus(
                    rule: rule,
                    state: .partial,
                    detail: "Runtime hook is installed with a different Message Fact Check config."
                )
            }
            if let parameterValue,
               let parameter = rule.parameter {
                let manifestValue = manifest?.parameterValues[rule.id] ?? parameter.defaultValue
                if parameterValue != manifestValue {
                    return BinaryRuleStatus(
                        rule: rule,
                        state: .partial,
                        detail: "Runtime hook is installed with a different parameter value."
                    )
                }
            }
            return BinaryRuleStatus(
                rule: rule,
                state: .applied,
                detail: installedDetail
            )
        }
        if manifestEnabled && !installed {
            return BinaryRuleStatus(
                rule: rule,
                state: .partial,
                detail: "Recorded in manifest, but runtime hook files are incomplete."
            )
        }
        if !manifestEnabled && installed {
            return BinaryRuleStatus(
                rule: rule,
                state: .notApplied,
                detail: "Runtime hook is installed for other rules; this rule is disabled."
            )
        }
        return BinaryRuleStatus(
            rule: rule,
            state: .notApplied,
            detail: "Runtime hook is not installed."
        )
    }

    private func runtimeRuleHasLegacyDiskPatch(
        _ rule: BinaryPatchRule,
        data: Data,
        matchCache: BinaryPatternMatchCache? = nil,
        parameterValue: UInt64?
    ) -> Bool {
        for replacement in rule.replacements where replacement.mode == .toggle && !replacement.isEmptyPatch {
            let originalCount = matchCache?.count(of: replacement.original)
                ?? data.nonOverlappingRanges(of: replacement.original).count
            guard originalCount < replacement.expectedOccurrences else {
                continue
            }
            let patched = replacement.patchedData(parameterValue: parameterValue)
            let exactCount = matchCache?.count(of: patched) ?? data.nonOverlappingRanges(of: patched).count
            if exactCount >= replacement.expectedOccurrences {
                return true
            }
            if flexiblePatchedRanges(for: replacement, in: data, matchCache: matchCache).count >= replacement.expectedOccurrences {
                return true
            }
        }
        return false
    }

    private func transform(
        data: Data,
        rule: BinaryPatchRule,
        enabled: Bool,
        parameterValue: UInt64? = nil,
        enabledAlternativeGroups: Set<String>? = nil
    ) throws -> Data {
        let parameterValue = parameterValue ?? rule.parameter?.defaultValue
        var next = data
        let toggleGroups = Self.toggleReplacementGroups(for: rule)
        for replacement in rule.replacements where replacement.mode == .normalize {
            if let enabledAlternativeGroups,
               !enabledAlternativeGroups.contains(replacement.alternativeGroup) {
                continue
            }
            let fromRanges = next.nonOverlappingRanges(of: replacement.original)
            if fromRanges.isEmpty {
                continue
            }
            guard fromRanges.count == replacement.expectedOccurrences else {
                throw PatchgramError.binaryPatternAmbiguous(replacement.id, fromRanges.count)
            }
            for range in fromRanges.reversed() {
                next.replaceSubrange(range, with: replacement.patchedData(parameterValue: parameterValue))
            }
        }

        for group in toggleGroups {
            let groupEnabled = enabled && (enabledAlternativeGroups?.contains(group.id) ?? true)
            if group.isParameterGated {
                next = try transformParameterGated(
                    data: next,
                    group: group,
                    enabled: groupEnabled,
                    parameterValue: parameterValue
                )
            } else {
                next = try transform(
                    data: next,
                    group: group,
                    enabled: groupEnabled && group.isEnabled(for: parameterValue),
                    parameterValue: parameterValue,
                    allowMissingWhenDisabling: enabledAlternativeGroups != nil
                )
            }
        }
        return next
    }

    private func normalizeRuntimeRuleDiskBytes(
        data: Data,
        rule: BinaryPatchRule,
        parameterValue: UInt64?
    ) throws -> Data {
        guard runtimeRuleHasLegacyDiskPatch(rule, data: data, parameterValue: parameterValue ?? rule.parameter?.defaultValue) else {
            return data
        }
        return try transform(
            data: data,
            rule: rule,
            enabled: false,
            parameterValue: parameterValue
        )
    }

    private func transformParameterGated(
        data: Data,
        group: BinaryToggleReplacementGroup,
        enabled: Bool,
        parameterValue: UInt64? = nil
    ) throws -> Data {
        let active = enabled ? group.activeReplacements(for: parameterValue) : []
        guard active.count <= 1 else {
            throw PatchgramError.binaryPatternAmbiguous(group.id, active.count)
        }
        let inactive = group.replacements.filter { replacement in
            !active.contains(replacement)
        }
        if let desired = active.first {
            if data.nonOverlappingRanges(of: desired.patchedData(parameterValue: parameterValue)).count >= desired.expectedOccurrences {
                return data
            }
            if let patchedAlternative = firstMatchedPatchedReplacement(inactive, in: data, parameterValue: parameterValue) {
                return try replace(
                    replacement: patchedAlternative.replacement,
                    fromRanges: patchedAlternative.ranges,
                    with: desired.patchedData(parameterValue: parameterValue),
                    in: data
                )
            }
            let originalRanges = data.nonOverlappingRanges(of: desired.original)
            guard !originalRanges.isEmpty else {
                throw PatchgramError.binaryPatternNotFound(group.id)
            }
            return try replace(
                replacement: desired,
                fromRanges: originalRanges,
                with: desired.patchedData(parameterValue: parameterValue),
                in: data
            )
        }

        guard let patched = firstMatchedPatchedReplacement(group.replacements, in: data, parameterValue: parameterValue) else {
            if group.replacements.contains(where: {
                data.nonOverlappingRanges(of: $0.original).count >= $0.expectedOccurrences
            }) {
                return data
            }
            throw PatchgramError.binaryPatternNotFound(group.id)
        }
        return try replace(
            replacement: patched.replacement,
            fromRanges: patched.ranges,
            with: patched.replacement.original,
            in: data
        )
    }

    private func firstMatchedPatchedReplacement(
        _ replacements: [BinaryReplacement],
        in data: Data,
        parameterValue: UInt64?
    ) -> (replacement: BinaryReplacement, ranges: [Range<Data.Index>])? {
        for replacement in replacements {
            let ranges = data.nonOverlappingRanges(of: replacement.patchedData(parameterValue: parameterValue))
            if ranges.count >= replacement.expectedOccurrences {
                return (replacement, ranges)
            }
            let flexible = flexiblePatchedRanges(for: replacement, in: data)
            if flexible.count >= replacement.expectedOccurrences {
                return (replacement, flexible)
            }
        }
        return nil
    }

    private func replace(
        replacement: BinaryReplacement,
        fromRanges: [Range<Data.Index>],
        with bytes: Data,
        in data: Data
    ) throws -> Data {
        guard fromRanges.count == replacement.expectedOccurrences else {
            throw PatchgramError.binaryPatternAmbiguous(replacement.id, fromRanges.count)
        }
        var next = data
        for range in fromRanges.reversed() {
            next.replaceSubrange(range, with: bytes)
        }
        return next
    }

    private func transform(
        data: Data,
        group: BinaryToggleReplacementGroup,
        enabled: Bool,
        parameterValue: UInt64? = nil,
        allowMissingWhenDisabling: Bool = false
    ) throws -> Data {
        var matches = group.replacements.compactMap { replacement -> (BinaryReplacement, [Range<Data.Index>])? in
            let from = enabled ? replacement.original : replacement.patchedData(parameterValue: parameterValue)
            let ranges = data.nonOverlappingRanges(of: from)
            return ranges.isEmpty ? nil : (replacement, ranges)
        }
        let oppositeMatches = group.replacements.compactMap { replacement -> (BinaryReplacement, [Range<Data.Index>])? in
            let opposite = enabled ? replacement.patchedData(parameterValue: parameterValue) : replacement.original
            let ranges = data.nonOverlappingRanges(of: opposite)
            return ranges.count >= replacement.expectedOccurrences ? (replacement, ranges) : nil
        }
        if matches.isEmpty && !oppositeMatches.isEmpty {
            return data
        }
        if matches.isEmpty {
            matches = group.replacements.compactMap { replacement -> (BinaryReplacement, [Range<Data.Index>])? in
                let ranges = flexiblePatchedRanges(for: replacement, in: data)
                return ranges.isEmpty ? nil : (replacement, ranges)
            }
        }
        matches = Self.collapsedEquivalentMatches(matches, enabled: enabled, parameterValue: parameterValue)

        guard matches.count == 1, let match = matches.first else {
            if matches.isEmpty {
                if !enabled && allowMissingWhenDisabling {
                    return data
                }
                throw PatchgramError.binaryPatternNotFound(group.id)
            }
            throw PatchgramError.binaryPatternAmbiguous(group.id, matches.count)
        }
        let (replacement, fromRanges) = match
        guard fromRanges.count == replacement.expectedOccurrences else {
            throw PatchgramError.binaryPatternAmbiguous(replacement.id, fromRanges.count)
        }
        let to = enabled ? replacement.patchedData(parameterValue: parameterValue) : replacement.original
        var next = data
        for range in fromRanges.reversed() {
            next.replaceSubrange(range, with: to)
        }
        return next
    }

    private static func collapsedEquivalentMatches(
        _ matches: [(BinaryReplacement, [Range<Data.Index>])],
        enabled: Bool,
        parameterValue: UInt64?
    ) -> [(BinaryReplacement, [Range<Data.Index>])] {
        guard matches.count > 1, let first = matches.first else { return matches }
        let firstRanges = first.1
        let firstBytes = enabled
            ? first.0.original
            : first.0.patchedData(parameterValue: parameterValue)
        let allEquivalent = matches.allSatisfy { match in
            let replacement = match.0
            let ranges = match.1
            let bytes = enabled
                ? replacement.original
                : replacement.patchedData(parameterValue: parameterValue)
            return ranges == firstRanges && bytes == firstBytes
        }
        return allEquivalent ? [first] : matches
    }

    private func flexiblePatchedRanges(
        for replacement: BinaryReplacement,
        in data: Data,
        matchCache: BinaryPatternMatchCache? = nil
    ) -> [Range<Data.Index>] {
        guard let template = replacement.template else { return [] }
        let anchor: Data
        let anchorOffset: Int
        switch template {
        case .creditsStarsAmount:
            anchor = Data(hexString: "010080d2fd7bc1a8c0035fd6")
            anchorOffset = 16
        case .creditsTonAmount:
            anchor = Data(hexString: "e1031faafd7bc1a8c0035fd6")
            anchorOffset = 16
        }
        let anchorRanges = matchCache?.ranges(of: anchor) ?? data.nonOverlappingRanges(of: anchor)
        return anchorRanges.compactMap { anchorRange in
            guard anchorRange.lowerBound >= anchorOffset else { return nil }
            let lowerBound = anchorRange.lowerBound - anchorOffset
            let upperBound = lowerBound + replacement.original.count
            guard upperBound <= data.count else { return nil }
            let range = lowerBound..<upperBound
            return replacement.matchesPatchedData(data.subdata(in: range)) ? range : nil
        }
    }

    private static func toggleReplacementGroups(for rule: BinaryPatchRule) -> [BinaryToggleReplacementGroup] {
        var ids: [String] = []
        var replacementsByGroup: [String: [BinaryReplacement]] = [:]
        for replacement in rule.replacements where replacement.mode == .toggle {
            let group = replacement.alternativeGroup
            if replacementsByGroup[group] == nil {
                ids.append(group)
            }
            replacementsByGroup[group, default: []].append(replacement)
        }
        return ids.map { id in
            BinaryToggleReplacementGroup(id: id, replacements: replacementsByGroup[id] ?? [])
        }
    }

    private func ensureBackup(for inspection: AppInspection, executableURL: URL) throws {
        let backup = backupURL(for: inspection)
        guard !fileManager.fileExists(atPath: backup.path) else { return }
        try fileManager.copyItem(at: executableURL, to: backup)
    }

    private func verifyPatchWriteAccess(for inspection: AppInspection) throws {
        let executableURL = patchTargetExecutableURL(for: inspection)
        try verifyWritableFileOrCreatableParent(executableURL)
        try verifyWritableDirectory(executableURL.deletingLastPathComponent())

        let backup = backupURL(for: inspection)
        try verifyWritableFileOrCreatableParent(backup)

        let contents = inspection.appURL.appendingPathComponent("Contents", isDirectory: true)
        try verifyWritableDirectory(contents)
        try verifyWritableDirectoryOrCreatableParent(manifestURL(for: inspection.appURL).deletingLastPathComponent())
        try verifyWritableFileOrCreatableParent(manifestURL(for: inspection.appURL))
        try verifyWritableDirectoryOrCreatableParent(runtimeConfigURL(for: inspection.appURL).deletingLastPathComponent())
        try verifyWritableFileOrCreatableParent(runtimeConfigURL(for: inspection.appURL))
        try verifyWritableDirectoryOrCreatableParent(frameworksURL(for: inspection.appURL))
        try verifyWritableFileOrCreatableParent(botVerificationRuntimeHookDylibURL(for: inspection.appURL))
    }

    private func verifyWritableFileOrCreatableParent(_ url: URL) throws {
        if fileManager.fileExists(atPath: url.path) {
            guard fileManager.isWritableFile(atPath: url.path) else {
                throw PatchgramError.missingWriteAccess(url.path)
            }
            do {
                let handle = try FileHandle(forWritingTo: url)
                try handle.close()
            } catch {
                throw PatchgramError.missingWriteAccess(url.path)
            }
        }
        try verifyWritableDirectoryOrCreatableParent(url.deletingLastPathComponent())
    }

    private func verifyWritableDirectoryOrCreatableParent(_ url: URL) throws {
        if fileManager.fileExists(atPath: url.path) {
            try verifyWritableDirectory(url)
            return
        }
        try verifyWritableDirectoryOrCreatableParent(url.deletingLastPathComponent())
    }

    private func verifyWritableDirectory(_ url: URL) throws {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            throw PatchgramError.missingWriteAccess(url.path)
        }
        guard fileManager.isWritableFile(atPath: url.path) else {
            throw PatchgramError.missingWriteAccess(url.path)
        }

        let probeURL = url.appendingPathComponent(".patchgram-access-check-\(UUID().uuidString)")
        do {
            try Data().write(to: probeURL, options: .atomic)
            try fileManager.removeItem(at: probeURL)
        } catch {
            try? fileManager.removeItem(at: probeURL)
            throw PatchgramError.missingWriteAccess(url.path)
        }
    }

    private func backupURL(for inspection: AppInspection) -> URL {
        inspection.executableURL.deletingLastPathComponent()
            .appendingPathComponent(inspection.executableURL.lastPathComponent + ".patchgram-original")
    }

    private func patchTargetExecutableURL(for inspection: AppInspection) -> URL {
        let wrapped = wrappedExecutableURL(for: inspection)
        if fileManager.fileExists(atPath: wrapped.path), executableIsRuntimeHookWrapper(inspection.executableURL) {
            return wrapped
        }
        return inspection.executableURL
    }

    private func wrappedExecutableURL(for inspection: AppInspection) -> URL {
        inspection.executableURL.deletingLastPathComponent()
            .appendingPathComponent(inspection.executableURL.lastPathComponent + Self.wrappedExecutableSuffix)
    }

    private func frameworksURL(for appURL: URL) -> URL {
        appURL.appendingPathComponent("Contents/Frameworks", isDirectory: true)
    }

    private func botVerificationRuntimeHookDylibURL(for appURL: URL) -> URL {
        frameworksURL(for: appURL).appendingPathComponent(Self.botVerificationRuntimeHookDylibName)
    }

    private func deprecatedBotVerificationRuntimeHookDylibURL(for appURL: URL) -> URL {
        frameworksURL(for: appURL).appendingPathComponent(Self.deprecatedBotVerificationRuntimeHookDylibName)
    }

    private func deprecatedBotVerificationRuntimeHookSourceURL(for appURL: URL) -> URL {
        frameworksURL(for: appURL).appendingPathComponent(Self.deprecatedBotVerificationRuntimeHookSourceName)
    }

    private func deprecatedBotVerificationRuntimeHookTemporarySourceURL(for appURL: URL) -> URL {
        frameworksURL(for: appURL)
            .appendingPathComponent(Self.deprecatedBotVerificationRuntimeHookSourceName + ".tmp")
    }

    private func runtimeConfigURL(for appURL: URL) -> URL {
        appURL.appendingPathComponent("Contents/Resources", isDirectory: true)
            .appendingPathComponent(Self.runtimeConfigName)
    }

    private func deprecatedBotVerificationRuntimeConfigURL(for appURL: URL) -> URL {
        appURL.appendingPathComponent("Contents/Resources", isDirectory: true)
            .appendingPathComponent(Self.deprecatedBotVerificationRuntimeConfigName)
    }

    private func legacyRuntimeHookDylibURL(for appURL: URL) -> URL {
        frameworksURL(for: appURL).appendingPathComponent(Self.legacyRuntimeHookDylibName)
    }

    private func legacyRuntimeHookSourceURL(for appURL: URL) -> URL {
        frameworksURL(for: appURL).appendingPathComponent(Self.legacyRuntimeHookSourceName)
    }

    private func legacyRuntimeHookTemporarySourceURL(for appURL: URL) -> URL {
        frameworksURL(for: appURL).appendingPathComponent(Self.legacyRuntimeHookSourceName + ".tmp")
    }

    private func executableIsRuntimeHookWrapper(_ url: URL) -> Bool {
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { return false }
        return text.contains(Self.wrapperMarker)
    }

    private func executableIsBotVerificationRuntimeHookWrapper(_ url: URL) -> Bool {
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { return false }
        return text.contains(Self.wrapperMarker)
            && (
                text.contains(Self.botVerificationRuntimeHookDylibName)
                    || text.contains(Self.deprecatedBotVerificationRuntimeHookDylibName)
            )
    }

    private func executableIsLegacyRuntimeHookWrapper(_ url: URL) -> Bool {
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { return false }
        return text.contains(Self.wrapperMarker)
            && text.contains(Self.legacyRuntimeHookDylibName)
    }

    private func removeLegacyRuntimeHook(for inspection: AppInspection) throws -> Bool {
        var changed = false
        let wrapped = wrappedExecutableURL(for: inspection)
        if executableIsLegacyRuntimeHookWrapper(inspection.executableURL) {
            guard fileManager.fileExists(atPath: wrapped.path) else {
                throw PatchgramError.missingExecutable(wrapped.path)
            }
            try fileManager.removeItem(at: inspection.executableURL)
            try fileManager.moveItem(at: wrapped, to: inspection.executableURL)
            try makeExecutable(at: inspection.executableURL)
            changed = true
        } else if fileManager.fileExists(atPath: wrapped.path),
                  !executableIsBotVerificationRuntimeHookWrapper(inspection.executableURL) {
            try fileManager.removeItem(at: wrapped)
            changed = true
        }
        for url in [
            legacyRuntimeHookDylibURL(for: inspection.appURL),
            legacyRuntimeHookSourceURL(for: inspection.appURL),
            legacyRuntimeHookTemporarySourceURL(for: inspection.appURL)
        ] where fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
            changed = true
        }
        return changed
    }

    private func isRuntimeRule(_ rule: BinaryPatchRule) -> Bool {
        Self.runtimeRuleIds.contains(rule.id)
    }

    private func isRuntimeMemoryRule(_ rule: BinaryPatchRule) -> Bool {
        Self.runtimeMemoryPatchRuleIds.contains(rule.id)
    }

    private func runtimeRuleMessage(for change: BinaryPatchRuleChange, changed: Bool) -> String {
        if change.enabled {
            return changed
                ? "Enabled \(change.rule.title)."
                : "\(change.rule.title) was already enabled."
        }
        return changed
            ? "Disabled \(change.rule.title)."
            : "\(change.rule.title) was already disabled."
    }

    private func runtimeHookInstalled(for inspection: AppInspection) -> Bool {
        executableIsBotVerificationRuntimeHookWrapper(inspection.executableURL)
            && fileManager.fileExists(atPath: wrappedExecutableURL(for: inspection).path)
            && fileManager.fileExists(atPath: botVerificationRuntimeHookDylibURL(for: inspection.appURL).path)
            && fileManager.fileExists(atPath: runtimeConfigURL(for: inspection.appURL).path)
    }

    private func synchronizeRuntimeHook(
        for inspection: AppInspection,
        manifest: BinaryPatchManifest
    ) throws -> RuntimeHookSyncResult {
        guard manifest.enabledRuleIds.contains(where: { Self.runtimeRuleIds.contains($0) }) else {
            let changed = try removeRuntimeHook(for: inspection)
            return RuntimeHookSyncResult(changed: changed, changedExecutable: changed)
        }
        var changed = false
        var executableChanged = false
        try fileManager.createDirectory(
            at: frameworksURL(for: inspection.appURL),
            withIntermediateDirectories: true
        )
        try fileManager.createDirectory(
            at: runtimeConfigURL(for: inspection.appURL).deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        changed = try writeRuntimeConfig(manifest: manifest, appURL: inspection.appURL) || changed
        changed = try removeDeprecatedBotVerificationRuntimeFiles(for: inspection.appURL) || changed
        let dylibChanged = try compileRuntimeHook(appURL: inspection.appURL)
        changed = dylibChanged || changed
        executableChanged = dylibChanged || executableChanged
        let wrapperChanged = try ensureRuntimeWrapper(for: inspection)
        changed = wrapperChanged || changed
        executableChanged = wrapperChanged || executableChanged
        return RuntimeHookSyncResult(changed: changed, changedExecutable: executableChanged)
    }

    private func removeDeprecatedBotVerificationRuntimeFiles(for appURL: URL) throws -> Bool {
        var changed = false
        for url in [
            deprecatedBotVerificationRuntimeHookDylibURL(for: appURL),
            deprecatedBotVerificationRuntimeHookSourceURL(for: appURL),
            deprecatedBotVerificationRuntimeHookTemporarySourceURL(for: appURL),
            deprecatedBotVerificationRuntimeConfigURL(for: appURL)
        ] where fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
            changed = true
        }
        return changed
    }

    private func removeRuntimeHook(for inspection: AppInspection) throws -> Bool {
        var changed = false
        let wrapped = wrappedExecutableURL(for: inspection)
        if executableIsBotVerificationRuntimeHookWrapper(inspection.executableURL) {
            guard fileManager.fileExists(atPath: wrapped.path) else {
                throw PatchgramError.missingExecutable(wrapped.path)
            }
            try fileManager.removeItem(at: inspection.executableURL)
            try fileManager.moveItem(at: wrapped, to: inspection.executableURL)
            try makeExecutable(at: inspection.executableURL)
            changed = true
        }

        for url in [
            botVerificationRuntimeHookDylibURL(for: inspection.appURL),
            deprecatedBotVerificationRuntimeHookDylibURL(for: inspection.appURL),
            deprecatedBotVerificationRuntimeHookSourceURL(for: inspection.appURL),
            deprecatedBotVerificationRuntimeHookTemporarySourceURL(for: inspection.appURL),
            runtimeConfigURL(for: inspection.appURL),
            deprecatedBotVerificationRuntimeConfigURL(for: inspection.appURL)
        ] where fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
            changed = true
        }
        return changed
    }

    private func writeRuntimeConfig(manifest: BinaryPatchManifest, appURL: URL) throws -> Bool {
        let enabled = Set(manifest.enabledRuleIds)
        let messageGroups = enabledAlternativeGroups(
            for: Self.messageSettingsRuleId,
            manifest: manifest
        )
        let adsGroups = enabledAlternativeGroups(
            for: Self.disableAdsRuleId,
            manifest: manifest
        )
        let monetizationGroups = enabledAlternativeGroups(
            for: Self.disableMonetizationRuleId,
            manifest: manifest
        )
        let botConfig = (
            manifest.botVerificationConfigs[Self.botVerificationRuleId]
                ?? BotVerificationPatchConfig.defaultConfig
        ).normalized
        let ratingConfig = (
            manifest.customLevelRatingConfigs[Self.customLevelRatingRuleId]
                ?? CustomLevelRatingPatchConfig.defaultConfig
        ).normalized
        let identityConfig = (
            manifest.selfIdentityConfigs[Self.selfIdentityOverrideRuleId]
                ?? SelfIdentityPatchConfig.defaultConfig
        ).normalized
        let identityGroups = enabledAlternativeGroups(
            for: Self.selfIdentityOverrideRuleId,
            manifest: manifest
        )
        let localPersonalChannelConfig = (
            manifest.localPersonalChannelConfigs[Self.localPersonalChannelRuleId]
                ?? LocalPersonalChannelPatchConfig.defaultConfig
        ).normalized
        let fragmentPhoneConfig = (
            manifest.fragmentPhoneConfigs[Self.fragmentPhoneRuleId]
                ?? FragmentPhonePatchConfig.defaultConfig
        ).normalized
        let starGiftSpoofConfig = (manifest.starGiftSpoofConfig ?? StarGiftSpoofPatchConfig.defaultConfig).normalized
        let starGiftUniqueSpoofConfig = (manifest.starGiftUniqueSpoofConfig ?? StarGiftUniqueSpoofPatchConfig.defaultConfig).normalized
        let customListUsernamesConfig = (
            manifest.customListUsernamesConfigs[Self.customListUsernamesRuleId]
                ?? CustomListUsernamesPatchConfig.defaultConfig
        ).normalized
        let messageFactCheckConfig = (
            manifest.messageFactCheckConfigs[Self.messageSettingsRuleId]
                ?? MessageFactCheckPatchConfig.defaultConfig
        ).normalized
        let visualPeerBadgeRule = BinaryPatchRuleCatalog.rule(id: Self.visualPeerBadgeRuleId)
        let tonRule = BinaryPatchRuleCatalog.rule(id: Self.customTonRuleId)
        let starsRule = BinaryPatchRuleCatalog.rule(id: Self.customStarsRuleId)
        // Pre-computed to keep the big PatchgramRuntimeConfigFile initializer under the Swift
        // type-checker's complexity ceiling — the 8 inline monetization closures plus ~50 fields
        // otherwise "unable to type-check in reasonable time" (tipped over by the overlay flag).
        let monetizationOn: (String) -> Bool = { sub in
            enabled.contains(Self.disableMonetizationRuleId)
                && monetizationGroups.contains { Self.disableMonetizationSubpatchId(for: $0) == sub }
        }
        let messageSettingsOn = enabled.contains(Self.messageSettingsRuleId)
        let identityOverrideOn = enabled.contains(Self.selfIdentityOverrideRuleId)
        let adsOn = enabled.contains(Self.disableAdsRuleId)
        let customPhoneNumberOn = identityOverrideOn && identityGroups.contains("self_identity.custom_phone_number")
        let customUserIdOn = identityOverrideOn && identityGroups.contains("self_identity.custom_user_id")
        let messageTypingOn = messageSettingsOn && messageGroups.contains(Self.messageTypingAlternativeGroup)
        let messageReadReceiptsOn = messageSettingsOn && messageGroups.contains(where: Self.isMessageReadReceiptsAlternativeGroup)
        let messageLocalDraftsOn = messageSettingsOn && messageGroups.contains(Self.messageLocalDraftsAlternativeGroup)
        let messageFactCheckOn = messageSettingsOn && messageGroups.contains(Self.messageFactCheckAlternativeGroup)
        let messageNoForwardsCopyOn = messageSettingsOn && messageGroups.contains(Self.messageNoForwardsAllowCopyAlternativeGroup)
        let messageDisableTtlOn = messageSettingsOn && messageGroups.contains(Self.messageTtlDisableAlternativeGroup)
        let scheduledSendOn = enabled.contains(Self.scheduledSendRuleId) || (messageSettingsOn && messageGroups.contains(Self.scheduledSendAlternativeGroup))
        let disableTelegramAdsOn = adsOn && adsGroups.contains(Self.disableTelegramAdsAlternativeGroup)
        let disableProxySponsorOn = adsOn && adsGroups.contains(where: Self.isProxySponsorAlternativeGroup)
        let visualPeerBadgeValue: UInt64 = manifest.parameterValues[Self.visualPeerBadgeRuleId] ?? visualPeerBadgeRule?.parameter?.defaultValue ?? 1
        let customTonValue: UInt64 = manifest.parameterValues[Self.customTonRuleId] ?? tonRule?.parameter?.defaultValue ?? 999
        let customStarsValue: UInt64 = manifest.parameterValues[Self.customStarsRuleId] ?? starsRule?.parameter?.defaultValue ?? 999
        let localPersonalChannelId: UInt64 = localPersonalChannelConfig.channelId ?? 0
        let fragmentPhonePurchaseDate = fragmentPhoneConfig.purchaseDateUnix ?? 0
        // Account freeze drives an only-me bot verification with fixed values, overriding any user
        // bot-verification config; bot verification is then on whenever freeze or the bot rule is.
        let accountFreezeOn = enabled.contains(Self.accountFreezeRuleId)
        let effectiveBotConfig = accountFreezeOn
            ? BotVerificationPatchConfig(
                targetMode: .onlySelf,
                preset: .custom,
                customEmojiId: Self.accountFreezeBotVerificationEmojiId,
                description: Self.accountFreezeBotVerificationDescription
            )
            : botConfig
        let botVerificationOn = accountFreezeOn || enabled.contains(Self.botVerificationRuleId)
        let payload = PatchgramRuntimeConfigFile(
            version: 1,
            enabledRuleIds: manifest.enabledRuleIds.filter { Self.runtimeRuleIds.contains($0) }.sorted(),
            enabledAlternativeGroups: manifest.enabledAlternativeGroups.filter { Self.runtimeRuleIds.contains($0.key) },
            parameterValues: manifest.parameterValues.filter { Self.runtimeRuleIds.contains($0.key) },
            botVerificationEnabled: botVerificationOn,
            botVerificationTargetMode: effectiveBotConfig.targetMode,
            botVerificationCustomEmojiId: effectiveBotConfig.customEmojiId,
            botVerificationDescription: effectiveBotConfig.description,
            customLevelRatingEnabled: enabled.contains(Self.customLevelRatingRuleId),
            customLevelRatingTargetMode: ratingConfig.targetMode,
            customLevelRatingLevel: ratingConfig.level,
            customLevelRatingRating: ratingConfig.rating,
            customLevelRatingCurrentLevelRating: ratingConfig.currentLevelRating,
            customLevelRatingNextLevelRating: ratingConfig.nextLevelRating,
            hideSelfPhoneEnabled: enabled.contains(Self.hideSelfPhoneRuleId),
            selfIdentityOverrideEnabled: enabled.contains(Self.selfIdentityOverrideRuleId),
            customPhoneNumberEnabled: customPhoneNumberOn,
            customPhoneNumberTargetMode: identityConfig.phoneTargetMode,
            customUserIdEnabled: customUserIdOn,
            customUserIdTargetMode: identityConfig.userIdTargetMode,
            selfIdentityOverridePhone: identityConfig.phone,
            selfIdentityOverrideUserId: identityConfig.userId,
            localPersonalChannelEnabled: enabled.contains(Self.localPersonalChannelRuleId),
            localPersonalChannelTargetMode: localPersonalChannelConfig.targetMode,
            localPersonalChannelReference: localPersonalChannelConfig.channelReference,
            localPersonalChannelId: localPersonalChannelId,
            localPersonalChannelMessageId: localPersonalChannelConfig.messageId,
            fragmentPhoneEnabled: enabled.contains(Self.fragmentPhoneRuleId),
            fragmentPhoneTargetMode: fragmentPhoneConfig.targetMode,
            fragmentPhonePurchaseDate: fragmentPhonePurchaseDate,
            fragmentPhoneCurrency: fragmentPhoneConfig.currency,
            fragmentPhoneAmount: fragmentPhoneConfig.amount,
            fragmentPhoneCryptoCurrency: fragmentPhoneConfig.cryptoCurrency,
            fragmentPhoneCryptoAmount: fragmentPhoneConfig.cryptoAmount,
            fragmentPhoneUrl: fragmentPhoneConfig.url,
            giftSpoofEnabled: enabled.contains(Self.starGiftSpoofRuleId),
            giftSpoofTargetMode: starGiftSpoofConfig.targetMode,
            giftSpoofSenderId: starGiftSpoofConfig.senderId,
            giftSpoofSenderPeerType: starGiftSpoofConfig.senderPeerType,
            giftSpoofDate: starGiftSpoofConfig.dateUnix ?? 0,
            giftSpoofGiftId: starGiftSpoofConfig.giftId,
            giftSpoofStickerId: starGiftSpoofConfig.stickerEmojiId,
            giftSpoofStars: starGiftSpoofConfig.stars,
            giftSpoofConvertStars: starGiftSpoofConfig.convertStars,
            giftSpoofCaption: starGiftSpoofConfig.caption.trimmingCharacters(in: .whitespacesAndNewlines),
            giftSpoofAvailable: starGiftSpoofConfig.available,
            giftSpoofTotal: starGiftSpoofConfig.total,
            giftSpoofLimited: starGiftSpoofConfig.forceLimited,
            giftSpoofUpgrade: starGiftSpoofConfig.forceUpgrade,
            giftSpoofAuction: starGiftSpoofConfig.forceAuction,
            giftSpoofUpgradePrice: starGiftSpoofConfig.upgradePrice,
            giftSpoofAuctionTitle: starGiftSpoofConfig.auctionTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            giftSpoofGiftNum: starGiftSpoofConfig.giftNumber,
            giftSpoofWasRefunded: starGiftSpoofConfig.wasRefunded,
            giftFakeTransferEnabled: enabled.contains(Self.giftFakeTransferRuleId),
            giftUniqueEnabled: enabled.contains(Self.starGiftUniqueSpoofRuleId),
            giftUniqueTargetMode: starGiftUniqueSpoofConfig.targetMode,
            giftUniqueGiftName: starGiftUniqueSpoofConfig.giftName,
            giftUniqueTitle: starGiftUniqueSpoofConfig.title,
            giftUniqueNum: starGiftUniqueSpoofConfig.numValue,
            giftUniqueHasBackdrop: starGiftUniqueSpoofConfig.hasBackdrop,
            giftUniqueBackdropName: starGiftUniqueSpoofConfig.backdropName,
            giftUniqueBackdropCenter: starGiftUniqueSpoofConfig.backdropCenterColor,
            giftUniqueBackdropEdge: starGiftUniqueSpoofConfig.backdropEdgeColor,
            giftUniqueBackdropPattern: starGiftUniqueSpoofConfig.backdropPatternColor,
            giftUniqueBackdropText: starGiftUniqueSpoofConfig.backdropTextColor,
            giftUniqueBackdropRarity: starGiftUniqueSpoofConfig.backdropRarityPermille,
            giftUniqueModelName: starGiftUniqueSpoofConfig.modelName,
            giftUniqueModelEmojiId: starGiftUniqueSpoofConfig.modelEmojiId,
            giftUniqueModelRarity: starGiftUniqueSpoofConfig.modelRarityPermille,
            giftUniqueSymbolName: starGiftUniqueSpoofConfig.symbolName,
            giftUniqueSymbolEmojiId: starGiftUniqueSpoofConfig.symbolEmojiId,
            giftUniqueSymbolRarity: starGiftUniqueSpoofConfig.symbolRarityPermille,
            giftUniqueTotalUpgraded: starGiftUniqueSpoofConfig.totalUpgradedValue,
            giftUniqueMaxUpgraded: starGiftUniqueSpoofConfig.maxUpgradedValue,
            giftUniqueDate: starGiftUniqueSpoofConfig.dateUnix ?? 0,
            giftUniqueSenderId: starGiftUniqueSpoofConfig.senderId,
            giftUniqueSenderPeerType: starGiftUniqueSpoofConfig.senderPeerType,
            giftUniqueOwnerId: starGiftUniqueSpoofConfig.ownerId,
            giftUniqueOwnerPeerType: starGiftUniqueSpoofConfig.ownerPeerType,
            giftUniqueHostId: starGiftUniqueSpoofConfig.hostId,
            giftUniqueHostPeerType: starGiftUniqueSpoofConfig.hostPeerType,
            giftUniqueOwnerAddress: starGiftUniqueSpoofConfig.ownerAddress,
            giftUniqueValueAmount: starGiftUniqueSpoofConfig.valueAmount,
            giftUniqueValueUsdAmount: starGiftUniqueSpoofConfig.valueUsdAmount,
            giftUniqueValueCurrency: starGiftUniqueSpoofConfig.valueCurrency,
            giftUniqueLastResaleAmount: starGiftUniqueSpoofConfig.lastResaleAmount,
            giftUniqueLastResaleCurrency: starGiftUniqueSpoofConfig.lastResaleCurrency,
            giftUniqueLastResaleDate: starGiftUniqueSpoofConfig.lastResaleDateUnix,
            giftShowHiddenEnabled: enabled.contains(Self.showHiddenGiftsRuleId),
            customListUsernamesEnabled: enabled.contains(Self.customListUsernamesRuleId),
            customListUsernamesPayload: customListUsernamesConfig.runtimePayload,
            visualPeerBadgeEnabled: enabled.contains(Self.visualPeerBadgeRuleId),
            visualPeerBadgeValue: visualPeerBadgeValue,
            noPremiumAnimEnabled: enabled.contains(Self.noPremiumAnimRuleId),
            disableSpoilersEnabled: enabled.contains(Self.disableSpoilersRuleId),
            customTonEnabled: enabled.contains(Self.customTonRuleId),
            customTonValue: customTonValue,
            customStarsEnabled: enabled.contains(Self.customStarsRuleId),
            customStarsValue: customStarsValue,
            forceOfflineEnabled: enabled.contains(Self.forceOfflineRuleId),
            openLinksWithoutWarningEnabled: enabled.contains(Self.openLinksWithoutWarningRuleId),
            noPhoneOnAddEnabled: enabled.contains(Self.noPhoneOnAddRuleId),
            callbackHoverEnabled: enabled.contains(Self.callbackHoverRuleId),
            blockTypingEnabled: enabled.contains(Self.blockTypingRuleId),
            blockReadMessagesEnabled: enabled.contains(Self.blockReadMessagesRuleId),
            hideBlockedEnabled: enabled.contains(Self.hideBlockedRuleId),
            messageSettingsEnabled: enabled.contains(Self.messageSettingsRuleId),
            messageTypingEnabled: messageTypingOn,
            messageReadReceiptsEnabled: messageReadReceiptsOn,
            messageLocalDraftsEnabled: messageLocalDraftsOn,
            messageFactCheckEnabled: messageFactCheckOn,
            messageFactCheckText: messageFactCheckConfig.text,
            messageFactCheckCountry: messageFactCheckConfig.country,
            messageFactCheckHash: messageFactCheckConfig.hash,
            messageFactCheckNeedCheck: messageFactCheckConfig.needCheck,
            messageNoForwardsCopyEnabled: messageNoForwardsCopyOn,
            messageDisableTtlEnabled: messageDisableTtlOn,
            overlayEnabled: enabled.contains(Self.overlayRuleId),
            mtprotoLoggerEnabled: enabled.contains(Self.mtprotoLoggerRuleId),
            localPremiumEnabled: enabled.contains(Self.localPremiumRuleId),
            accountFreezeEnabled: enabled.contains(Self.accountFreezeRuleId),
            disableMonetizationEnabled: enabled.contains(Self.disableMonetizationRuleId),
            disableMonetizationAppConfigEnabled: monetizationOn("app_config"),
            disableMonetizationPremiumUIEnabled: monetizationOn("premium_ui"),
            disableMonetizationGiftsEnabled: monetizationOn("gifts"),
            disableMonetizationPaidReactionsEnabled: monetizationOn("paid_reactions"),
            disableMonetizationEmojiStatusesEnabled: monetizationOn("emoji_statuses"),
            disableMonetizationStarsTonCollectiblesEnabled: monetizationOn("stars_ton_collectibles"),
            disableMonetizationBoostsEnabled: monetizationOn("boosts"),
            disableMonetizationReadReceiptsEnabled: monetizationOn("read_receipts"),
            scheduledSendEnabled: scheduledSendOn,
            sensitiveBlurEnabled: enabled.contains(Self.sensitiveBlurRuleId),
            hideStoriesEnabled: enabled.contains(Self.hideStoriesRuleId),
            disableAdsEnabled: enabled.contains(Self.disableAdsRuleId),
            disableTelegramAdsEnabled: disableTelegramAdsOn,
            disableProxySponsorEnabled: disableProxySponsorOn
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(payload)
        let url = runtimeConfigURL(for: appURL)
        if fileManager.fileExists(atPath: url.path),
           (try? Data(contentsOf: url)) == data {
            return false
        }
        try data.write(to: url, options: .atomic)
        return true
    }

    private func enabledAlternativeGroups(for ruleId: String, manifest: BinaryPatchManifest) -> Set<String> {
        if let groups = manifest.enabledAlternativeGroups[ruleId] {
            return Set(groups)
        }
        if ruleId == Self.selfIdentityOverrideRuleId,
           manifest.enabledRuleIds.contains(ruleId) {
            return [
                "self_identity.custom_phone_number",
                "self_identity.custom_user_id"
            ]
        }
        guard let rule = BinaryPatchRuleCatalog.rule(id: ruleId) else { return [] }
        return Set(rule.replacements.map(\.alternativeGroup))
    }

    private func compileRuntimeHook(appURL: URL) throws -> Bool {
        let source = Data(runtimeHookSource().utf8)
        let dylibURL = botVerificationRuntimeHookDylibURL(for: appURL)
        // Up-to-date only if the existing dylib embeds the CURRENT content-hash marker.
        // Any source change yields a new hash ⇒ this fails ⇒ recompile.
        if fileManager.fileExists(atPath: dylibURL.path),
           let existing = try? Data(contentsOf: dylibURL),
           existing.range(of: Data(runtimeHookBuildMarker().utf8)) != nil {
            return false
        }
        let sourceURL = fileManager.temporaryDirectory
            .appendingPathComponent("PatchgramRuntime-\(UUID().uuidString)")
        try source.write(to: sourceURL, options: .atomic)
        defer {
            try? fileManager.removeItem(at: sourceURL)
        }

        // Link the bundled rlottie static lib when present so the overlay can render .tgs animated
        // stickers. Gated by a macro the engine source checks; absent on older apps → .tgs disabled,
        // PNG still works. The .a comes from the app (not the signed patch bundle), so the bundle
        // format/manifest is unchanged.
        let rlottieLib = PatchgramResourceProvider.shared.rlottieLibraryURL()
        let haveRlottie = rlottieLib.map { fileManager.fileExists(atPath: $0.path) } ?? false

        var arguments: [String] = [
            "-dynamiclib",
            "-arch", "arm64",
            // Compiled as Objective-C so the dylib can host a native AppKit overlay
            // (the existing C body is a strict subset; the only `id`/`self`/`@`/`IMP`
            // tokens in it live in strings/comments). ARC keeps the overlay memory-safe.
            "-x", "objective-c",
            "-fobjc-arc",
            "-O2",
            "-mmacosx-version-min=12.0",
            "-framework", "Foundation",
            "-framework", "AppKit",
            "-framework", "QuartzCore"
        ]
        if haveRlottie {
            arguments.append("-DPATCHGRAM_HAVE_RLOTTIE=1")
        }
        arguments += ["-o", dylibURL.path, sourceURL.path]
        if haveRlottie, let lib = rlottieLib {
            // `-x none` resets the input type: the earlier `-x objective-c` is sticky and would
            // otherwise make clang try to COMPILE the .a archive as ObjC source (it hangs parsing
            // the binary). With `-x none` the .a is treated by extension → linked, not compiled.
            // librlottie.a is C++ and the engine gunzips via zlib → also pull in libc++ and libz.
            arguments += ["-x", "none", lib.path, "-lc++", "-lz"]
        }

        let result = try runLoggedProcess(
            executableURL: URL(fileURLWithPath: "/usr/bin/clang"),
            arguments: arguments,
            appURL: appURL,
            label: "Compile Patchgram runtime hook"
        )
        guard result.exitCode == 0 else {
            throw PatchgramError.processFailed(
                "clang failed while compiling Patchgram runtime hook. Full log: `\(patchLogURL(for: appURL).path)`. \(result.output)"
            )
        }
        return true
    }

    private func ensureRuntimeWrapper(for inspection: AppInspection) throws -> Bool {
        if executableIsLegacyRuntimeHookWrapper(inspection.executableURL) {
            _ = try removeLegacyRuntimeHook(for: inspection)
        } else if executableIsRuntimeHookWrapper(inspection.executableURL),
                  !executableIsBotVerificationRuntimeHookWrapper(inspection.executableURL) {
            throw PatchgramError.processFailed("Unsupported Patchgram runtime wrapper is already installed.")
        }

        let wrapped = wrappedExecutableURL(for: inspection)
        let wrapper = runtimeWrapperScript(for: inspection)
        let wrapperData = Data(wrapper.utf8)

        if executableIsBotVerificationRuntimeHookWrapper(inspection.executableURL) {
            guard fileManager.fileExists(atPath: wrapped.path) else {
                throw PatchgramError.missingExecutable(wrapped.path)
            }
            if (try? Data(contentsOf: inspection.executableURL)) == wrapperData {
                return false
            }
            try wrapperData.write(to: inspection.executableURL, options: .atomic)
            try makeExecutable(at: inspection.executableURL)
            return true
        }

        if fileManager.fileExists(atPath: wrapped.path) {
            try fileManager.removeItem(at: wrapped)
        }
        try fileManager.moveItem(at: inspection.executableURL, to: wrapped)
        try wrapperData.write(to: inspection.executableURL, options: .atomic)
        try makeExecutable(at: inspection.executableURL)
        return true
    }

    private func runtimeWrapperScript(for inspection: AppInspection) -> String {
        let dylibPath = botVerificationRuntimeHookDylibURL(for: inspection.appURL).path
        let configPath = runtimeConfigURL(for: inspection.appURL).path
        return """
        #!/bin/sh
        \(Self.wrapperMarker)
        PATCHGRAM_DYLIB=\(shellQuoted(dylibPath))
        export PATCHGRAM_RUNTIME_CONFIG=\(shellQuoted(configPath))
        export PATCHGRAM_BOT_VERIFICATION_CONFIG=\(shellQuoted(configPath))
        if [ -n "${DYLD_INSERT_LIBRARIES:-}" ]; then
          export DYLD_INSERT_LIBRARIES="$PATCHGRAM_DYLIB:$DYLD_INSERT_LIBRARIES"
        else
          export DYLD_INSERT_LIBRARIES="$PATCHGRAM_DYLIB"
        fi
        exec "$0\(Self.wrappedExecutableSuffix)" "$@"
        """
    }

    private func runtimeMemoryPatchDefinitionsSource() -> String {
        struct RuntimePatch {
            let ruleId: String
            let replacement: BinaryReplacement
        }

        let patches = BinaryPatchRuleCatalog.rules
            .filter { Self.runtimeMemoryPatchRuleIds.contains($0.id) }
            .flatMap { rule in
                rule.replacements
                    .filter { $0.mode == .toggle && !$0.isEmptyPatch }
                    .map { RuntimePatch(ruleId: rule.id, replacement: $0) }
            }

        func cIdentifier(_ value: String) -> String {
            value.map { character in
                character.isLetter || character.isNumber ? String(character) : "_"
            }
            .joined()
        }

        func cString(_ value: String) -> String {
            value
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
        }

        func cBytes(_ data: Data) -> String {
            data.map { String(format: "0x%02x", $0) }.joined(separator: ", ")
        }

        func cValues(_ values: Set<UInt64>?) -> String {
            (values ?? [])
                .sorted()
                .map { "\($0)ULL" }
                .joined(separator: ", ")
        }

        func templateKind(_ template: BinaryPatchTemplate?) -> String {
            switch template {
            case .creditsStarsAmount:
                return "PatchgramTemplateCreditsStars"
            case .creditsTonAmount:
                return "PatchgramTemplateCreditsTon"
            case nil:
                return "PatchgramTemplateNone"
            }
        }

        var lines: [String] = []
        for (index, patch) in patches.enumerated() {
            let prefix = "g_runtime_patch_\(index)_\(cIdentifier(patch.replacement.id))"
            lines.append("static const uint8_t \(prefix)_original[] = { \(cBytes(patch.replacement.original)) };")
            lines.append("static const uint8_t \(prefix)_patched[] = { \(cBytes(patch.replacement.patched)) };")
            if let mask = patch.replacement.originalMask {
                lines.append("static const uint8_t \(prefix)_mask[] = { \(cBytes(mask)) };")
            }
            if let values = patch.replacement.enabledParameterValues {
                lines.append("static const uint64_t \(prefix)_enabled_values[] = { \(cValues(values)) };")
            }
        }
        lines.append("static const struct PatchgramMemoryPatch g_memory_patches[] = {")
        for (index, patch) in patches.enumerated() {
            let prefix = "g_runtime_patch_\(index)_\(cIdentifier(patch.replacement.id))"
            let valuesPointer = patch.replacement.enabledParameterValues == nil ? "NULL" : "\(prefix)_enabled_values"
            let valuesCount = patch.replacement.enabledParameterValues?.count ?? 0
            let maskPointer = patch.replacement.originalMask == nil ? "NULL" : "\(prefix)_mask"
            lines.append("    { \"\(cString(patch.ruleId))\", \"\(cString(patch.replacement.alternativeGroup))\", \"\(cString(patch.replacement.id))\", \(prefix)_original, sizeof(\(prefix)_original), \(prefix)_patched, sizeof(\(prefix)_patched), \(maskPointer), \(patch.replacement.expectedOccurrences), \(templateKind(patch.replacement.template)), \(valuesPointer), \(valuesCount) },")
        }
        lines.append("};")
        lines.append("static const size_t g_memory_patch_count = sizeof(g_memory_patches) / sizeof(g_memory_patches[0]);")
        return lines.joined(separator: "\n")
    }

    // Content hash of the source template → the build marker. Deterministic (the template is
    // generated from rules/offsets), so identical source ⇒ identical marker.
    private func runtimeHookBuildMarker() -> String {
        let template = runtimeHookSourceTemplate()
        let digest = SHA256.hash(data: Data(template.utf8))
        let hex = digest.prefix(10).map { String(format: "%02x", $0) }.joined()
        return Self.runtimeHookMarkerPrefix + hex
    }

    private func runtimeHookSource() -> String {
        runtimeHookSourceTemplate()
            .replacingOccurrences(of: Self.runtimeHookMarkerPlaceholder, with: runtimeHookBuildMarker())
    }

    private func runtimeHookSourceTemplate() -> String {
        PatchgramResourceProvider.shared.engineTemplate()
            .replacingOccurrences(
                of: Self.runtimeHookMemoryPatchTablePlaceholder,
                with: runtimeMemoryPatchDefinitionsSource()
            )
            .replacingOccurrences(
                of: Self.runtimeHookTLSchemaPlaceholder,
                with: PatchgramResourceProvider.shared.tlSchemaInc() ?? Self.tlSchemaStub
            )
    }

    private func makeExecutable(at url: URL) throws {
        var attributes = try fileManager.attributesOfItem(atPath: url.path)
        let current = (attributes[.posixPermissions] as? NSNumber)?.intValue ?? 0o755
        attributes[.posixPermissions] = NSNumber(value: current | 0o755)
        try fileManager.setAttributes([.posixPermissions: attributes[.posixPermissions] as Any], ofItemAtPath: url.path)
    }

    private func sign(appURL: URL) throws {
        let result = try runLoggedProcess(
            executableURL: URL(fileURLWithPath: "/usr/bin/codesign"),
            arguments: ["--force", "--deep", "--sign", "-", appURL.path],
            appURL: appURL,
            label: "Ad-hoc codesign"
        )
        guard result.exitCode == 0 else {
            throw PatchgramError.processFailed(
                "codesign failed. Full log: `\(patchLogURL(for: appURL).path)`. \(result.output)"
            )
        }
    }

    private func runLoggedProcess(
        executableURL: URL,
        arguments: [String],
        appURL: URL,
        label: String
    ) throws -> ProcessResult {
        appendPatchLog(
            "BEGIN \(label)\nCOMMAND: \(processDescription(executableURL: executableURL, arguments: arguments))",
            appURL: appURL
        )
        let start = Date()
        let result = try processRunner.run(executableURL: executableURL, arguments: arguments)
        appendPatchLog(
            "END \(label)\nEXIT: \(result.exitCode)\nDURATION: \(durationString(since: start))\nOUTPUT:\n\(result.output.isEmpty ? "<empty>" : result.output)",
            appURL: appURL
        )
        return result
    }

    private func patchLogURL(for appURL: URL) -> URL {
        appURL.appendingPathComponent("Contents/Resources", isDirectory: true)
            .appendingPathComponent(Self.patchLogName)
    }

    private func hookLogURL(for appURL: URL) -> URL {
        appURL.appendingPathComponent("Contents/Resources", isDirectory: true)
            .appendingPathComponent(Self.hookLogName)
    }

    private func manifestURL(for appURL: URL) -> URL {
        appURL.appendingPathComponent("Contents/Resources", isDirectory: true)
            .appendingPathComponent("PatchgramManifest.json")
    }

    private func diagnosticStatuses(
        data: Data,
        inspection: AppInspection,
        parameterValues: [String: UInt64]
    ) -> String {
        let matchCache = BinaryPatternMatchCache(data: data)
        return BinaryPatchRuleCatalog.rules
            .map {
                if isRuntimeRule($0) {
                    return "\($0.id): \(RuleApplicationState.partial.rawValue) - Runtime hook status is checked from manifest and hook files."
                }
                let current = status(
                    for: $0,
                    data: data,
                    matchCache: matchCache,
                    parameterValue: parameterValues[$0.id]
                )
                return "\(current.id): \(current.state.rawValue) - \(current.detail)"
            }
            .joined(separator: "\n")
    }

    private func appendPatchLog(_ message: String, appURL: URL) {
        let url = patchLogURL(for: appURL)
        do {
            let directory = url.deletingLastPathComponent()
            if !fileManager.fileExists(atPath: directory.path) {
                try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            }
            let timestamp = ISO8601DateFormatter().string(from: Date())
            let data = Data("\n[\(timestamp)] \(message)\n".utf8)
            if fileManager.fileExists(atPath: url.path), let handle = try? FileHandle(forWritingTo: url) {
                try handle.seekToEnd()
                try handle.write(contentsOf: data)
                try handle.close()
            } else {
                try data.write(to: url, options: .atomic)
            }
        } catch {
            // Logging must never make a patch operation fail.
        }
    }

    private func processDescription(executableURL: URL, arguments: [String]) -> String {
        ([executableURL.path] + arguments).map(shellQuoted).joined(separator: " ")
    }

    private func durationString(since start: Date) -> String {
        String(format: "%.3fs", Date().timeIntervalSince(start))
    }

    private func parameterValues(from changes: [BinaryPatchRuleChange]) -> [String: UInt64] {
        Dictionary(uniqueKeysWithValues: changes.compactMap { change in
            guard let parameterValue = change.parameterValue else { return nil }
            return (change.rule.id, parameterValue)
        })
    }

    private func shellQuoted(_ value: String) -> String {
        guard !value.isEmpty else { return "''" }
        let safe = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_+-=./:@")
        if value.unicodeScalars.allSatisfy({ safe.contains($0) }) {
            return value
        }
        return "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }

    private func readManifest(appURL: URL) throws -> BinaryPatchManifest? {
        let url = manifestURL(for: appURL)
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(BinaryPatchManifest.self, from: data)
    }

    private func writeManifest(_ manifest: BinaryPatchManifest, appURL: URL) throws {
        var manifest = manifest
        // Record the definition digest of every enabled rule from the current catalog, so a later
        // rescan can tell that a fetched update changed an enabled rule's definition.
        let rulesById = Dictionary(
            BinaryPatchRuleCatalog.rules.map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        manifest.appliedDefinitionHashes = Dictionary(
            uniqueKeysWithValues: manifest.enabledRuleIds.compactMap { id in
                rulesById[id].map { (id, $0.definitionDigest) }
            }
        )
        let url = manifestURL(for: appURL)
        let resources = url.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: resources.path) {
            try fileManager.createDirectory(at: resources, withIntermediateDirectories: true)
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let encoded = try encoder.encode(manifest)
        try encoded.write(to: url, options: .atomic)
    }

    private func updateManifest(appURL: URL, applying changes: [BinaryPatchRuleChange]) throws {
        let manifest = try manifest(appURL: appURL, applying: changes)
        try writeManifest(manifest, appURL: appURL)
    }

    private func manifest(appURL: URL, applying changes: [BinaryPatchRuleChange]) throws -> BinaryPatchManifest {
        var manifest = try readManifest(appURL: appURL)
            ?? BinaryPatchManifest(updatedAt: Date(), enabledRuleIds: [])
        var enabled = Set(manifest.enabledRuleIds)
        var parameters = manifest.parameterValues
        var botVerificationConfigs = manifest.botVerificationConfigs
        var customLevelRatingConfigs = manifest.customLevelRatingConfigs
        var selfIdentityConfigs = manifest.selfIdentityConfigs
        var localPersonalChannelConfigs = manifest.localPersonalChannelConfigs
        var fragmentPhoneConfigs = manifest.fragmentPhoneConfigs
        var starGiftSpoofConfig = manifest.starGiftSpoofConfig
        var starGiftUniqueSpoofConfig = manifest.starGiftUniqueSpoofConfig
        var customListUsernamesConfigs = manifest.customListUsernamesConfigs
        var messageFactCheckConfigs = manifest.messageFactCheckConfigs
        var enabledAlternativeGroups = manifest.enabledAlternativeGroups

        for change in changes {
            if change.enabled {
                enabled.insert(change.rule.id)
                if let groups = change.enabledAlternativeGroups {
                    enabledAlternativeGroups[change.rule.id] = groups.sorted()
                } else {
                    enabledAlternativeGroups.removeValue(forKey: change.rule.id)
                }
                if let parameterValue = change.parameterValue {
                    parameters[change.rule.id] = parameterValue
                }
                if change.rule.kind == .botVerification {
                    botVerificationConfigs[change.rule.id] = (
                        change.botVerificationConfig
                            ?? botVerificationConfigs[change.rule.id]
                            ?? BotVerificationPatchConfig.defaultConfig
                    ).normalized
                }
                if change.rule.kind == .customLevelRating {
                    customLevelRatingConfigs[change.rule.id] = (
                        change.customLevelRatingConfig
                            ?? customLevelRatingConfigs[change.rule.id]
                            ?? CustomLevelRatingPatchConfig.defaultConfig
                    ).normalized
                }
                if change.rule.kind == .selfIdentityOverride {
                    selfIdentityConfigs[change.rule.id] = (
                        change.selfIdentityConfig
                            ?? selfIdentityConfigs[change.rule.id]
                            ?? SelfIdentityPatchConfig.defaultConfig
                    ).normalized
                }
                if change.rule.kind == .localPersonalChannel {
                    localPersonalChannelConfigs[change.rule.id] = (
                        change.localPersonalChannelConfig
                            ?? localPersonalChannelConfigs[change.rule.id]
                            ?? LocalPersonalChannelPatchConfig.defaultConfig
                    ).normalized
                }
                if change.rule.kind == .fragmentPhone {
                    fragmentPhoneConfigs[change.rule.id] = (
                        change.fragmentPhoneConfig
                            ?? fragmentPhoneConfigs[change.rule.id]
                            ?? FragmentPhonePatchConfig.defaultConfig
                    ).normalized
                }
                if change.rule.kind == .starGiftSpoof {
                    starGiftSpoofConfig = (
                        change.starGiftSpoofConfig
                            ?? starGiftSpoofConfig
                            ?? StarGiftSpoofPatchConfig.defaultConfig
                    ).normalized
                }
                if change.rule.kind == .starGiftUniqueSpoof {
                    starGiftUniqueSpoofConfig = (
                        change.starGiftUniqueSpoofConfig
                            ?? starGiftUniqueSpoofConfig
                            ?? StarGiftUniqueSpoofPatchConfig.defaultConfig
                    ).normalized
                }
                if change.rule.kind == .customListUsernames {
                    customListUsernamesConfigs[change.rule.id] = (
                        change.customListUsernamesConfig
                            ?? customListUsernamesConfigs[change.rule.id]
                            ?? CustomListUsernamesPatchConfig.defaultConfig
                    ).normalized
                }
                if change.rule.id == Self.messageSettingsRuleId,
                   enabledAlternativeGroups[change.rule.id]?.contains(Self.messageFactCheckAlternativeGroup) == true {
                    messageFactCheckConfigs[change.rule.id] = (
                        change.messageFactCheckConfig
                            ?? messageFactCheckConfigs[change.rule.id]
                            ?? MessageFactCheckPatchConfig.defaultConfig
                    ).normalized
                }
            } else {
                enabled.remove(change.rule.id)
                parameters.removeValue(forKey: change.rule.id)
                botVerificationConfigs.removeValue(forKey: change.rule.id)
                customLevelRatingConfigs.removeValue(forKey: change.rule.id)
                selfIdentityConfigs.removeValue(forKey: change.rule.id)
                localPersonalChannelConfigs.removeValue(forKey: change.rule.id)
                fragmentPhoneConfigs.removeValue(forKey: change.rule.id)
                if change.rule.kind == .starGiftSpoof { starGiftSpoofConfig = nil }
                if change.rule.kind == .starGiftUniqueSpoof { starGiftUniqueSpoofConfig = nil }
                customListUsernamesConfigs.removeValue(forKey: change.rule.id)
                messageFactCheckConfigs.removeValue(forKey: change.rule.id)
                enabledAlternativeGroups.removeValue(forKey: change.rule.id)
            }
        }

        manifest.updatedAt = Date()
        manifest.enabledRuleIds = enabled.sorted()
        manifest.parameterValues = parameters.filter { enabled.contains($0.key) }
        manifest.botVerificationConfigs = botVerificationConfigs.filter { enabled.contains($0.key) }
        manifest.customLevelRatingConfigs = customLevelRatingConfigs.filter { enabled.contains($0.key) }
        manifest.selfIdentityConfigs = selfIdentityConfigs.filter { enabled.contains($0.key) }
        manifest.localPersonalChannelConfigs = localPersonalChannelConfigs.filter { enabled.contains($0.key) }
        manifest.fragmentPhoneConfigs = fragmentPhoneConfigs.filter { enabled.contains($0.key) }
        // Keep the base gift-spoof config whenever the base OR the unique patch is enabled — the unique
        // patch reuses its sender id + date.
        manifest.starGiftSpoofConfig = (enabled.contains(Self.starGiftSpoofRuleId)
            || enabled.contains(Self.starGiftUniqueSpoofRuleId)) ? starGiftSpoofConfig : nil
        manifest.starGiftUniqueSpoofConfig = enabled.contains(Self.starGiftUniqueSpoofRuleId) ? starGiftUniqueSpoofConfig : nil
        manifest.customListUsernamesConfigs = customListUsernamesConfigs.filter { enabled.contains($0.key) }
        manifest.messageFactCheckConfigs = messageFactCheckConfigs.filter { ruleId, _ in
            enabled.contains(ruleId)
                && enabledAlternativeGroups[ruleId]?.contains(Self.messageFactCheckAlternativeGroup) == true
        }
        manifest.enabledAlternativeGroups = enabledAlternativeGroups.filter { enabled.contains($0.key) }
        return manifest
    }

    private func updateManifest(
        appURL: URL,
        data: Data,
        inspection: AppInspection,
        parameterValues: [String: UInt64]
    ) throws {
        let matchCache = BinaryPatternMatchCache(data: data)
        let enabled = BinaryPatchRuleCatalog.rules
            .map {
                status(
                    for: $0,
                    data: data,
                    matchCache: matchCache,
                    parameterValue: parameterValues[$0.id]
                )
            }
            .filter { $0.state.isEnabled }
            .map(\.id)
            .sorted()
        let manifest = BinaryPatchManifest(
            updatedAt: Date(),
            enabledRuleIds: enabled,
            parameterValues: parameterValues.filter { enabled.contains($0.key) },
            botVerificationConfigs: [:],
            customLevelRatingConfigs: [:],
            selfIdentityConfigs: [:],
            localPersonalChannelConfigs: [:],
            fragmentPhoneConfigs: [:],
            customListUsernamesConfigs: [:],
            messageFactCheckConfigs: [:]
        )
        try writeManifest(manifest, appURL: appURL)
    }

    private func updateManifest(appURL: URL, desired: [String: Bool]) throws {
        let enabled = desired.filter(\.value).map(\.key).sorted()
        let manifest = BinaryPatchManifest(updatedAt: Date(), enabledRuleIds: enabled)
        try writeManifest(manifest, appURL: appURL)
    }

}

public struct ProcessResult: Hashable, Sendable {
    public let exitCode: Int32
    public let output: String
}

public protocol ProcessRunning: Sendable {
    func run(executableURL: URL, arguments: [String]) throws -> ProcessResult
}

public struct FoundationProcessRunner: ProcessRunning {
    public init() {}

    public func run(executableURL: URL, arguments: [String]) throws -> ProcessResult {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = executableURL
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        process.waitUntilExit()
        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        return ProcessResult(exitCode: process.terminationStatus, output: output)
    }
}

private extension Data {
    func nonOverlappingRanges(of needle: Data) -> [Range<Data.Index>] {
        guard !needle.isEmpty, count >= needle.count else { return [] }
        var ranges: [Range<Data.Index>] = []
        var searchStart = startIndex
        while searchStart <= endIndex - needle.count,
              let range = self.range(of: needle, options: [], in: searchStart..<endIndex) {
            ranges.append(range)
            searchStart = range.upperBound
        }
        return ranges
    }
}
