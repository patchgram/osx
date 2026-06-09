import Foundation

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

    public init(rule: BinaryPatchRule, state: RuleApplicationState, detail: String) {
        self.rule = rule
        self.state = state
        self.detail = detail
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
    var enabledAlternativeGroups: [String: [String]] = [:]

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
        enabledAlternativeGroups: [String: [String]] = [:]
    ) {
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
        case enabledAlternativeGroups
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
        enabledAlternativeGroups = try container.decodeIfPresent(
            [String: [String]].self,
            forKey: .enabledAlternativeGroups
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
    let messageSettingsEnabled: Bool
    let messageTypingEnabled: Bool
    let messageReadReceiptsEnabled: Bool
    let messageLocalDraftsEnabled: Bool
    let messageFactCheckEnabled: Bool
    let messageFactCheckText: String
    let messageFactCheckCountry: String
    let messageFactCheckHash: Int64
    let messageFactCheckNeedCheck: Bool
    let localPremiumEnabled: Bool
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
    private static let messageSettingsRuleId = "binary.messages.settings"
    private static let messageTypingAlternativeGroup = "messages.typing.disable"
    private static let messageReadReceiptsAlternativeGroupPrefix = "messages.read_receipts."
    private static let messageLocalDraftsAlternativeGroup = "messages.drafts.local_only"
    private static let scheduledSendAlternativeGroup = "messages.scheduled_send.local"
    private static let messageFactCheckAlternativeGroup = "messages.fact_check.local"
    private static let disableMonetizationRuleId = "binary.config.disable_monetization"
    private static let localPremiumRuleId = "binary.premium.local"
    private static let scheduledSendRuleId = "binary.messages.scheduled_send"
    private static let sensitiveBlurRuleId = "binary.visual.sensitive_blur"
    private static let hideStoriesRuleId = "binary.stories.hide"
    private static let disableAdsRuleId = "binary.ads.disable_sponsored"
    private static let disableTelegramAdsAlternativeGroup = "ads.telegram_ads.disable"
    private static let disableProxySponsorAlternativeGroupPrefix = "ads.proxy_sponsor."
    private static let runtimeMemoryPatchRuleIds: Set<String> = [
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
    private static let runtimeRuleIds: Set<String> = runtimeMemoryPatchRuleIds.union([
        botVerificationRuleId,
        customLevelRatingRuleId,
        hideSelfPhoneRuleId,
        selfIdentityOverrideRuleId,
        localPersonalChannelRuleId,
        fragmentPhoneRuleId,
        customListUsernamesRuleId,
        visualPeerBadgeRuleId,
        scheduledSendRuleId,
        sensitiveBlurRuleId
    ])

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
    private static let runtimeHookBuildMarker = "PATCHGRAM_RUNTIME_BUILD_20260609_DISABLE_MONETIZATION_RUNTIME"
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
        return rules.map { rule in
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
    }

    public func manifestStatuses(
        appURL: URL,
        rules: [BinaryPatchRule] = BinaryPatchRuleCatalog.rules
    ) throws -> [BinaryRuleStatus]? {
        guard let manifest = try readManifest(appURL: appURL) else { return nil }
        let enabled = Set(manifest.enabledRuleIds)
        return rules.map { rule in
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
            return BinaryRuleStatus(
                rule: rule,
                state: state,
                detail: detail
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
        return data.range(of: Data(Self.runtimeHookBuildMarker.utf8)) != nil
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
        let payload = PatchgramRuntimeConfigFile(
            version: 1,
            enabledRuleIds: manifest.enabledRuleIds.filter { Self.runtimeRuleIds.contains($0) }.sorted(),
            enabledAlternativeGroups: manifest.enabledAlternativeGroups.filter { Self.runtimeRuleIds.contains($0.key) },
            parameterValues: manifest.parameterValues.filter { Self.runtimeRuleIds.contains($0.key) },
            botVerificationEnabled: enabled.contains(Self.botVerificationRuleId),
            botVerificationTargetMode: botConfig.targetMode,
            botVerificationCustomEmojiId: botConfig.customEmojiId,
            botVerificationDescription: botConfig.description,
            customLevelRatingEnabled: enabled.contains(Self.customLevelRatingRuleId),
            customLevelRatingTargetMode: ratingConfig.targetMode,
            customLevelRatingLevel: ratingConfig.level,
            customLevelRatingRating: ratingConfig.rating,
            customLevelRatingCurrentLevelRating: ratingConfig.currentLevelRating,
            customLevelRatingNextLevelRating: ratingConfig.nextLevelRating,
            hideSelfPhoneEnabled: enabled.contains(Self.hideSelfPhoneRuleId),
            selfIdentityOverrideEnabled: enabled.contains(Self.selfIdentityOverrideRuleId),
            customPhoneNumberEnabled: enabled.contains(Self.selfIdentityOverrideRuleId)
                && identityGroups.contains("self_identity.custom_phone_number"),
            customPhoneNumberTargetMode: identityConfig.phoneTargetMode,
            customUserIdEnabled: enabled.contains(Self.selfIdentityOverrideRuleId)
                && identityGroups.contains("self_identity.custom_user_id"),
            customUserIdTargetMode: identityConfig.userIdTargetMode,
            selfIdentityOverridePhone: identityConfig.phone,
            selfIdentityOverrideUserId: identityConfig.userId,
            localPersonalChannelEnabled: enabled.contains(Self.localPersonalChannelRuleId),
            localPersonalChannelTargetMode: localPersonalChannelConfig.targetMode,
            localPersonalChannelReference: localPersonalChannelConfig.channelReference,
            localPersonalChannelId: localPersonalChannelConfig.channelId ?? 0,
            localPersonalChannelMessageId: localPersonalChannelConfig.messageId,
            fragmentPhoneEnabled: enabled.contains(Self.fragmentPhoneRuleId),
            fragmentPhoneTargetMode: fragmentPhoneConfig.targetMode,
            fragmentPhonePurchaseDate: fragmentPhoneConfig.purchaseDateUnix ?? 0,
            fragmentPhoneCurrency: fragmentPhoneConfig.currency,
            fragmentPhoneAmount: fragmentPhoneConfig.amount,
            fragmentPhoneCryptoCurrency: fragmentPhoneConfig.cryptoCurrency,
            fragmentPhoneCryptoAmount: fragmentPhoneConfig.cryptoAmount,
            fragmentPhoneUrl: fragmentPhoneConfig.url,
            customListUsernamesEnabled: enabled.contains(Self.customListUsernamesRuleId),
            customListUsernamesPayload: customListUsernamesConfig.runtimePayload,
            visualPeerBadgeEnabled: enabled.contains(Self.visualPeerBadgeRuleId),
            visualPeerBadgeValue: manifest.parameterValues[Self.visualPeerBadgeRuleId]
                ?? visualPeerBadgeRule?.parameter?.defaultValue
                ?? 1,
            noPremiumAnimEnabled: enabled.contains(Self.noPremiumAnimRuleId),
            disableSpoilersEnabled: enabled.contains(Self.disableSpoilersRuleId),
            customTonEnabled: enabled.contains(Self.customTonRuleId),
            customTonValue: manifest.parameterValues[Self.customTonRuleId] ?? tonRule?.parameter?.defaultValue ?? 999,
            customStarsEnabled: enabled.contains(Self.customStarsRuleId),
            customStarsValue: manifest.parameterValues[Self.customStarsRuleId] ?? starsRule?.parameter?.defaultValue ?? 999,
            forceOfflineEnabled: enabled.contains(Self.forceOfflineRuleId),
            openLinksWithoutWarningEnabled: enabled.contains(Self.openLinksWithoutWarningRuleId),
            noPhoneOnAddEnabled: enabled.contains(Self.noPhoneOnAddRuleId),
            callbackHoverEnabled: enabled.contains(Self.callbackHoverRuleId),
            blockTypingEnabled: enabled.contains(Self.blockTypingRuleId),
            blockReadMessagesEnabled: enabled.contains(Self.blockReadMessagesRuleId),
            messageSettingsEnabled: enabled.contains(Self.messageSettingsRuleId),
            messageTypingEnabled: enabled.contains(Self.messageSettingsRuleId)
                && messageGroups.contains(Self.messageTypingAlternativeGroup),
            messageReadReceiptsEnabled: enabled.contains(Self.messageSettingsRuleId)
                && messageGroups.contains(where: Self.isMessageReadReceiptsAlternativeGroup),
            messageLocalDraftsEnabled: enabled.contains(Self.messageSettingsRuleId)
                && messageGroups.contains(Self.messageLocalDraftsAlternativeGroup),
            messageFactCheckEnabled: enabled.contains(Self.messageSettingsRuleId)
                && messageGroups.contains(Self.messageFactCheckAlternativeGroup),
            messageFactCheckText: messageFactCheckConfig.text,
            messageFactCheckCountry: messageFactCheckConfig.country,
            messageFactCheckHash: messageFactCheckConfig.hash,
            messageFactCheckNeedCheck: messageFactCheckConfig.needCheck,
            localPremiumEnabled: enabled.contains(Self.localPremiumRuleId),
            disableMonetizationEnabled: enabled.contains(Self.disableMonetizationRuleId),
            disableMonetizationAppConfigEnabled: enabled.contains(Self.disableMonetizationRuleId)
                && monetizationGroups.contains { Self.disableMonetizationSubpatchId(for: $0) == "app_config" },
            disableMonetizationPremiumUIEnabled: enabled.contains(Self.disableMonetizationRuleId)
                && monetizationGroups.contains { Self.disableMonetizationSubpatchId(for: $0) == "premium_ui" },
            disableMonetizationGiftsEnabled: enabled.contains(Self.disableMonetizationRuleId)
                && monetizationGroups.contains { Self.disableMonetizationSubpatchId(for: $0) == "gifts" },
            disableMonetizationPaidReactionsEnabled: enabled.contains(Self.disableMonetizationRuleId)
                && monetizationGroups.contains { Self.disableMonetizationSubpatchId(for: $0) == "paid_reactions" },
            disableMonetizationEmojiStatusesEnabled: enabled.contains(Self.disableMonetizationRuleId)
                && monetizationGroups.contains { Self.disableMonetizationSubpatchId(for: $0) == "emoji_statuses" },
            disableMonetizationStarsTonCollectiblesEnabled: enabled.contains(Self.disableMonetizationRuleId)
                && monetizationGroups.contains { Self.disableMonetizationSubpatchId(for: $0) == "stars_ton_collectibles" },
            disableMonetizationBoostsEnabled: enabled.contains(Self.disableMonetizationRuleId)
                && monetizationGroups.contains { Self.disableMonetizationSubpatchId(for: $0) == "boosts" },
            disableMonetizationReadReceiptsEnabled: enabled.contains(Self.disableMonetizationRuleId)
                && monetizationGroups.contains { Self.disableMonetizationSubpatchId(for: $0) == "read_receipts" },
            scheduledSendEnabled: enabled.contains(Self.scheduledSendRuleId)
                || (enabled.contains(Self.messageSettingsRuleId)
                    && messageGroups.contains(Self.scheduledSendAlternativeGroup)),
            sensitiveBlurEnabled: enabled.contains(Self.sensitiveBlurRuleId),
            hideStoriesEnabled: enabled.contains(Self.hideStoriesRuleId),
            disableAdsEnabled: enabled.contains(Self.disableAdsRuleId),
            disableTelegramAdsEnabled: enabled.contains(Self.disableAdsRuleId)
                && adsGroups.contains(Self.disableTelegramAdsAlternativeGroup),
            disableProxySponsorEnabled: enabled.contains(Self.disableAdsRuleId)
                && adsGroups.contains(where: Self.isProxySponsorAlternativeGroup)
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
        if fileManager.fileExists(atPath: dylibURL.path),
           let existing = try? Data(contentsOf: dylibURL),
           existing.range(of: Data(Self.runtimeHookBuildMarker.utf8)) != nil {
            return false
        }
        let sourceURL = fileManager.temporaryDirectory
            .appendingPathComponent("PatchgramRuntime-\(UUID().uuidString)")
        try source.write(to: sourceURL, options: .atomic)
        defer {
            try? fileManager.removeItem(at: sourceURL)
        }

        let result = try runLoggedProcess(
            executableURL: URL(fileURLWithPath: "/usr/bin/clang"),
            arguments: [
                "-dynamiclib",
                "-arch", "arm64",
                "-x", "c",
                "-O2",
                "-mmacosx-version-min=12.0",
                "-o", dylibURL.path,
                sourceURL.path
            ],
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
            if let values = patch.replacement.enabledParameterValues {
                lines.append("static const uint64_t \(prefix)_enabled_values[] = { \(cValues(values)) };")
            }
        }
        lines.append("static const struct PatchgramMemoryPatch g_memory_patches[] = {")
        for (index, patch) in patches.enumerated() {
            let prefix = "g_runtime_patch_\(index)_\(cIdentifier(patch.replacement.id))"
            let valuesPointer = patch.replacement.enabledParameterValues == nil ? "NULL" : "\(prefix)_enabled_values"
            let valuesCount = patch.replacement.enabledParameterValues?.count ?? 0
            lines.append("    { \"\(cString(patch.ruleId))\", \"\(cString(patch.replacement.alternativeGroup))\", \"\(cString(patch.replacement.id))\", \(prefix)_original, sizeof(\(prefix)_original), \(prefix)_patched, sizeof(\(prefix)_patched), \(patch.replacement.expectedOccurrences), \(templateKind(patch.replacement.template)), \(valuesPointer), \(valuesCount) },")
        }
        lines.append("};")
        lines.append("static const size_t g_memory_patch_count = sizeof(g_memory_patches) / sizeof(g_memory_patches[0]);")
        return lines.joined(separator: "\n")
    }

    private func runtimeHookSource() -> String {
        #"""
        #include <mach-o/loader.h>
        #include <mach-o/dyld.h>
        #include <mach/mach.h>
        #include <mach/mach_vm.h>
        #include <ctype.h>
        #include <dlfcn.h>
        #include <pthread.h>
        #include <stdbool.h>
        #include <stdarg.h>
        #include <stdint.h>
        #include <stdio.h>
        #include <stdlib.h>
        #include <string.h>
        #include <sys/stat.h>
        #include <sys/mman.h>
        #include <time.h>
        #include <unistd.h>

        __attribute__((used)) static const char g_patchgram_runtime_build_marker[] = "\#(Self.runtimeHookBuildMarker)";

        #define PATCHGRAM_USER_SET_FLAGS_VMADDR 0x103fac220ULL
        #define PATCHGRAM_USER_SET_BOT_VERIFY_DETAILS_VMADDR 0x103c25284ULL
        #define PATCHGRAM_CHANNEL_SET_BOT_VERIFY_DETAILS_VMADDR 0x103fadd08ULL
        #define PATCHGRAM_PHONE_OR_HIDDEN_VALUE_MAP_VMADDR 0x10557c90cULL
        #define PATCHGRAM_IS_COLLECTIBLE_PHONE_VMADDR 0x1054d1c40ULL
        #define PATCHGRAM_HISTORY_ITEM_SET_FACTCHECK_VMADDR 0x1044e516cULL
        #define PATCHGRAM_HISTORY_ITEM_CREATE_VIEW_VMADDR 0x1044e15f8ULL
        #define PATCHGRAM_HISTORY_ITEM_HAS_UNREQUESTED_FACTCHECK_VMADDR 0x1044e58f4ULL
        #define PATCHGRAM_DATA_FACTCHECKS_REQUEST_FOR_VMADDR 0x108215c38ULL
        #define PATCHGRAM_SESSION_PRIVATE_TRY_TO_RECEIVE_VMADDR 0x105d6b498ULL
        #define PATCHGRAM_SESSION_SEND_PREPARED_VMADDR 0x105d74850ULL
        #define PATCHGRAM_MESSAGES_SEND_MESSAGE_SERIALIZE_VMADDR 0x103d35b74ULL
        #define PATCHGRAM_MESSAGES_SEND_MEDIA_SERIALIZE_VMADDR 0x101f98694ULL
        #define PATCHGRAM_FORMAT_COUNT_DECIMAL_VMADDR 0x101aea7b8ULL
        #define PATCHGRAM_PROFILE_PEER_ID_TEXT_RETURN_VMADDR 0x10542febcULL
        #define PATCHGRAM_INLINE_HOOK_SIZE 16
        #define PATCHGRAM_PEER_ID_OFFSET 0x8
        #define PATCHGRAM_USER_USERNAME_INFO_OFFSET 0x268
        #define PATCHGRAM_USER_FLAGS_OFFSET 0x218
        #define PATCHGRAM_USER_PHONE_OFFSET 0x288
        #define PATCHGRAM_USER_STARS_RATING_OFFSET 0x2c0
        #define PATCHGRAM_USER_PERSONAL_CHANNEL_ID_OFFSET 0x2d0
        #define PATCHGRAM_USER_PERSONAL_CHANNEL_MESSAGE_ID_OFFSET 0x2d8
        #define PATCHGRAM_MESSAGES_SEND_MESSAGE_FLAGS_OFFSET 0x18
        #define PATCHGRAM_MESSAGES_SEND_MESSAGE_SCHEDULE_DATE_OFFSET 0x88
        #define PATCHGRAM_MESSAGES_SEND_MEDIA_FLAGS_OFFSET 0x70
        #define PATCHGRAM_MESSAGES_SEND_MEDIA_SCHEDULE_DATE_OFFSET 0xf0
        #define PATCHGRAM_MESSAGES_FLAG_SCHEDULE_DATE 0x400U
        #define PATCHGRAM_SCHEDULED_SEND_DELAY_SECONDS 12
        #define PATCHGRAM_USER_SELF_FLAG 0x2000U
        #define PATCHGRAM_DETAILS_BOT_ID_OFFSET 0x0
        #define PATCHGRAM_DETAILS_ICON_ID_OFFSET 0x8
        #define PATCHGRAM_DETAILS_DESCRIPTION_OFFSET 0x10
        #define PATCHGRAM_QSTRING_D_OFFSET 0x0
        #define PATCHGRAM_QSTRING_PTR_OFFSET 0x8
        #define PATCHGRAM_QSTRING_SIZE_OFFSET 0x10
        #define PATCHGRAM_PHONE_OR_HIDDEN_VALUE_USER_OFFSET 0x10
        #define PATCHGRAM_TEXT_WITH_ENTITIES_ENTITIES_OFFSET 0x18
        #define PATCHGRAM_TEXT_WITH_ENTITIES_SIZE 0x30
        #define PATCHGRAM_QT_ARRAY_DATA_POINTER_SIZE 0x18
        #define PATCHGRAM_PEER_ID_VALUE_MASK 0x0000ffffffffffffULL
        #define PATCHGRAM_PEER_ID_TYPE_SHIFT 48
        #define PATCHGRAM_MAX_DESCRIPTION_UTF8 1024
        #define PATCHGRAM_MAX_DESCRIPTION_UTF16 512
        #define PATCHGRAM_MAX_PHONE_UTF8 128
        #define PATCHGRAM_MAX_PHONE_UTF16 64
        #define PATCHGRAM_MAX_FRAGMENT_TEXT_UTF8 256
        #define PATCHGRAM_MAX_FRAGMENT_PHONE_UTF8 128
        #define PATCHGRAM_MAX_USERNAME_UTF8 4096
        #define PATCHGRAM_MAX_USERNAME_UTF16 4096
        #define PATCHGRAM_MAX_CUSTOM_USERNAMES 32
        #define PATCHGRAM_USERNAME_INFO_VECTOR_OFFSET 0x0
        #define PATCHGRAM_USERNAME_INFO_EDITABLE_INDEX_OFFSET 0x18
        #define PATCHGRAM_MAX_FACT_CHECK_TEXT_UTF8 1024
        #define PATCHGRAM_MAX_FACT_CHECK_TEXT_UTF16 1024
        #define PATCHGRAM_MAX_FACT_CHECK_COUNTRY_UTF16 256
        #define PATCHGRAM_GENERATED_DETAILS_SIZE 0x80
        #define PATCHGRAM_MAX_MEMORY_PATCH_OCCURRENCES 16
        #define PATCHGRAM_MAX_TRACKED_USER_PEERS 1024
        #define PATCHGRAM_MAX_TRACKED_FRAGMENT_REQUESTS 64
        #define PATCHGRAM_MAX_TRACKED_FACT_CHECK_REQUESTS 64
        #define PATCHGRAM_MAX_FORCED_FACT_CHECK_ITEMS 4096
        #define PATCHGRAM_MAX_USERNAME_TL_REPLACEMENTS 16
        #define PATCHGRAM_SERIALIZED_REQUEST_BODY_POSITION 8
        #define PATCHGRAM_REQUEST_DATA_REQUEST_ID_OFFSET 0x30
        #define PATCHGRAM_RESPONSE_REQUEST_ID_OFFSET 0x20
        #define PATCHGRAM_RESPONSE_SIZE 0x28
        #define PATCHGRAM_QVECTOR_D_OFFSET 0x0
        #define PATCHGRAM_QVECTOR_PTR_OFFSET 0x8
        #define PATCHGRAM_QVECTOR_SIZE_OFFSET 0x10
        #define PATCHGRAM_SESSION_PRIVATE_DATA_OFFSET 0x28
        #define PATCHGRAM_SESSION_DATA_RECEIVED_BEGIN_OFFSET 0x120
        #define PATCHGRAM_SESSION_DATA_RECEIVED_END_OFFSET 0x128
        #define PATCHGRAM_TL_FRAGMENT_GET_COLLECTIBLE_INFO 0xbe1e85baU
        #define PATCHGRAM_TL_INPUT_COLLECTIBLE_PHONE 0xa2e214a4U
        #define PATCHGRAM_TL_INPUT_COLLECTIBLE_USERNAME 0xe39460a9U
        #define PATCHGRAM_TL_FRAGMENT_COLLECTIBLE_INFO 0x6ebdff91U
        #define PATCHGRAM_TL_MESSAGES_GET_FACT_CHECK 0xb9cdc5eeU
        #define PATCHGRAM_TL_FACT_CHECK 0xb89bfccfU
        #define PATCHGRAM_TL_TEXT_WITH_ENTITIES 0x751f3146U
        #define PATCHGRAM_TL_VECTOR 0x1cb5c415U
        #define PATCHGRAM_TL_ACCOUNT_CHECK_USERNAME 0x2714d86cU
        #define PATCHGRAM_TL_ACCOUNT_UPDATE_USERNAME 0x3e0bdd7cU
        #define PATCHGRAM_TL_ACCOUNT_REORDER_USERNAMES 0xef500eabU
        #define PATCHGRAM_TL_ACCOUNT_TOGGLE_USERNAME 0x58d6b376U
        #define PATCHGRAM_TL_USERS_GET_USERS 0x0d91a548U
        #define PATCHGRAM_TL_USERS_GET_FULL_USER 0xb60f5918U
        #define PATCHGRAM_TL_USER 0x31774388U
        #define PATCHGRAM_TL_USER_FULL 0x06cbe645U
        #define PATCHGRAM_TL_USERS_USER_FULL 0x3b6d152eU
        #define PATCHGRAM_TL_UPDATE_USER_NAME 0xa7848924U
        #define PATCHGRAM_TL_USERNAME 0xb4073647U
        #define PATCHGRAM_MESSAGE_FACTCHECK_TEXT_OFFSET 0x0
        #define PATCHGRAM_MESSAGE_FACTCHECK_COUNTRY_OFFSET 0x30
        #define PATCHGRAM_MESSAGE_FACTCHECK_HASH_OFFSET 0x48
        #define PATCHGRAM_MESSAGE_FACTCHECK_NEED_CHECK_OFFSET 0x50
        #define PATCHGRAM_MESSAGE_FACTCHECK_SIZE 0x58

        enum PatchgramPatchTemplate {
            PatchgramTemplateNone,
            PatchgramTemplateCreditsStars,
            PatchgramTemplateCreditsTon
        };

        struct PatchgramMemoryPatch {
            const char *rule_id;
            const char *alternative_group;
            const char *patch_id;
            const uint8_t *original;
            size_t original_size;
            const uint8_t *patched;
            size_t patched_size;
            size_t expected_occurrences;
            enum PatchgramPatchTemplate template_kind;
            const uint64_t *enabled_values;
            size_t enabled_value_count;
        };

        \#(runtimeMemoryPatchDefinitionsSource())

        static char g_log_path[4096] = {0};
        static char g_config_path[4096] = {0};
        static time_t g_config_mtime_sec = 0;
        static long g_config_mtime_nsec = 0;
        static uint64_t g_configured_icon_id = 0;
        static uint64_t g_self_user_id = 0;
        static uint16_t g_configured_description_utf16[PATCHGRAM_MAX_DESCRIPTION_UTF16] = {0};
        static int64_t g_configured_description_utf16_size = 0;
        static uint16_t g_configured_self_phone_utf16[PATCHGRAM_MAX_PHONE_UTF16] = {0};
        static int64_t g_configured_self_phone_utf16_size = 0;
        uint64_t g_configured_self_display_user_id = 0;
        uintptr_t g_profile_peer_id_text_return = 0;
        static uint8_t g_generated_user_details[PATCHGRAM_GENERATED_DETAILS_SIZE] = {0};
        static uint8_t g_generated_channel_details[PATCHGRAM_GENERATED_DETAILS_SIZE] = {0};
        static bool g_bot_verification_enabled = false;
        static bool g_custom_level_rating_enabled = false;
        static bool g_hide_self_phone_enabled = false;
        static bool g_self_identity_override_enabled = false;
        static bool g_custom_phone_number_enabled = false;
        static bool g_custom_user_id_enabled = false;
        static bool g_local_personal_channel_enabled = false;
        static bool g_fragment_phone_enabled = false;
        static bool g_custom_list_usernames_enabled = false;
        static bool g_visual_peer_badge_enabled = false;
        static bool g_force_offline_enabled = false;
        static bool g_open_links_without_warning_enabled = false;
        static bool g_callback_hover_enabled = false;
        static bool g_custom_ton_enabled = false;
        static bool g_custom_stars_enabled = false;
        static bool g_block_typing_enabled = false;
        static bool g_block_read_messages_enabled = false;
        static bool g_message_settings_enabled = false;
        static bool g_message_typing_enabled = false;
        static bool g_message_read_receipts_enabled = false;
        static bool g_message_local_drafts_enabled = false;
        static bool g_message_fact_check_enabled = false;
        static bool g_local_premium_enabled = false;
        static bool g_disable_monetization_enabled = false;
        static bool g_disable_monetization_app_config_enabled = false;
        static bool g_disable_monetization_premium_ui_enabled = false;
        static bool g_disable_monetization_gifts_enabled = false;
        static bool g_disable_monetization_paid_reactions_enabled = false;
        static bool g_disable_monetization_emoji_statuses_enabled = false;
        static bool g_disable_monetization_stars_ton_collectibles_enabled = false;
        static bool g_disable_monetization_boosts_enabled = false;
        static bool g_disable_monetization_read_receipts_enabled = false;
        static bool g_no_premium_anim_enabled = false;
        static bool g_disable_spoilers_enabled = false;
        static bool g_scheduled_send_enabled = false;
        static bool g_scheduled_send_message_hook_installed = false;
        static bool g_scheduled_send_media_hook_installed = false;
        static bool g_sensitive_blur_enabled = false;
        static bool g_hide_stories_enabled = false;
        static bool g_disable_ads_enabled = false;
        static bool g_disable_telegram_ads_enabled = false;
        static bool g_disable_proxy_sponsor_enabled = false;
        static bool g_no_phone_on_add_enabled = false;
        static uint64_t g_visual_peer_badge_value = 1;
        static uint64_t g_local_personal_channel_id = 0;
        static int32_t g_local_personal_channel_message_id = 0;
        static uint64_t g_fragment_phone_target_mode = 2;
        static int32_t g_fragment_phone_purchase_date = 0;
        static int64_t g_fragment_phone_amount = 0;
        static int64_t g_fragment_phone_crypto_amount = 0;
        static char g_fragment_phone_currency[PATCHGRAM_MAX_FRAGMENT_TEXT_UTF8] = {0};
        static char g_fragment_phone_crypto_currency[PATCHGRAM_MAX_FRAGMENT_TEXT_UTF8] = {0};
        static char g_fragment_phone_url[PATCHGRAM_MAX_FRAGMENT_TEXT_UTF8] = {0};
        static char g_fragment_phone_self_phone_utf8[PATCHGRAM_MAX_FRAGMENT_PHONE_UTF8] = {0};
        struct PatchgramUsernameConfigEntry {
            char username[PATCHGRAM_MAX_USERNAME_UTF8];
            bool collectible;
            int32_t purchase_date;
            int64_t amount;
            int64_t crypto_amount;
            char currency[PATCHGRAM_MAX_FRAGMENT_TEXT_UTF8];
            char crypto_currency[PATCHGRAM_MAX_FRAGMENT_TEXT_UTF8];
            char url[PATCHGRAM_MAX_FRAGMENT_TEXT_UTF8];
            uint16_t username_utf16[PATCHGRAM_MAX_USERNAME_UTF16];
            int64_t username_utf16_size;
        };
        static struct PatchgramUsernameConfigEntry g_custom_username_entries[PATCHGRAM_MAX_CUSTOM_USERNAMES] = {0};
        static size_t g_custom_username_entry_count = 0;
        static uint8_t *g_custom_username_vector_items = NULL;
        static size_t g_custom_username_vector_count = 0;
        static int32_t g_custom_username_vector_editable_index = -2;
        static struct PatchgramUsernameConfigEntry g_original_username_entries[PATCHGRAM_MAX_CUSTOM_USERNAMES] = {0};
        static size_t g_original_username_entry_count = 0;
        static int32_t g_original_username_editable_index = -1;
        static bool g_original_usernames_captured = false;
        static char g_message_fact_check_text[PATCHGRAM_MAX_FACT_CHECK_TEXT_UTF8] = {0};
        static char g_message_fact_check_country[PATCHGRAM_MAX_FRAGMENT_TEXT_UTF8] = {0};
        static uint16_t g_message_fact_check_text_utf16[PATCHGRAM_MAX_FACT_CHECK_TEXT_UTF16] = {0};
        static int64_t g_message_fact_check_text_utf16_size = 0;
        static uint16_t g_message_fact_check_country_utf16[PATCHGRAM_MAX_FACT_CHECK_COUNTRY_UTF16] = {0};
        static int64_t g_message_fact_check_country_utf16_size = 0;
        static int64_t g_message_fact_check_hash = 0;
        static bool g_message_fact_check_need_check = false;
        uint64_t g_self_user_id_target_mode = 2;
        static uint64_t g_custom_ton_value = 999;
        static uint64_t g_custom_stars_value = 999;
        static int32_t g_custom_level_rating_level = 1;
        static int32_t g_custom_level_rating_rating = 1000;
        static int32_t g_custom_level_rating_current_level_rating = 0;
        static int32_t g_custom_level_rating_next_level_rating = 2000;
        static bool g_warned_unknown_self_user_id = false;
        static bool g_previous_force_offline_enabled = false;
        static bool g_previous_open_links_without_warning_enabled = false;
        static bool g_previous_callback_hover_enabled = false;
        static bool g_previous_custom_ton_enabled = false;
        static bool g_previous_custom_stars_enabled = false;
        static bool g_previous_block_typing_enabled = false;
        static bool g_previous_block_read_messages_enabled = false;
        static bool g_previous_visual_peer_badge_enabled = false;
        static bool g_previous_message_settings_enabled = false;
        static bool g_previous_message_typing_enabled = false;
        static bool g_previous_message_read_receipts_enabled = false;
        static bool g_previous_message_local_drafts_enabled = false;
        static bool g_previous_message_fact_check_enabled = false;
        static bool g_previous_local_premium_enabled = false;
        static bool g_previous_disable_monetization_enabled = false;
        static bool g_previous_disable_monetization_app_config_enabled = false;
        static bool g_previous_disable_monetization_premium_ui_enabled = false;
        static bool g_previous_disable_monetization_gifts_enabled = false;
        static bool g_previous_disable_monetization_paid_reactions_enabled = false;
        static bool g_previous_disable_monetization_emoji_statuses_enabled = false;
        static bool g_previous_disable_monetization_stars_ton_collectibles_enabled = false;
        static bool g_previous_disable_monetization_boosts_enabled = false;
        static bool g_previous_disable_monetization_read_receipts_enabled = false;
        static bool g_previous_no_premium_anim_enabled = false;
        static bool g_previous_disable_spoilers_enabled = false;
        static bool g_previous_scheduled_send_enabled = false;
        static bool g_previous_sensitive_blur_enabled = false;
        static bool g_previous_hide_stories_enabled = false;
        static bool g_previous_disable_ads_enabled = false;
        static bool g_previous_disable_telegram_ads_enabled = false;
        static bool g_previous_disable_proxy_sponsor_enabled = false;
        static bool g_previous_no_phone_on_add_enabled = false;
        static uint32_t g_bot_verify_skip_nonself_logs = 0;
        static uint32_t g_bot_verify_setter_logs = 0;
        static uint32_t g_bot_verify_apply_logs = 0;
        static uint32_t g_bot_verify_generated_logs = 0;
        static uint32_t g_bot_verify_self_candidate_logs = 0;
        static uint32_t g_bot_verify_self_ignored_logs = 0;
        static uint32_t g_bot_verify_should_patch_logs = 0;
        static uint32_t g_hide_self_phone_logs = 0;
        static uint32_t g_hide_self_phone_field_logs = 0;
        static uint32_t g_self_identity_phone_logs = 0;
        static uint32_t g_local_personal_channel_logs = 0;
        static uint32_t g_fragment_phone_logs = 0;
        static uint32_t g_fragment_phone_request_logs = 0;
        static uint32_t g_fragment_phone_request_skip_logs = 0;
        static uint32_t g_fragment_phone_response_logs = 0;
        static uint32_t g_custom_usernames_logs = 0;
        static uint32_t g_custom_username_request_logs = 0;
        static uint32_t g_custom_username_response_logs = 0;
        static uint32_t g_custom_username_tl_request_diag_logs = 0;
        static uint32_t g_custom_username_tl_response_diag_logs = 0;
        static uint32_t g_custom_username_tl_patch_logs = 0;
        static uint32_t g_message_fact_check_request_logs = 0;
        static uint32_t g_message_fact_check_request_skip_logs = 0;
        static uint32_t g_message_fact_check_response_logs = 0;
        static uint32_t g_message_fact_check_trigger_logs = 0;
        static uint32_t g_message_fact_check_request_for_logs = 0;
        static uint32_t g_message_fact_check_direct_set_logs = 0;
        static uint32_t g_message_fact_check_early_layout_logs = 0;
        static uint32_t g_level_rating_logs = 0;
        static uint32_t g_scheduled_send_logs = 0;
        static void *g_tracked_user_peers[PATCHGRAM_MAX_TRACKED_USER_PEERS] = {0};
        static size_t g_tracked_user_peer_count = 0;
        static pthread_mutex_t g_tracked_user_peers_mutex = PTHREAD_MUTEX_INITIALIZER;
        struct PatchgramCollectibleRequest {
            int32_t request_id;
            char username[PATCHGRAM_MAX_USERNAME_UTF8];
        };
        static struct PatchgramCollectibleRequest g_fragment_phone_request_ids[PATCHGRAM_MAX_TRACKED_FRAGMENT_REQUESTS] = {0};
        static pthread_mutex_t g_fragment_phone_request_ids_mutex = PTHREAD_MUTEX_INITIALIZER;
        static int32_t g_custom_username_full_user_request_ids[PATCHGRAM_MAX_TRACKED_FRAGMENT_REQUESTS] = {0};
        static pthread_mutex_t g_custom_username_full_user_request_ids_mutex = PTHREAD_MUTEX_INITIALIZER;
        struct PatchgramFactCheckRequest {
            int32_t request_id;
            int32_t count;
        };
        static struct PatchgramFactCheckRequest g_fact_check_requests[PATCHGRAM_MAX_TRACKED_FACT_CHECK_REQUESTS] = {0};
        static pthread_mutex_t g_fact_check_requests_mutex = PTHREAD_MUTEX_INITIALIZER;
        struct PatchgramForcedFactCheckItem {
            void *item;
            uint8_t attempts;
        };
        static struct PatchgramForcedFactCheckItem g_forced_fact_check_items[PATCHGRAM_MAX_FORCED_FACT_CHECK_ITEMS] = {0};
        static pthread_mutex_t g_forced_fact_check_items_mutex = PTHREAD_MUTEX_INITIALIZER;
        struct PatchgramTLRange {
            size_t start;
            size_t end;
            size_t flags2_word_index;
            bool inserts_missing_field;
        };

        typedef void (*PatchgramSetBotVerifyDetailsFn)(void *, void *);
        typedef void (*PatchgramPhoneOrHiddenValueMapFn)(void *, void *);
        typedef bool (*PatchgramIsCollectiblePhoneFn)(void *);
        typedef void (*PatchgramSetUserFlagsFn)(void *, uint32_t);
        typedef void (*PatchgramMessagesSerializeFn)(void *, void *, uint64_t, uint64_t);
        typedef void (*PatchgramSessionTryToReceiveFn)(void *);
        typedef void (*PatchgramSessionSendPreparedFn)(void *, void *, int64_t);
        typedef bool (*PatchgramHistoryItemHasUnrequestedFactcheckFn)(void *);
        typedef void (*PatchgramDataFactchecksRequestForFn)(void *, void *);
        typedef void (*PatchgramHistoryItemSetFactcheckFn)(void *, void *);
        typedef void (*PatchgramHistoryItemCreateViewFn)(void *, void *, void *, void *);
        typedef void *(*PatchgramCxxOperatorNewFn)(size_t);
        struct PatchgramStarsRating {
            int32_t level;
            int32_t stars;
            int32_t thisLevelStars;
            int32_t nextLevelStars;
        };

        static PatchgramSetUserFlagsFn g_original_user_set_flags = NULL;
        static PatchgramSetBotVerifyDetailsFn g_original_user_set_bot_verify_details = NULL;
        static PatchgramSetBotVerifyDetailsFn g_original_channel_set_bot_verify_details = NULL;
        static PatchgramPhoneOrHiddenValueMapFn g_original_phone_or_hidden_value_map = NULL;
        static PatchgramIsCollectiblePhoneFn g_original_is_collectible_phone = NULL;
        static PatchgramMessagesSerializeFn g_original_messages_send_message_serialize = NULL;
        static PatchgramMessagesSerializeFn g_original_messages_send_media_serialize = NULL;
        static PatchgramSessionTryToReceiveFn g_original_session_private_try_to_receive = NULL;
        static PatchgramSessionSendPreparedFn g_original_session_send_prepared = NULL;
        static PatchgramHistoryItemHasUnrequestedFactcheckFn g_original_history_item_has_unrequested_factcheck = NULL;
        static PatchgramDataFactchecksRequestForFn g_original_data_factchecks_request_for = NULL;
        static PatchgramHistoryItemSetFactcheckFn g_history_item_set_factcheck = NULL;
        static PatchgramHistoryItemCreateViewFn g_original_history_item_create_view = NULL;
        static PatchgramCxxOperatorNewFn g_cxx_operator_new = NULL;
        void *g_original_format_count_decimal = NULL;

        enum PatchgramTargetMode {
            PatchgramTargetAll,
            PatchgramTargetAllExceptSelf,
            PatchgramTargetOnlySelf
        };

        static enum PatchgramTargetMode g_target_mode = PatchgramTargetAll;
        static enum PatchgramTargetMode g_level_rating_target_mode = PatchgramTargetAll;
        static enum PatchgramTargetMode g_self_phone_target_mode = PatchgramTargetOnlySelf;
        static enum PatchgramTargetMode g_local_personal_channel_target_mode = PatchgramTargetOnlySelf;

        static void patchgram_set_log_path(const char *config_path) {
            if (!config_path || !config_path[0]) {
                snprintf(g_log_path, sizeof(g_log_path), "%s", "/tmp/PatchgramHook.log");
                return;
            }
            snprintf(g_log_path, sizeof(g_log_path), "%s", config_path);
            char *slash = strrchr(g_log_path, '/');
            if (slash) {
                slash[1] = '\0';
                strncat(g_log_path, "PatchgramHook.log", sizeof(g_log_path) - strlen(g_log_path) - 1);
            } else {
                snprintf(g_log_path, sizeof(g_log_path), "%s", "/tmp/PatchgramHook.log");
            }
        }

        static void patchgram_log(const char *format, ...) {
            FILE *file = fopen(g_log_path[0] ? g_log_path : "/tmp/PatchgramHook.log", "a");
            if (!file) {
                return;
            }
            time_t now = time(NULL);
            struct tm tm_value;
            localtime_r(&now, &tm_value);
            char timestamp[32];
            strftime(timestamp, sizeof(timestamp), "%Y-%m-%dT%H:%M:%S", &tm_value);
            fprintf(file, "\n[%s] ", timestamp);
            va_list args;
            va_start(args, format);
            vfprintf(file, format, args);
            va_end(args);
            fprintf(file, "\n");
            fclose(file);
        }

        static bool patchgram_string_has_suffix(const char *string, const char *suffix) {
            if (!string || !suffix) {
                return false;
            }
            const size_t string_length = strlen(string);
            const size_t suffix_length = strlen(suffix);
            return string_length >= suffix_length
                && strcmp(string + string_length - suffix_length, suffix) == 0;
        }

        static bool patchgram_string_has_prefix(const char *string, const char *prefix) {
            if (!string || !prefix) {
                return false;
            }
            const size_t prefix_length = strlen(prefix);
            return strncmp(string, prefix, prefix_length) == 0;
        }

        static bool patchgram_string_contains(const char *string, const char *needle) {
            if (!string || !needle) {
                return false;
            }
            return strstr(string, needle) != NULL;
        }

        static bool patchgram_is_telegram_executable_image(const char *name) {
            return patchgram_string_has_suffix(name, "/Contents/MacOS/Telegram")
                || patchgram_string_has_suffix(name, "/Contents/MacOS/Telegram.patchgram-bin");
        }

        static void patchgram_write_absolute_branch(void *buffer, void *destination) {
            const uint32_t ldr_x16_literal_8 = 0x58000050;
            const uint32_t br_x16 = 0xd61f0200;
            memcpy(buffer, &ldr_x16_literal_8, sizeof(ldr_x16_literal_8));
            memcpy((uint8_t *)buffer + 4, &br_x16, sizeof(br_x16));
            memcpy((uint8_t *)buffer + 8, &destination, sizeof(destination));
        }

        static bool patchgram_make_writable(void *address, size_t length) {
            const size_t page_size = (size_t)getpagesize();
            const uintptr_t start = (uintptr_t)address & ~(uintptr_t)(page_size - 1);
            const uintptr_t end = ((uintptr_t)address + length + page_size - 1) & ~(uintptr_t)(page_size - 1);
            const mach_vm_size_t size = (mach_vm_size_t)(end - start);
            kern_return_t result = mach_vm_protect(
                mach_task_self(),
                (mach_vm_address_t)start,
                size,
                false,
                VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY
            );
            if (result == KERN_SUCCESS) {
                return true;
            }
            if (mprotect((void *)start, (size_t)size, PROT_READ | PROT_WRITE | PROT_EXEC) == 0) {
                return true;
            }
            patchgram_log("ERROR Could not make code page writable: mach=%d", result);
            return false;
        }

        static void patchgram_restore_executable(void *address, size_t length) {
            const size_t page_size = (size_t)getpagesize();
            const uintptr_t start = (uintptr_t)address & ~(uintptr_t)(page_size - 1);
            const uintptr_t end = ((uintptr_t)address + length + page_size - 1) & ~(uintptr_t)(page_size - 1);
            const mach_vm_size_t size = (mach_vm_size_t)(end - start);
            mach_vm_protect(
                mach_task_self(),
                (mach_vm_address_t)start,
                size,
                false,
                VM_PROT_READ | VM_PROT_EXECUTE
            );
        }

        __attribute__((naked))
        static void patchgram_format_count_decimal(void) {
            __asm__ volatile(
                "stp x15, x16, [sp, #-16]!\n"
                "adrp x15, _g_configured_self_display_user_id@PAGE\n"
                "ldr x15, [x15, _g_configured_self_display_user_id@PAGEOFF]\n"
                "cbz x15, 1f\n"
                "adrp x16, _g_profile_peer_id_text_return@PAGE\n"
                "ldr x16, [x16, _g_profile_peer_id_text_return@PAGEOFF]\n"
                "cmp x30, x16\n"
                "b.ne 1f\n"
                "adrp x16, _g_self_user_id_target_mode@PAGE\n"
                "ldr x16, [x16, _g_self_user_id_target_mode@PAGEOFF]\n"
                "cbz x16, 4f\n"
                "cmp x16, #1\n"
                "b.eq 3f\n"
                "adrp x16, _g_self_user_id@PAGE\n"
                "ldr x16, [x16, _g_self_user_id@PAGEOFF]\n"
                "cbz x16, 1f\n"
                "cmp x1, x16\n"
                "b.ne 1f\n"
                "b 4f\n"
                "3:\n"
                "adrp x16, _g_self_user_id@PAGE\n"
                "ldr x16, [x16, _g_self_user_id@PAGEOFF]\n"
                "cbz x16, 1f\n"
                "cmp x1, x16\n"
                "b.eq 1f\n"
                "4:\n"
                "mov x1, x15\n"
                "1:\n"
                "adrp x15, _g_original_format_count_decimal@PAGE\n"
                "ldr x15, [x15, _g_original_format_count_decimal@PAGEOFF]\n"
                "ldp x15, x16, [sp], #16\n"
                "adrp x16, _g_original_format_count_decimal@PAGE\n"
                "ldr x16, [x16, _g_original_format_count_decimal@PAGEOFF]\n"
                "br x16\n"
            );
        }

        static void *patchgram_allocate_trampoline(void *target) {
            void *trampoline = mmap(NULL, 4096, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON, -1, 0);
            if (trampoline == MAP_FAILED) {
                patchgram_log("ERROR Could not allocate trampoline");
                return NULL;
            }
            memcpy(trampoline, target, PATCHGRAM_INLINE_HOOK_SIZE);
            void *return_address = (uint8_t *)target + PATCHGRAM_INLINE_HOOK_SIZE;
            patchgram_write_absolute_branch((uint8_t *)trampoline + PATCHGRAM_INLINE_HOOK_SIZE, return_address);
            if (mprotect(trampoline, 4096, PROT_READ | PROT_EXEC) != 0) {
                patchgram_log("ERROR Could not mark trampoline executable");
                munmap(trampoline, 4096);
                return NULL;
            }
            __builtin___clear_cache((char *)trampoline, (char *)trampoline + 4096);
            return trampoline;
        }

        static bool patchgram_install_inline_hook(
            void *target,
            void *replacement,
            const uint8_t *expected,
            size_t expected_size,
            void **original,
            const char *name
        ) {
            if (!target || !replacement || !original) {
                return false;
            }
            if (memcmp(target, expected, expected_size) != 0) {
                patchgram_log("ERROR %s signature mismatch, hook skipped", name);
                return false;
            }
            void *trampoline = patchgram_allocate_trampoline(target);
            if (!trampoline) {
                return false;
            }
            if (!patchgram_make_writable(target, PATCHGRAM_INLINE_HOOK_SIZE)) {
                munmap(trampoline, 4096);
                return false;
            }
            uint8_t branch[PATCHGRAM_INLINE_HOOK_SIZE];
            patchgram_write_absolute_branch(branch, replacement);
            memcpy(target, branch, sizeof(branch));
            __builtin___clear_cache((char *)target, (char *)target + PATCHGRAM_INLINE_HOOK_SIZE);
            patchgram_restore_executable(target, PATCHGRAM_INLINE_HOOK_SIZE);
            *original = trampoline;
            patchgram_log("HOOK %s installed", name);
            return true;
        }

        static char *patchgram_read_file(const char *path) {
            FILE *file = fopen(path, "rb");
            if (!file) {
                return NULL;
            }
            if (fseek(file, 0, SEEK_END) != 0) {
                fclose(file);
                return NULL;
            }
            long size = ftell(file);
            if (size < 0) {
                fclose(file);
                return NULL;
            }
            rewind(file);
            char *buffer = (char *)calloc((size_t)size + 1, 1);
            if (!buffer) {
                fclose(file);
                return NULL;
            }
            fread(buffer, 1, (size_t)size, file);
            fclose(file);
            return buffer;
        }

        static uint64_t patchgram_json_u64(const char *json, const char *key, uint64_t fallback) {
            char needle[128];
            snprintf(needle, sizeof(needle), "\"%s\"", key);
            const char *found = strstr(json, needle);
            if (!found) {
                return fallback;
            }
            const char *colon = strchr(found, ':');
            if (!colon) {
                return fallback;
            }
            while (*colon && (*colon < '0' || *colon > '9')) {
                colon++;
            }
            if (!*colon) {
                return fallback;
            }
            return strtoull(colon, NULL, 10);
        }

        static int64_t patchgram_json_i64(const char *json, const char *key, int64_t fallback) {
            char needle[128];
            snprintf(needle, sizeof(needle), "\"%s\"", key);
            const char *found = strstr(json, needle);
            if (!found) {
                return fallback;
            }
            const char *colon = strchr(found, ':');
            if (!colon) {
                return fallback;
            }
            while (*colon && *colon != '-' && (*colon < '0' || *colon > '9')) {
                colon++;
            }
            if (!*colon) {
                return fallback;
            }
            return strtoll(colon, NULL, 10);
        }

        static bool patchgram_json_bool(const char *json, const char *key, bool fallback) {
            char needle[128];
            snprintf(needle, sizeof(needle), "\"%s\"", key);
            const char *found = strstr(json, needle);
            if (!found) {
                return fallback;
            }
            const char *colon = strchr(found, ':');
            if (!colon) {
                return fallback;
            }
            colon++;
            while (*colon == ' ' || *colon == '\n' || *colon == '\r' || *colon == '\t') {
                colon++;
            }
            if (strncmp(colon, "true", 4) == 0) {
                return true;
            }
            if (strncmp(colon, "false", 5) == 0) {
                return false;
            }
            return fallback;
        }

        static enum PatchgramTargetMode patchgram_parse_target_mode(const char *target_mode) {
            if (strcmp(target_mode, "allExceptSelf") == 0) {
                return PatchgramTargetAllExceptSelf;
            } else if (strcmp(target_mode, "onlySelf") == 0) {
                return PatchgramTargetOnlySelf;
            }
            return PatchgramTargetAll;
        }

        static void patchgram_set_target_mode(const char *target_mode) {
            g_target_mode = patchgram_parse_target_mode(target_mode);
        }

        static int patchgram_hex_value(char character) {
            if (character >= '0' && character <= '9') {
                return character - '0';
            }
            if (character >= 'a' && character <= 'f') {
                return character - 'a' + 10;
            }
            if (character >= 'A' && character <= 'F') {
                return character - 'A' + 10;
            }
            return -1;
        }

        static bool patchgram_json_hex4(const char *text, uint32_t *value) {
            uint32_t result = 0;
            for (int index = 0; index < 4; index++) {
                const int digit = patchgram_hex_value(text[index]);
                if (digit < 0) {
                    return false;
                }
                result = (result << 4) | (uint32_t)digit;
            }
            *value = result;
            return true;
        }

        static size_t patchgram_append_utf8_codepoint(char *out, size_t offset, size_t out_size, uint32_t codepoint) {
            if (codepoint > 0x10ffffU || (codepoint >= 0xd800U && codepoint <= 0xdfffU)) {
                codepoint = 0xfffdU;
            }
            if (codepoint <= 0x7fU) {
                if (offset + 1 >= out_size) {
                    return offset;
                }
                out[offset++] = (char)codepoint;
            } else if (codepoint <= 0x7ffU) {
                if (offset + 2 >= out_size) {
                    return offset;
                }
                out[offset++] = (char)(0xc0U | (codepoint >> 6));
                out[offset++] = (char)(0x80U | (codepoint & 0x3fU));
            } else if (codepoint <= 0xffffU) {
                if (offset + 3 >= out_size) {
                    return offset;
                }
                out[offset++] = (char)(0xe0U | (codepoint >> 12));
                out[offset++] = (char)(0x80U | ((codepoint >> 6) & 0x3fU));
                out[offset++] = (char)(0x80U | (codepoint & 0x3fU));
            } else {
                if (offset + 4 >= out_size) {
                    return offset;
                }
                out[offset++] = (char)(0xf0U | (codepoint >> 18));
                out[offset++] = (char)(0x80U | ((codepoint >> 12) & 0x3fU));
                out[offset++] = (char)(0x80U | ((codepoint >> 6) & 0x3fU));
                out[offset++] = (char)(0x80U | (codepoint & 0x3fU));
            }
            return offset;
        }

        static void patchgram_json_string(const char *json, const char *key, char *out, size_t out_size) {
            if (!out || out_size == 0) {
                return;
            }
            out[0] = '\0';
            char needle[128];
            snprintf(needle, sizeof(needle), "\"%s\"", key);
            const char *found = strstr(json, needle);
            if (!found) {
                return;
            }
            const char *colon = strchr(found, ':');
            if (!colon) {
                return;
            }
            const char *start = strchr(colon, '"');
            if (!start) {
                return;
            }
            start++;
            const char *cursor = start;
            size_t offset = 0;
            while (*cursor) {
                const char character = *cursor++;
                if (character == '"') {
                    break;
                }
                if (character != '\\') {
                    if (offset + 1 < out_size) {
                        out[offset++] = character;
                    }
                    continue;
                }
                const char escaped = *cursor++;
                if (!escaped) {
                    break;
                }
                switch (escaped) {
                case '"':
                case '\\':
                case '/':
                    if (offset + 1 < out_size) {
                        out[offset++] = escaped;
                    }
                    break;
                case 'b':
                    if (offset + 1 < out_size) {
                        out[offset++] = '\b';
                    }
                    break;
                case 'f':
                    if (offset + 1 < out_size) {
                        out[offset++] = '\f';
                    }
                    break;
                case 'n':
                    if (offset + 1 < out_size) {
                        out[offset++] = '\n';
                    }
                    break;
                case 'r':
                    if (offset + 1 < out_size) {
                        out[offset++] = '\r';
                    }
                    break;
                case 't':
                    if (offset + 1 < out_size) {
                        out[offset++] = '\t';
                    }
                    break;
                case 'u': {
                    uint32_t codepoint = 0;
                    if (!patchgram_json_hex4(cursor, &codepoint)) {
                        break;
                    }
                    cursor += 4;
                    if (codepoint >= 0xd800U && codepoint <= 0xdbffU
                        && cursor[0] == '\\'
                        && cursor[1] == 'u') {
                        uint32_t low = 0;
                        if (patchgram_json_hex4(cursor + 2, &low)
                            && low >= 0xdc00U
                            && low <= 0xdfffU) {
                            codepoint = 0x10000U + ((codepoint - 0xd800U) << 10) + (low - 0xdc00U);
                            cursor += 6;
                        }
                    }
                    offset = patchgram_append_utf8_codepoint(out, offset, out_size, codepoint);
                    break;
                }
                default:
                    if (offset + 1 < out_size) {
                        out[offset++] = escaped;
                    }
                    break;
                }
            }
            out[offset] = '\0';
        }

        static bool patchgram_utf8_continuation(const unsigned char *text, size_t offset) {
            return (text[offset] & 0xc0U) == 0x80U;
        }

        static size_t patchgram_append_utf16_codepoint(uint16_t *out, size_t offset, size_t out_size, uint32_t codepoint) {
            if (codepoint > 0x10ffffU || (codepoint >= 0xd800U && codepoint <= 0xdfffU)) {
                codepoint = 0xfffdU;
            }
            if (codepoint <= 0xffffU) {
                if (offset + 1 >= out_size) {
                    return offset;
                }
                out[offset++] = (uint16_t)codepoint;
            } else {
                if (offset + 2 >= out_size) {
                    return offset;
                }
                codepoint -= 0x10000U;
                out[offset++] = (uint16_t)(0xd800U + (codepoint >> 10));
                out[offset++] = (uint16_t)(0xdc00U + (codepoint & 0x3ffU));
            }
            return offset;
        }

        static size_t patchgram_utf8_to_utf16(const char *utf8, uint16_t *out, size_t out_size) {
            if (!utf8 || !out || out_size == 0) {
                return 0;
            }
            const unsigned char *cursor = (const unsigned char *)utf8;
            size_t offset = 0;
            while (*cursor && offset + 1 < out_size) {
                uint32_t codepoint = 0xfffdU;
                size_t advance = 1;
                const unsigned char first = cursor[0];
                const size_t remaining = strlen((const char *)cursor);
                if (first < 0x80U) {
                    codepoint = first;
                } else if (remaining >= 2
                           && (first & 0xe0U) == 0xc0U
                           && patchgram_utf8_continuation(cursor, 1)) {
                    codepoint = ((uint32_t)(first & 0x1fU) << 6)
                        | (uint32_t)(cursor[1] & 0x3fU);
                    advance = (codepoint >= 0x80U) ? 2 : 1;
                } else if (remaining >= 3
                           && (first & 0xf0U) == 0xe0U
                           && patchgram_utf8_continuation(cursor, 1)
                           && patchgram_utf8_continuation(cursor, 2)) {
                    codepoint = ((uint32_t)(first & 0x0fU) << 12)
                        | ((uint32_t)(cursor[1] & 0x3fU) << 6)
                        | (uint32_t)(cursor[2] & 0x3fU);
                    advance = (codepoint >= 0x800U) ? 3 : 1;
                } else if (remaining >= 4
                           && (first & 0xf8U) == 0xf0U
                           && patchgram_utf8_continuation(cursor, 1)
                           && patchgram_utf8_continuation(cursor, 2)
                           && patchgram_utf8_continuation(cursor, 3)) {
                    codepoint = ((uint32_t)(first & 0x07U) << 18)
                        | ((uint32_t)(cursor[1] & 0x3fU) << 12)
                        | ((uint32_t)(cursor[2] & 0x3fU) << 6)
                        | (uint32_t)(cursor[3] & 0x3fU);
                    advance = (codepoint >= 0x10000U && codepoint <= 0x10ffffU) ? 4 : 1;
                }
                offset = patchgram_append_utf16_codepoint(out, offset, out_size, codepoint);
                cursor += advance;
            }
            out[offset] = 0;
            return offset;
        }

        static void patchgram_configure_description(const char *description) {
            g_configured_description_utf16_size = (int64_t)patchgram_utf8_to_utf16(
                description,
                g_configured_description_utf16,
                PATCHGRAM_MAX_DESCRIPTION_UTF16
            );
        }

        static void patchgram_configure_self_phone(const char *phone) {
            g_configured_self_phone_utf16_size = (int64_t)patchgram_utf8_to_utf16(
                phone,
                g_configured_self_phone_utf16,
                PATCHGRAM_MAX_PHONE_UTF16
            );
        }

        static void patchgram_configure_fact_check_text(const char *text, const char *country) {
            g_message_fact_check_text_utf16_size = (int64_t)patchgram_utf8_to_utf16(
                text,
                g_message_fact_check_text_utf16,
                PATCHGRAM_MAX_FACT_CHECK_TEXT_UTF16
            );
            g_message_fact_check_country_utf16_size = (int64_t)patchgram_utf8_to_utf16(
                country,
                g_message_fact_check_country_utf16,
                PATCHGRAM_MAX_FACT_CHECK_COUNTRY_UTF16
            );
        }

        static bool patchgram_resolve_cxx_operator_new(void) {
            if (!g_cxx_operator_new) {
                g_cxx_operator_new = (PatchgramCxxOperatorNewFn)dlsym(RTLD_DEFAULT, "_Znwm");
            }
            if (!g_cxx_operator_new) {
                g_cxx_operator_new = (PatchgramCxxOperatorNewFn)dlsym(RTLD_DEFAULT, "__Znwm");
            }
            if (!g_cxx_operator_new) {
                if (g_custom_usernames_logs < 96) {
                    g_custom_usernames_logs++;
                    patchgram_log("CUSTOM USERNAMES skip reason=missing-cxx-operator-new");
                }
                return false;
            }
            return true;
        }

        static void *patchgram_cxx_operator_new(size_t byte_count) {
            if (byte_count == 0) {
                return NULL;
            }
            if (!patchgram_resolve_cxx_operator_new()) {
                return NULL;
            }
            return g_cxx_operator_new(byte_count);
        }

        static bool patchgram_username_equal(const char *lhs, const char *rhs) {
            if (!lhs || !rhs) {
                return false;
            }
            while (*lhs && *rhs) {
                if (tolower((unsigned char)*lhs) != tolower((unsigned char)*rhs)) {
                    return false;
                }
                lhs++;
                rhs++;
            }
            return *lhs == '\0' && *rhs == '\0';
        }

        static struct PatchgramUsernameConfigEntry *patchgram_custom_username_entry(const char *username) {
            if (!username || !username[0]) {
                return NULL;
            }
            struct PatchgramUsernameConfigEntry *first_match = NULL;
            for (size_t i = 0; i < g_custom_username_entry_count; i++) {
                if (patchgram_username_equal(g_custom_username_entries[i].username, username)) {
                    if (!first_match) {
                        first_match = &g_custom_username_entries[i];
                    }
                    if (g_custom_username_entries[i].collectible) {
                        return &g_custom_username_entries[i];
                    }
                }
            }
            return first_match;
        }

        static void patchgram_configure_custom_username_entry_utf16(struct PatchgramUsernameConfigEntry *entry) {
            if (!entry) {
                return;
            }
            entry->username_utf16_size = (int64_t)patchgram_utf8_to_utf16(
                entry->username,
                entry->username_utf16,
                PATCHGRAM_MAX_USERNAME_UTF16
            );
        }

        static void patchgram_configure_custom_usernames_payload(char *payload) {
            memset(g_custom_username_entries, 0, sizeof(g_custom_username_entries));
            g_custom_username_entry_count = 0;
            g_custom_username_vector_items = NULL;
            g_custom_username_vector_count = 0;
            g_custom_username_vector_editable_index = -2;
            if (!payload || !payload[0]) {
                return;
            }
            char *line = payload;
            while (line && *line && g_custom_username_entry_count < PATCHGRAM_MAX_CUSTOM_USERNAMES) {
                char *next = strchr(line, '\n');
                if (next) {
                    *next = '\0';
                    next++;
                }
                char *fields[8] = {0};
                size_t field_count = 0;
                char *cursor = line;
                while (cursor && field_count < 8) {
                    fields[field_count++] = cursor;
                    char *separator = strchr(cursor, '|');
                    if (!separator) {
                        break;
                    }
                    *separator = '\0';
                    cursor = separator + 1;
                }
                if (field_count >= 8 && fields[0] && fields[0][0]) {
                    struct PatchgramUsernameConfigEntry *entry = &g_custom_username_entries[g_custom_username_entry_count];
                    snprintf(entry->username, sizeof(entry->username), "%s", fields[0]);
                    entry->collectible = fields[1] && strcmp(fields[1], "1") == 0;
                    entry->purchase_date = (int32_t)strtol(fields[2] ? fields[2] : "0", NULL, 10);
                    snprintf(entry->currency, sizeof(entry->currency), "%s", fields[3] ? fields[3] : "USD");
                    entry->amount = strtoll(fields[4] ? fields[4] : "0", NULL, 10);
                    snprintf(entry->crypto_currency, sizeof(entry->crypto_currency), "%s", fields[5] ? fields[5] : "TON");
                    entry->crypto_amount = strtoll(fields[6] ? fields[6] : "0", NULL, 10);
                    snprintf(entry->url, sizeof(entry->url), "%s", fields[7] ? fields[7] : "");
                    patchgram_configure_custom_username_entry_utf16(entry);
                    if (entry->username_utf16_size > 0) {
                        g_custom_username_entry_count++;
                    }
                }
                line = next;
            }
            if (g_custom_usernames_logs < 24) {
                g_custom_usernames_logs++;
                patchgram_log(
                    "CUSTOM USERNAMES parsed count=%zu enabled=%d",
                    g_custom_username_entry_count,
                    g_custom_list_usernames_enabled ? 1 : 0
                );
            }
        }

        static const char *patchgram_main_image_name(void) {
            uint32_t count = _dyld_image_count();
            for (uint32_t index = 0; index < count; index++) {
                const char *name = _dyld_get_image_name(index);
                if (patchgram_is_telegram_executable_image(name)) {
                    return name;
                }
            }
            return "<unknown>";
        }

        static bool patchgram_has_telegram_executable_image(void) {
            uint32_t count = _dyld_image_count();
            for (uint32_t index = 0; index < count; index++) {
                const char *name = _dyld_get_image_name(index);
                if (patchgram_is_telegram_executable_image(name)) {
                    return true;
                }
            }
            return false;
        }

        static uintptr_t patchgram_main_slide(void) {
            uint32_t count = _dyld_image_count();
            for (uint32_t index = 0; index < count; index++) {
                const char *name = _dyld_get_image_name(index);
                if (patchgram_is_telegram_executable_image(name)) {
                    return (uintptr_t)_dyld_get_image_vmaddr_slide(index);
                }
            }
            return 0;
        }

        static void *patchgram_resolve_vmaddr(uint64_t vmaddr) {
            return (void *)(uintptr_t)(vmaddr + patchgram_main_slide());
        }

        static uint32_t patchgram_arm64_instruction(uint32_t value) {
            return value;
        }

        static void patchgram_write_u32_le(uint8_t *destination, uint32_t value) {
            destination[0] = (uint8_t)(value & 0xffU);
            destination[1] = (uint8_t)((value >> 8) & 0xffU);
            destination[2] = (uint8_t)((value >> 16) & 0xffU);
            destination[3] = (uint8_t)((value >> 24) & 0xffU);
        }

        static uint32_t patchgram_arm64_mov_wide(uint32_t register_id, uint64_t value) {
            return 0xd2800000U | ((uint32_t)(value & 0xffffULL) << 5) | register_id;
        }

        static uint32_t patchgram_arm64_mov_keep(uint32_t register_id, uint64_t value, uint32_t shift) {
            const uint32_t halfword = (shift / 16U) << 21;
            return 0xf2800000U | halfword | ((uint32_t)(value & 0xffffULL) << 5) | register_id;
        }

        static bool patchgram_render_credits_amount(
            uint64_t amount,
            bool ton,
            uint8_t *out,
            size_t out_size
        ) {
            const size_t byte_count = ton ? 128 : 72;
            if (!out || out_size != byte_count) {
                return false;
            }
            const uint64_t capped = amount > (UINT64_MAX >> 2) ? (UINT64_MAX >> 2) : amount;
            const uint64_t encoded = ton ? ((capped << 2) | 1ULL) : (capped << 2);
            patchgram_write_u32_le(out + 0, patchgram_arm64_mov_wide(0, encoded));
            patchgram_write_u32_le(out + 4, patchgram_arm64_mov_keep(0, encoded >> 16, 16));
            patchgram_write_u32_le(out + 8, patchgram_arm64_mov_keep(0, encoded >> 32, 32));
            patchgram_write_u32_le(out + 12, patchgram_arm64_mov_keep(0, encoded >> 48, 48));
            if (ton) {
                patchgram_write_u32_le(out + 16, 0xaa1f03e1U);
            } else {
                patchgram_write_u32_le(out + 16, patchgram_arm64_mov_wide(1, 0));
            }
            patchgram_write_u32_le(out + 20, 0xa8c17bfdU);
            patchgram_write_u32_le(out + 24, 0xd65f03c0U);
            for (size_t offset = 28; offset < byte_count; offset += 4) {
                patchgram_write_u32_le(out + offset, 0xd503201fU);
            }
            return true;
        }

        static bool patchgram_render_memory_patch(
            const struct PatchgramMemoryPatch *patch,
            uint8_t *out,
            size_t out_size
        ) {
            if (!patch || !out || out_size != patch->patched_size) {
                return false;
            }
            switch (patch->template_kind) {
            case PatchgramTemplateCreditsStars:
                return patchgram_render_credits_amount(g_custom_stars_value, false, out, out_size);
            case PatchgramTemplateCreditsTon:
                return patchgram_render_credits_amount(g_custom_ton_value, true, out, out_size);
            case PatchgramTemplateNone:
            default:
                memcpy(out, patch->patched, patch->patched_size);
                return true;
            }
        }

        static bool patchgram_matches_mov_wide(
            const uint8_t *bytes,
            uint32_t register_id,
            uint32_t shift,
            bool keep
        ) {
            const uint32_t instruction = (uint32_t)bytes[0]
                | ((uint32_t)bytes[1] << 8)
                | ((uint32_t)bytes[2] << 16)
                | ((uint32_t)bytes[3] << 24);
            const uint32_t base = keep ? 0xf2800000U : 0xd2800000U;
            const uint32_t expected = base | ((shift / 16U) << 21) | register_id;
            return (instruction & 0xffe0001fU) == expected;
        }

        static bool patchgram_matches_rendered_credits_amount(
            const uint8_t *bytes,
            size_t size,
            bool ton
        ) {
            const size_t byte_count = ton ? 128 : 72;
            if (!bytes || size != byte_count) {
                return false;
            }
            if (!patchgram_matches_mov_wide(bytes + 0, 0, 0, false)
                || !patchgram_matches_mov_wide(bytes + 4, 0, 16, true)
                || !patchgram_matches_mov_wide(bytes + 8, 0, 32, true)
                || !patchgram_matches_mov_wide(bytes + 12, 0, 48, true)) {
                return false;
            }
            const uint8_t ton_zero[] = { 0xe1, 0x03, 0x1f, 0xaa };
            const uint8_t stars_zero[] = { 0x01, 0x00, 0x80, 0xd2 };
            if (memcmp(bytes + 16, ton ? ton_zero : stars_zero, 4) != 0) {
                return false;
            }
            const uint8_t arm64_return[] = { 0xfd, 0x7b, 0xc1, 0xa8, 0xc0, 0x03, 0x5f, 0xd6 };
            if (memcmp(bytes + 20, arm64_return, sizeof(arm64_return)) != 0) {
                return false;
            }
            const uint8_t nop[] = { 0x1f, 0x20, 0x03, 0xd5 };
            for (size_t offset = 28; offset < byte_count; offset += 4) {
                if (memcmp(bytes + offset, nop, sizeof(nop)) != 0) {
                    return false;
                }
            }
            return true;
        }

        static bool patchgram_matches_any_rendered_template(
            const struct PatchgramMemoryPatch *patch,
            const uint8_t *bytes
        ) {
            if (!patch || !bytes) {
                return false;
            }
            switch (patch->template_kind) {
            case PatchgramTemplateCreditsStars:
                return patchgram_matches_rendered_credits_amount(bytes, patch->patched_size, false);
            case PatchgramTemplateCreditsTon:
                return patchgram_matches_rendered_credits_amount(bytes, patch->patched_size, true);
            case PatchgramTemplateNone:
            default:
                return false;
            }
        }

        static bool patchgram_patch_value_enabled(const struct PatchgramMemoryPatch *patch, uint64_t value) {
            if (!patch || patch->enabled_value_count == 0) {
                return true;
            }
            for (size_t index = 0; index < patch->enabled_value_count; index++) {
                if (patch->enabled_values[index] == value) {
                    return true;
                }
            }
            return false;
        }

        static bool patchgram_disable_monetization_group_enabled(const char *alternative_group) {
            if (!g_disable_monetization_enabled || !alternative_group) {
                return false;
            }
            if (strcmp(alternative_group, "help.getAppConfig.constructor") == 0) {
                return g_disable_monetization_app_config_enabled;
            }
            if (strcmp(alternative_group, "api.who_read_exists.chat_threshold.default_100") == 0) {
                return g_disable_monetization_read_receipts_enabled;
            }
            if (patchgram_string_contains(alternative_group, "paidReaction")
                    || patchgram_string_contains(alternative_group, "reaction_paid")
                    || patchgram_string_contains(alternative_group, "allowed_reactions.paid")
                    || patchgram_string_contains(alternative_group, "message_reactions.skip_empty")) {
                return g_disable_monetization_paid_reactions_enabled;
            }
            if (patchgram_string_contains(alternative_group, "boost")) {
                return g_disable_monetization_boosts_enabled;
            }
            if (patchgram_string_contains(alternative_group, "gift")
                    || patchgram_string_contains(alternative_group, "Gift")) {
                return g_disable_monetization_gifts_enabled;
            }
            if (patchgram_string_contains(alternative_group, "emoji_status")
                    || patchgram_string_contains(alternative_group, "EmojiStatus")
                    || patchgram_string_contains(alternative_group, "main_menu.status")
                    || patchgram_string_contains(alternative_group, "AvailableEffects")) {
                return g_disable_monetization_emoji_statuses_enabled;
            }
            if (patchgram_string_contains(alternative_group, "stars")
                    || patchgram_string_contains(alternative_group, "Stars")
                    || patchgram_string_contains(alternative_group, "ton")
                    || patchgram_string_contains(alternative_group, "nft")
                    || patchgram_string_contains(alternative_group, "collectible")) {
                return g_disable_monetization_stars_ton_collectibles_enabled;
            }
            return g_disable_monetization_premium_ui_enabled;
        }

        static bool patchgram_rule_enabled(const struct PatchgramMemoryPatch *patch) {
            if (!patch) {
                return false;
            }
            const char *rule_id = patch->rule_id;
            const char *alternative_group = patch->alternative_group;
            if (strcmp(rule_id, "binary.presence.force_offline") == 0) {
                return g_force_offline_enabled;
            }
            if (strcmp(rule_id, "binary.visual.peer_badge") == 0) {
                return g_visual_peer_badge_enabled
                    && patchgram_patch_value_enabled(patch, g_visual_peer_badge_value);
            }
            if (strcmp(rule_id, "binary.links.open_without_warning") == 0) {
                return g_open_links_without_warning_enabled;
            }
            if (strcmp(rule_id, "binary.inline.callback_hover") == 0) {
                return g_callback_hover_enabled;
            }
            if (strcmp(rule_id, "binary.display.custom_ton") == 0) {
                return g_custom_ton_enabled;
            }
            if (strcmp(rule_id, "binary.display.custom_stars") == 0) {
                return g_custom_stars_enabled;
            }
            if (strcmp(rule_id, "binary.activity.block_typing") == 0) {
                return g_block_typing_enabled;
            }
            if (strcmp(rule_id, "binary.read_receipts.block_history_read") == 0) {
                return g_block_read_messages_enabled;
            }
            if (strcmp(rule_id, "binary.messages.settings") == 0) {
                if (strcmp(alternative_group, "messages.typing.disable") == 0) {
                    return g_message_settings_enabled && g_message_typing_enabled;
                }
                if (patchgram_string_has_prefix(alternative_group, "messages.read_receipts.")) {
                    return g_message_settings_enabled && g_message_read_receipts_enabled;
                }
                if (strcmp(alternative_group, "messages.drafts.local_only") == 0) {
                    return g_message_settings_enabled && g_message_local_drafts_enabled;
                }
                if (strcmp(alternative_group, "messages.scheduled_send.local") == 0) {
                    return g_message_settings_enabled && g_scheduled_send_enabled;
                }
                if (strcmp(alternative_group, "messages.fact_check.local") == 0) {
                    return g_message_settings_enabled && g_message_fact_check_enabled;
                }
                return g_message_settings_enabled;
            }
            if (strcmp(rule_id, "binary.config.disable_monetization") == 0) {
                return patchgram_disable_monetization_group_enabled(alternative_group);
            }
            if (strcmp(rule_id, "binary.premium.local") == 0) {
                return g_local_premium_enabled;
            }
            if (strcmp(rule_id, "binary.visual.no_premium_anim") == 0) {
                return g_no_premium_anim_enabled;
            }
            if (strcmp(rule_id, "binary.visual.disable_spoilers") == 0) {
                return g_disable_spoilers_enabled;
            }
            if (strcmp(rule_id, "binary.visual.sensitive_blur") == 0) {
                return g_sensitive_blur_enabled;
            }
            if (strcmp(rule_id, "binary.stories.hide") == 0) {
                return g_hide_stories_enabled;
            }
            if (strcmp(rule_id, "binary.ads.disable_sponsored") == 0) {
                if (strcmp(alternative_group, "ads.telegram_ads.disable") == 0) {
                    return g_disable_telegram_ads_enabled;
                }
                if (patchgram_string_has_prefix(alternative_group, "ads.proxy_sponsor.")) {
                    return g_disable_proxy_sponsor_enabled;
                }
                return g_disable_ads_enabled;
            }
            if (strcmp(rule_id, "binary.privacy.no_phone_on_add") == 0) {
                return g_no_phone_on_add_enabled;
            }
            return false;
        }

        static bool patchgram_disable_monetization_group_previously_enabled(const char *alternative_group) {
            if (!g_previous_disable_monetization_enabled || !alternative_group) {
                return false;
            }
            if (strcmp(alternative_group, "help.getAppConfig.constructor") == 0) {
                return g_previous_disable_monetization_app_config_enabled;
            }
            if (strcmp(alternative_group, "api.who_read_exists.chat_threshold.default_100") == 0) {
                return g_previous_disable_monetization_read_receipts_enabled;
            }
            if (patchgram_string_contains(alternative_group, "paidReaction")
                    || patchgram_string_contains(alternative_group, "reaction_paid")
                    || patchgram_string_contains(alternative_group, "allowed_reactions.paid")
                    || patchgram_string_contains(alternative_group, "message_reactions.skip_empty")) {
                return g_previous_disable_monetization_paid_reactions_enabled;
            }
            if (patchgram_string_contains(alternative_group, "boost")) {
                return g_previous_disable_monetization_boosts_enabled;
            }
            if (patchgram_string_contains(alternative_group, "gift")
                    || patchgram_string_contains(alternative_group, "Gift")) {
                return g_previous_disable_monetization_gifts_enabled;
            }
            if (patchgram_string_contains(alternative_group, "emoji_status")
                    || patchgram_string_contains(alternative_group, "EmojiStatus")
                    || patchgram_string_contains(alternative_group, "main_menu.status")
                    || patchgram_string_contains(alternative_group, "AvailableEffects")) {
                return g_previous_disable_monetization_emoji_statuses_enabled;
            }
            if (patchgram_string_contains(alternative_group, "stars")
                    || patchgram_string_contains(alternative_group, "Stars")
                    || patchgram_string_contains(alternative_group, "ton")
                    || patchgram_string_contains(alternative_group, "nft")
                    || patchgram_string_contains(alternative_group, "collectible")) {
                return g_previous_disable_monetization_stars_ton_collectibles_enabled;
            }
            return g_previous_disable_monetization_premium_ui_enabled;
        }

        static bool patchgram_rule_previously_enabled(const char *rule_id, const char *alternative_group) {
            if (strcmp(rule_id, "binary.presence.force_offline") == 0) {
                return g_previous_force_offline_enabled;
            }
            if (strcmp(rule_id, "binary.visual.peer_badge") == 0) {
                return g_previous_visual_peer_badge_enabled;
            }
            if (strcmp(rule_id, "binary.links.open_without_warning") == 0) {
                return g_previous_open_links_without_warning_enabled;
            }
            if (strcmp(rule_id, "binary.inline.callback_hover") == 0) {
                return g_previous_callback_hover_enabled;
            }
            if (strcmp(rule_id, "binary.display.custom_ton") == 0) {
                return g_previous_custom_ton_enabled;
            }
            if (strcmp(rule_id, "binary.display.custom_stars") == 0) {
                return g_previous_custom_stars_enabled;
            }
            if (strcmp(rule_id, "binary.activity.block_typing") == 0) {
                return g_previous_block_typing_enabled;
            }
            if (strcmp(rule_id, "binary.read_receipts.block_history_read") == 0) {
                return g_previous_block_read_messages_enabled;
            }
            if (strcmp(rule_id, "binary.messages.settings") == 0) {
                if (strcmp(alternative_group, "messages.typing.disable") == 0) {
                    return g_previous_message_settings_enabled && g_previous_message_typing_enabled;
                }
                if (patchgram_string_has_prefix(alternative_group, "messages.read_receipts.")) {
                    return g_previous_message_settings_enabled && g_previous_message_read_receipts_enabled;
                }
                if (strcmp(alternative_group, "messages.drafts.local_only") == 0) {
                    return g_previous_message_settings_enabled && g_previous_message_local_drafts_enabled;
                }
                if (strcmp(alternative_group, "messages.scheduled_send.local") == 0) {
                    return g_previous_message_settings_enabled && g_previous_scheduled_send_enabled;
                }
                if (strcmp(alternative_group, "messages.fact_check.local") == 0) {
                    return g_previous_message_settings_enabled && g_previous_message_fact_check_enabled;
                }
                return g_previous_message_settings_enabled;
            }
            if (strcmp(rule_id, "binary.config.disable_monetization") == 0) {
                return patchgram_disable_monetization_group_previously_enabled(alternative_group);
            }
            if (strcmp(rule_id, "binary.premium.local") == 0) {
                return g_previous_local_premium_enabled;
            }
            if (strcmp(rule_id, "binary.visual.no_premium_anim") == 0) {
                return g_previous_no_premium_anim_enabled;
            }
            if (strcmp(rule_id, "binary.visual.disable_spoilers") == 0) {
                return g_previous_disable_spoilers_enabled;
            }
            if (strcmp(rule_id, "binary.visual.sensitive_blur") == 0) {
                return g_previous_sensitive_blur_enabled;
            }
            if (strcmp(rule_id, "binary.stories.hide") == 0) {
                return g_previous_hide_stories_enabled;
            }
            if (strcmp(rule_id, "binary.ads.disable_sponsored") == 0) {
                if (strcmp(alternative_group, "ads.telegram_ads.disable") == 0) {
                    return g_previous_disable_telegram_ads_enabled;
                }
                if (patchgram_string_has_prefix(alternative_group, "ads.proxy_sponsor.")) {
                    return g_previous_disable_proxy_sponsor_enabled;
                }
                return g_previous_disable_ads_enabled;
            }
            if (strcmp(rule_id, "binary.privacy.no_phone_on_add") == 0) {
                return g_previous_no_phone_on_add_enabled;
            }
            return false;
        }

        static void patchgram_remember_runtime_enabled_state(void) {
            g_previous_visual_peer_badge_enabled = g_visual_peer_badge_enabled;
            g_previous_force_offline_enabled = g_force_offline_enabled;
            g_previous_open_links_without_warning_enabled = g_open_links_without_warning_enabled;
            g_previous_callback_hover_enabled = g_callback_hover_enabled;
            g_previous_custom_ton_enabled = g_custom_ton_enabled;
            g_previous_custom_stars_enabled = g_custom_stars_enabled;
            g_previous_block_typing_enabled = g_block_typing_enabled;
            g_previous_block_read_messages_enabled = g_block_read_messages_enabled;
            g_previous_message_settings_enabled = g_message_settings_enabled;
            g_previous_message_typing_enabled = g_message_typing_enabled;
            g_previous_message_read_receipts_enabled = g_message_read_receipts_enabled;
            g_previous_message_local_drafts_enabled = g_message_local_drafts_enabled;
            g_previous_message_fact_check_enabled = g_message_fact_check_enabled;
            g_previous_local_premium_enabled = g_local_premium_enabled;
            g_previous_disable_monetization_enabled = g_disable_monetization_enabled;
            g_previous_disable_monetization_app_config_enabled = g_disable_monetization_app_config_enabled;
            g_previous_disable_monetization_premium_ui_enabled = g_disable_monetization_premium_ui_enabled;
            g_previous_disable_monetization_gifts_enabled = g_disable_monetization_gifts_enabled;
            g_previous_disable_monetization_paid_reactions_enabled = g_disable_monetization_paid_reactions_enabled;
            g_previous_disable_monetization_emoji_statuses_enabled = g_disable_monetization_emoji_statuses_enabled;
            g_previous_disable_monetization_stars_ton_collectibles_enabled = g_disable_monetization_stars_ton_collectibles_enabled;
            g_previous_disable_monetization_boosts_enabled = g_disable_monetization_boosts_enabled;
            g_previous_disable_monetization_read_receipts_enabled = g_disable_monetization_read_receipts_enabled;
            g_previous_no_premium_anim_enabled = g_no_premium_anim_enabled;
            g_previous_disable_spoilers_enabled = g_disable_spoilers_enabled;
            g_previous_scheduled_send_enabled = g_scheduled_send_enabled;
            g_previous_sensitive_blur_enabled = g_sensitive_blur_enabled;
            g_previous_hide_stories_enabled = g_hide_stories_enabled;
            g_previous_disable_ads_enabled = g_disable_ads_enabled;
            g_previous_disable_telegram_ads_enabled = g_disable_telegram_ads_enabled;
            g_previous_disable_proxy_sponsor_enabled = g_disable_proxy_sponsor_enabled;
            g_previous_no_phone_on_add_enabled = g_no_phone_on_add_enabled;
        }

        typedef bool (*PatchgramMemoryMatcher)(const uint8_t *);

        static size_t patchgram_find_memory_matches(
            const uint8_t *base,
            size_t size,
            size_t needle_size,
            PatchgramMemoryMatcher matcher,
            uintptr_t *matches,
            size_t max_matches
        ) {
            size_t count = 0;
            if (!base || !matcher || needle_size == 0 || size < needle_size) {
                return 0;
            }
            for (size_t offset = 0; offset <= size - needle_size; offset++) {
                if (!matcher(base + offset)) {
                    continue;
                }
                if (count < max_matches) {
                    matches[count] = (uintptr_t)(base + offset);
                }
                count++;
                if (count > PATCHGRAM_MAX_MEMORY_PATCH_OCCURRENCES) {
                    break;
                }
            }
            return count;
        }

        static const struct PatchgramMemoryPatch *g_current_memory_patch = NULL;
        static const uint8_t *g_current_desired_patch = NULL;
        static const uint8_t *g_current_rendered_patch = NULL;

        static bool patchgram_match_original_patch(const uint8_t *bytes) {
            return g_current_memory_patch
                && memcmp(bytes, g_current_memory_patch->original, g_current_memory_patch->original_size) == 0;
        }

        static bool patchgram_match_desired_patch(const uint8_t *bytes) {
            return g_current_memory_patch
                && g_current_desired_patch
                && memcmp(bytes, g_current_desired_patch, g_current_memory_patch->patched_size) == 0;
        }

        static bool patchgram_match_rendered_patch(const uint8_t *bytes) {
            return g_current_memory_patch
                && g_current_rendered_patch
                && memcmp(bytes, g_current_rendered_patch, g_current_memory_patch->patched_size) == 0;
        }

        static bool patchgram_match_any_template_patch(const uint8_t *bytes) {
            return g_current_memory_patch
                && patchgram_matches_any_rendered_template(g_current_memory_patch, bytes);
        }

        static bool patchgram_memory_patch_is_rule(
            const struct PatchgramMemoryPatch *patch,
            const char *rule_id
        ) {
            return patch && rule_id && strcmp(patch->rule_id, rule_id) == 0;
        }

        static bool patchgram_memory_patch_needs_diagnostics(const struct PatchgramMemoryPatch *patch) {
            return patchgram_memory_patch_is_rule(patch, "binary.visual.disable_spoilers")
                || patchgram_memory_patch_is_rule(patch, "binary.privacy.no_phone_on_add");
        }

        static void patchgram_log_memory_match_addresses(
            const char *stage,
            const struct PatchgramMemoryPatch *patch,
            const uintptr_t *matches,
            size_t count
        ) {
            if (!patchgram_memory_patch_needs_diagnostics(patch) || !matches || count == 0) {
                return;
            }
            const size_t limit = count < 16 ? count : 16;
            for (size_t index = 0; index < limit; index++) {
                patchgram_log(
                    "DIAG MEMORY PATCH address stage=%s rule=%s group=%s patch=%s index=%zu address=0x%llx",
                    stage ? stage : "unknown",
                    patch->rule_id,
                    patch->alternative_group,
                    patch->patch_id,
                    index,
                    (unsigned long long)matches[index]
                );
            }
            if (count > limit) {
                patchgram_log(
                    "DIAG MEMORY PATCH address stage=%s rule=%s group=%s patch=%s truncated=%zu/%zu",
                    stage ? stage : "unknown",
                    patch->rule_id,
                    patch->alternative_group,
                    patch->patch_id,
                    limit,
                    count
                );
            }
        }

        static bool patchgram_write_process_memory(uintptr_t address, const uint8_t *bytes, size_t size) {
            if (!patchgram_make_writable((void *)address, size)) {
                return false;
            }
            memcpy((void *)address, bytes, size);
            __builtin___clear_cache((char *)address, (char *)address + size);
            patchgram_restore_executable((void *)address, size);
            return true;
        }

        static void patchgram_apply_memory_patch_in_range(
            const struct PatchgramMemoryPatch *patch,
            const uint8_t *base,
            size_t size
        ) {
            if (!patch || !base || size == 0) {
                return;
            }
            uint8_t rendered[160];
            if (patch->patched_size > sizeof(rendered)
                || !patchgram_render_memory_patch(patch, rendered, patch->patched_size)) {
                patchgram_log("ERROR Memory patch render failed: %s", patch->patch_id);
                return;
            }
            const bool enabled = patchgram_rule_enabled(patch);
            const uint8_t *desired = enabled ? rendered : patch->original;
            const char *action = enabled ? "wrote" : "restored";
            const bool diagnostics = patchgram_memory_patch_needs_diagnostics(patch);
            if (diagnostics) {
                patchgram_log(
                    "DIAG MEMORY PATCH begin rule=%s group=%s patch=%s enabled=%d action=%s originalSize=%zu patchedSize=%zu expected=%zu rangeBase=%p rangeSize=%zu",
                    patch->rule_id,
                    patch->alternative_group,
                    patch->patch_id,
                    enabled ? 1 : 0,
                    action,
                    patch->original_size,
                    patch->patched_size,
                    patch->expected_occurrences,
                    base,
                    size
                );
            }

            uintptr_t matches[PATCHGRAM_MAX_MEMORY_PATCH_OCCURRENCES] = {0};
            g_current_memory_patch = patch;
            g_current_desired_patch = desired;
            g_current_rendered_patch = rendered;

            size_t count = patchgram_find_memory_matches(
                base,
                size,
                enabled ? patch->original_size : patch->patched_size,
                enabled
                    ? patchgram_match_original_patch
                    : (patch->template_kind == PatchgramTemplateNone
                        ? patchgram_match_rendered_patch
                        : patchgram_match_any_template_patch),
                matches,
                PATCHGRAM_MAX_MEMORY_PATCH_OCCURRENCES
            );
            if (diagnostics) {
                patchgram_log(
                    "DIAG MEMORY PATCH search stage=primary rule=%s group=%s patch=%s enabled=%d found=%zu expected=%zu needleSize=%zu",
                    patch->rule_id,
                    patch->alternative_group,
                    patch->patch_id,
                    enabled ? 1 : 0,
                    count,
                    patch->expected_occurrences,
                    enabled ? patch->original_size : patch->patched_size
                );
                patchgram_log_memory_match_addresses("primary", patch, matches, count);
            }
            if (count == patch->expected_occurrences) {
                size_t written = 0;
                for (size_t index = 0; index < count; index++) {
                    if (patchgram_write_process_memory(matches[index], desired, patch->patched_size)) {
                        written++;
                    }
                }
                patchgram_log("MEMORY PATCH %s %s %zu/%zu", patch->patch_id, action, written, count);
                if (diagnostics) {
                    patchgram_log(
                        "DIAG MEMORY PATCH result rule=%s group=%s patch=%s action=%s written=%zu found=%zu expected=%zu",
                        patch->rule_id,
                        patch->alternative_group,
                        patch->patch_id,
                        action,
                        written,
                        count,
                        patch->expected_occurrences
                    );
                }
                return;
            }
            if (count > 0) {
                patchgram_log(
                    "ERROR Memory patch %s occurrence mismatch while %s: found=%zu expected=%zu",
                    patch->patch_id,
                    enabled ? "enabling" : "disabling",
                    count,
                    patch->expected_occurrences
                );
                if (diagnostics) {
                    patchgram_log(
                        "DIAG MEMORY PATCH result rule=%s group=%s patch=%s status=occurrence-mismatch action=%s found=%zu expected=%zu",
                        patch->rule_id,
                        patch->alternative_group,
                        patch->patch_id,
                        action,
                        count,
                        patch->expected_occurrences
                    );
                }
                return;
            }

            count = patchgram_find_memory_matches(
                base,
                size,
                patch->patched_size,
                patchgram_match_desired_patch,
                matches,
                PATCHGRAM_MAX_MEMORY_PATCH_OCCURRENCES
            );
            if (diagnostics) {
                patchgram_log(
                    "DIAG MEMORY PATCH search stage=desired rule=%s group=%s patch=%s found=%zu expected=%zu needleSize=%zu",
                    patch->rule_id,
                    patch->alternative_group,
                    patch->patch_id,
                    count,
                    patch->expected_occurrences,
                    patch->patched_size
                );
                patchgram_log_memory_match_addresses("desired", patch, matches, count);
            }
            if (count == patch->expected_occurrences) {
                patchgram_log("MEMORY PATCH %s already %s", patch->patch_id, enabled ? "applied" : "restored");
                if (diagnostics) {
                    patchgram_log(
                        "DIAG MEMORY PATCH result rule=%s group=%s patch=%s status=already-%s found=%zu expected=%zu",
                        patch->rule_id,
                        patch->alternative_group,
                        patch->patch_id,
                        enabled ? "applied" : "restored",
                        count,
                        patch->expected_occurrences
                    );
                }
                return;
            }

            if (enabled && patch->template_kind != PatchgramTemplateNone) {
                count = patchgram_find_memory_matches(
                    base,
                    size,
                    patch->patched_size,
                    patchgram_match_any_template_patch,
                    matches,
                    PATCHGRAM_MAX_MEMORY_PATCH_OCCURRENCES
                );
                if (diagnostics) {
                    patchgram_log(
                        "DIAG MEMORY PATCH search stage=template rule=%s group=%s patch=%s found=%zu expected=%zu needleSize=%zu",
                        patch->rule_id,
                        patch->alternative_group,
                        patch->patch_id,
                        count,
                        patch->expected_occurrences,
                        patch->patched_size
                    );
                    patchgram_log_memory_match_addresses("template", patch, matches, count);
                }
                if (count == patch->expected_occurrences) {
                    size_t written = 0;
                    for (size_t index = 0; index < count; index++) {
                        if (patchgram_write_process_memory(matches[index], desired, patch->patched_size)) {
                            written++;
                        }
                    }
                    patchgram_log("MEMORY PATCH %s updated rendered value %zu/%zu", patch->patch_id, written, count);
                    if (diagnostics) {
                        patchgram_log(
                            "DIAG MEMORY PATCH result rule=%s group=%s patch=%s status=updated-rendered written=%zu found=%zu expected=%zu",
                            patch->rule_id,
                            patch->alternative_group,
                            patch->patch_id,
                            written,
                            count,
                            patch->expected_occurrences
                        );
                    }
                    return;
                }
            }

            patchgram_log("ERROR Memory patch %s not found while %s", patch->patch_id, enabled ? "enabling" : "disabling");
            if (diagnostics) {
                patchgram_log(
                    "DIAG MEMORY PATCH result rule=%s group=%s patch=%s status=not-found action=%s expected=%zu",
                    patch->rule_id,
                    patch->alternative_group,
                    patch->patch_id,
                    action,
                    patch->expected_occurrences
                );
            }
        }

        static void patchgram_apply_memory_patches(const char *reason) {
            const struct mach_header_64 *header = NULL;
            intptr_t slide = 0;
            uint32_t count = _dyld_image_count();
            for (uint32_t image_index = 0; image_index < count; image_index++) {
                const char *name = _dyld_get_image_name(image_index);
                if (!patchgram_is_telegram_executable_image(name)) {
                    continue;
                }
                header = (const struct mach_header_64 *)_dyld_get_image_header(image_index);
                slide = _dyld_get_image_vmaddr_slide(image_index);
                break;
            }
            if (!header) {
                patchgram_log("ERROR Main executable image not found for memory patches");
                return;
            }
            size_t skipped_disabled = 0;
            const uint8_t *command = (const uint8_t *)header + sizeof(struct mach_header_64);
            for (uint32_t command_index = 0; command_index < header->ncmds; command_index++) {
                const struct load_command *load_command = (const struct load_command *)command;
                if (load_command->cmd == LC_SEGMENT_64) {
                    const struct segment_command_64 *segment = (const struct segment_command_64 *)command;
                    if (strncmp(segment->segname, "__TEXT", sizeof(segment->segname)) == 0) {
                        const uint8_t *base = (const uint8_t *)(uintptr_t)(segment->vmaddr + slide);
                        patchgram_log(
                            "BEGIN Memory patches reason=%s segment=%s size=%llu patchCount=%zu noPhoneOnAdd=%d noPremiumAnim=%d disableSpoilers=%d scheduledSend=%d",
                            reason ? reason : "load",
                            segment->segname,
                            segment->vmsize,
                            g_memory_patch_count,
                            g_no_phone_on_add_enabled ? 1 : 0,
                            g_no_premium_anim_enabled ? 1 : 0,
                            g_disable_spoilers_enabled ? 1 : 0,
                            g_scheduled_send_enabled ? 1 : 0
                        );
                        for (size_t patch_index = 0; patch_index < g_memory_patch_count; patch_index++) {
                            const struct PatchgramMemoryPatch *patch = &g_memory_patches[patch_index];
                            const bool enabled = patchgram_rule_enabled(patch);
                            const bool previously_enabled = patchgram_rule_previously_enabled(
                                patch->rule_id,
                                patch->alternative_group
                            );
                            if (patchgram_memory_patch_needs_diagnostics(patch)) {
                                patchgram_log(
                                    "DIAG MEMORY PATCH decision phase=restore rule=%s group=%s patch=%s enabled=%d previouslyEnabled=%d willApply=%d",
                                    patch->rule_id,
                                    patch->alternative_group,
                                    patch->patch_id,
                                    enabled ? 1 : 0,
                                    previously_enabled ? 1 : 0,
                                    (!enabled && previously_enabled) ? 1 : 0
                                );
                            }
                            if (enabled || !previously_enabled) {
                                skipped_disabled++;
                                continue;
                            }
                            patchgram_apply_memory_patch_in_range(patch, base, (size_t)segment->vmsize);
                        }
                        for (size_t patch_index = 0; patch_index < g_memory_patch_count; patch_index++) {
                            const struct PatchgramMemoryPatch *patch = &g_memory_patches[patch_index];
                            const bool enabled = patchgram_rule_enabled(patch);
                            if (patchgram_memory_patch_needs_diagnostics(patch)) {
                                patchgram_log(
                                    "DIAG MEMORY PATCH decision phase=apply rule=%s group=%s patch=%s enabled=%d willApply=%d",
                                    patch->rule_id,
                                    patch->alternative_group,
                                    patch->patch_id,
                                    enabled ? 1 : 0,
                                    enabled ? 1 : 0
                                );
                            }
                            if (!enabled) {
                                continue;
                            }
                            patchgram_apply_memory_patch_in_range(patch, base, (size_t)segment->vmsize);
                        }
                    }
                }
                command += load_command->cmdsize;
            }
            g_current_memory_patch = NULL;
            g_current_desired_patch = NULL;
            g_current_rendered_patch = NULL;
            patchgram_log("END Memory patches skipped_disabled=%zu", skipped_disabled);
            patchgram_remember_runtime_enabled_state();
        }

        static bool patchgram_refresh_config_mtime(const char *path, bool *changed) {
            if (changed) {
                *changed = false;
            }
            if (!path || !path[0]) {
                return false;
            }
            struct stat attributes;
            if (stat(path, &attributes) != 0) {
                return false;
            }
        #if defined(__APPLE__)
            const time_t sec = attributes.st_mtimespec.tv_sec;
            const long nsec = attributes.st_mtimespec.tv_nsec;
        #else
            const time_t sec = attributes.st_mtim.tv_sec;
            const long nsec = attributes.st_mtim.tv_nsec;
        #endif
            const bool did_change = (sec != g_config_mtime_sec) || (nsec != g_config_mtime_nsec);
            g_config_mtime_sec = sec;
            g_config_mtime_nsec = nsec;
            if (changed) {
                *changed = did_change;
            }
            return true;
        }

        static void patchgram_apply_tracked_user_runtime_values(const char *source);
        static const char *patchgram_target_mode_value_name(enum PatchgramTargetMode target_mode);

        static bool patchgram_load_runtime_config(const char *config_path, bool apply_memory_patches, const char *reason) {
            if (!config_path || !config_path[0]) {
                patchgram_log("ERROR Missing runtime config path");
                return false;
            }
            char *json = patchgram_read_file(config_path);
            if (!json) {
                patchgram_log("ERROR Could not read config: %s", config_path);
                return false;
            }

            char target_mode[64];
            char rating_target_mode[64];
            char description[PATCHGRAM_MAX_DESCRIPTION_UTF8];
            char self_phone[PATCHGRAM_MAX_PHONE_UTF8];
            char self_user_id[64];
            char personal_channel_reference[256];
            char self_phone_target_mode[64];
            char self_user_id_target_mode[64];
            char personal_channel_target_mode[64];
            char fragment_phone_target_mode[64];
            char fragment_phone_currency[PATCHGRAM_MAX_FRAGMENT_TEXT_UTF8];
            char fragment_phone_crypto_currency[PATCHGRAM_MAX_FRAGMENT_TEXT_UTF8];
            char fragment_phone_url[PATCHGRAM_MAX_FRAGMENT_TEXT_UTF8];
            char custom_list_usernames_payload[PATCHGRAM_MAX_CUSTOM_USERNAMES * 8192];
            char message_fact_check_text[PATCHGRAM_MAX_FACT_CHECK_TEXT_UTF8];
            char message_fact_check_country[PATCHGRAM_MAX_FRAGMENT_TEXT_UTF8];
            patchgram_json_string(json, "botVerificationTargetMode", target_mode, sizeof(target_mode));
            patchgram_json_string(json, "customLevelRatingTargetMode", rating_target_mode, sizeof(rating_target_mode));
            patchgram_json_string(json, "botVerificationDescription", description, sizeof(description));
            patchgram_json_string(json, "selfIdentityOverridePhone", self_phone, sizeof(self_phone));
            patchgram_json_string(json, "selfIdentityOverrideUserId", self_user_id, sizeof(self_user_id));
            patchgram_json_string(json, "localPersonalChannelReference", personal_channel_reference, sizeof(personal_channel_reference));
            patchgram_json_string(json, "customPhoneNumberTargetMode", self_phone_target_mode, sizeof(self_phone_target_mode));
            patchgram_json_string(json, "customUserIdTargetMode", self_user_id_target_mode, sizeof(self_user_id_target_mode));
            patchgram_json_string(json, "localPersonalChannelTargetMode", personal_channel_target_mode, sizeof(personal_channel_target_mode));
            patchgram_json_string(json, "fragmentPhoneTargetMode", fragment_phone_target_mode, sizeof(fragment_phone_target_mode));
            patchgram_json_string(json, "fragmentPhoneCurrency", fragment_phone_currency, sizeof(fragment_phone_currency));
            patchgram_json_string(json, "fragmentPhoneCryptoCurrency", fragment_phone_crypto_currency, sizeof(fragment_phone_crypto_currency));
            patchgram_json_string(json, "fragmentPhoneUrl", fragment_phone_url, sizeof(fragment_phone_url));
            patchgram_json_string(json, "customListUsernamesPayload", custom_list_usernames_payload, sizeof(custom_list_usernames_payload));
            patchgram_json_string(json, "messageFactCheckText", message_fact_check_text, sizeof(message_fact_check_text));
            patchgram_json_string(json, "messageFactCheckCountry", message_fact_check_country, sizeof(message_fact_check_country));
            if (!self_phone_target_mode[0]) {
                snprintf(self_phone_target_mode, sizeof(self_phone_target_mode), "%s", "onlySelf");
            }
            if (!self_user_id_target_mode[0]) {
                snprintf(self_user_id_target_mode, sizeof(self_user_id_target_mode), "%s", "onlySelf");
            }
            if (!personal_channel_target_mode[0]) {
                snprintf(personal_channel_target_mode, sizeof(personal_channel_target_mode), "%s", "onlySelf");
            }
            if (!fragment_phone_target_mode[0]) {
                snprintf(fragment_phone_target_mode, sizeof(fragment_phone_target_mode), "%s", "onlySelf");
            }
            g_bot_verification_enabled = patchgram_json_bool(json, "botVerificationEnabled", false);
            g_custom_level_rating_enabled = patchgram_json_bool(json, "customLevelRatingEnabled", false);
            g_hide_self_phone_enabled = patchgram_json_bool(json, "hideSelfPhoneEnabled", false);
            g_self_identity_override_enabled = patchgram_json_bool(json, "selfIdentityOverrideEnabled", false);
            g_custom_phone_number_enabled = patchgram_json_bool(json, "customPhoneNumberEnabled", g_self_identity_override_enabled);
            g_custom_user_id_enabled = patchgram_json_bool(json, "customUserIdEnabled", g_self_identity_override_enabled);
            g_local_personal_channel_enabled = patchgram_json_bool(json, "localPersonalChannelEnabled", false);
            g_fragment_phone_enabled = patchgram_json_bool(json, "fragmentPhoneEnabled", false);
            g_custom_list_usernames_enabled = patchgram_json_bool(json, "customListUsernamesEnabled", false);
            g_visual_peer_badge_enabled = patchgram_json_bool(json, "visualPeerBadgeEnabled", false);
            g_force_offline_enabled = patchgram_json_bool(json, "forceOfflineEnabled", false);
            g_open_links_without_warning_enabled = patchgram_json_bool(json, "openLinksWithoutWarningEnabled", false);
            g_callback_hover_enabled = patchgram_json_bool(json, "callbackHoverEnabled", false);
            g_custom_ton_enabled = patchgram_json_bool(json, "customTonEnabled", false);
            g_custom_stars_enabled = patchgram_json_bool(json, "customStarsEnabled", false);
            g_block_typing_enabled = patchgram_json_bool(json, "blockTypingEnabled", false);
            g_block_read_messages_enabled = patchgram_json_bool(json, "blockReadMessagesEnabled", false);
            g_message_settings_enabled = patchgram_json_bool(json, "messageSettingsEnabled", false);
            g_message_typing_enabled = patchgram_json_bool(json, "messageTypingEnabled", false);
            g_message_read_receipts_enabled = patchgram_json_bool(json, "messageReadReceiptsEnabled", false);
            g_message_local_drafts_enabled = patchgram_json_bool(json, "messageLocalDraftsEnabled", false);
            g_message_fact_check_enabled = patchgram_json_bool(json, "messageFactCheckEnabled", false);
            g_local_premium_enabled = patchgram_json_bool(json, "localPremiumEnabled", false);
            g_disable_monetization_enabled = patchgram_json_bool(json, "disableMonetizationEnabled", false);
            g_disable_monetization_app_config_enabled = patchgram_json_bool(json, "disableMonetizationAppConfigEnabled", g_disable_monetization_enabled);
            g_disable_monetization_premium_ui_enabled = patchgram_json_bool(json, "disableMonetizationPremiumUIEnabled", g_disable_monetization_enabled);
            g_disable_monetization_gifts_enabled = patchgram_json_bool(json, "disableMonetizationGiftsEnabled", g_disable_monetization_enabled);
            g_disable_monetization_paid_reactions_enabled = patchgram_json_bool(json, "disableMonetizationPaidReactionsEnabled", g_disable_monetization_enabled);
            g_disable_monetization_emoji_statuses_enabled = patchgram_json_bool(json, "disableMonetizationEmojiStatusesEnabled", g_disable_monetization_enabled);
            g_disable_monetization_stars_ton_collectibles_enabled = patchgram_json_bool(json, "disableMonetizationStarsTonCollectiblesEnabled", g_disable_monetization_enabled);
            g_disable_monetization_boosts_enabled = patchgram_json_bool(json, "disableMonetizationBoostsEnabled", g_disable_monetization_enabled);
            g_disable_monetization_read_receipts_enabled = patchgram_json_bool(json, "disableMonetizationReadReceiptsEnabled", g_disable_monetization_enabled);
            g_no_premium_anim_enabled = patchgram_json_bool(json, "noPremiumAnimEnabled", false);
            g_disable_spoilers_enabled = patchgram_json_bool(json, "disableSpoilersEnabled", false);
            g_scheduled_send_enabled = patchgram_json_bool(json, "scheduledSendEnabled", false);
            g_sensitive_blur_enabled = patchgram_json_bool(json, "sensitiveBlurEnabled", false);
            g_hide_stories_enabled = patchgram_json_bool(json, "hideStoriesEnabled", false);
            g_disable_ads_enabled = patchgram_json_bool(json, "disableAdsEnabled", false);
            g_disable_telegram_ads_enabled = patchgram_json_bool(json, "disableTelegramAdsEnabled", g_disable_ads_enabled);
            g_disable_proxy_sponsor_enabled = patchgram_json_bool(json, "disableProxySponsorEnabled", g_disable_ads_enabled);
            g_no_phone_on_add_enabled = patchgram_json_bool(json, "noPhoneOnAddEnabled", false);
            g_visual_peer_badge_value = patchgram_json_u64(json, "visualPeerBadgeValue", 1);
            g_local_personal_channel_id = patchgram_json_u64(json, "localPersonalChannelId", 0);
            g_local_personal_channel_message_id = (int32_t)patchgram_json_i64(json, "localPersonalChannelMessageId", 0);
            g_fragment_phone_purchase_date = (int32_t)patchgram_json_i64(json, "fragmentPhonePurchaseDate", 0);
            g_fragment_phone_amount = patchgram_json_i64(json, "fragmentPhoneAmount", 0);
            g_fragment_phone_crypto_amount = patchgram_json_i64(json, "fragmentPhoneCryptoAmount", 0);
            snprintf(g_fragment_phone_currency, sizeof(g_fragment_phone_currency), "%s", fragment_phone_currency);
            snprintf(g_fragment_phone_crypto_currency, sizeof(g_fragment_phone_crypto_currency), "%s", fragment_phone_crypto_currency);
            snprintf(g_fragment_phone_url, sizeof(g_fragment_phone_url), "%s", fragment_phone_url);
            snprintf(g_message_fact_check_text, sizeof(g_message_fact_check_text), "%s", message_fact_check_text);
            snprintf(g_message_fact_check_country, sizeof(g_message_fact_check_country), "%s", message_fact_check_country);
            g_message_fact_check_hash = patchgram_json_i64(json, "messageFactCheckHash", 0);
            g_message_fact_check_need_check = patchgram_json_bool(json, "messageFactCheckNeedCheck", false);
            g_custom_ton_value = patchgram_json_u64(json, "customTonValue", 999);
            g_custom_stars_value = patchgram_json_u64(json, "customStarsValue", 999);
            g_custom_level_rating_level = (int32_t)patchgram_json_i64(json, "customLevelRatingLevel", 1);
            g_custom_level_rating_rating = (int32_t)patchgram_json_i64(json, "customLevelRatingRating", 1000);
            g_custom_level_rating_current_level_rating = (int32_t)patchgram_json_i64(json, "customLevelRatingCurrentLevelRating", 0);
            g_custom_level_rating_next_level_rating = (int32_t)patchgram_json_i64(json, "customLevelRatingNextLevelRating", 2000);
            g_configured_icon_id = patchgram_json_u64(json, "botVerificationCustomEmojiId", 0);
            g_configured_self_display_user_id = g_custom_user_id_enabled && self_user_id[0]
                ? strtoull(self_user_id, NULL, 10)
                : 0;
            patchgram_set_target_mode(target_mode);
            g_level_rating_target_mode = patchgram_parse_target_mode(rating_target_mode);
            g_self_phone_target_mode = patchgram_parse_target_mode(self_phone_target_mode);
            g_self_user_id_target_mode = (uint64_t)patchgram_parse_target_mode(self_user_id_target_mode);
            g_local_personal_channel_target_mode = patchgram_parse_target_mode(personal_channel_target_mode);
            g_fragment_phone_target_mode = (uint64_t)patchgram_parse_target_mode(fragment_phone_target_mode);
            patchgram_configure_description(description);
            patchgram_configure_self_phone(self_phone);
            patchgram_configure_fact_check_text(g_message_fact_check_text, g_message_fact_check_country);
            patchgram_configure_custom_usernames_payload(custom_list_usernames_payload);
            patchgram_refresh_config_mtime(config_path, NULL);
            patchgram_log(
                "CONFIG %s botVerification=%d targetMode=%s customEmojiId=%llu description=%s descriptionUtf16Length=%lld customLevelRating=%d:%s level=%d rating=%d current=%d next=%d hideSelfPhone=%d selfIdentity=%d customPhone=%d:%s phoneUtf16Length=%lld customUserId=%d:%s displayUserId=%llu personalChannel=%d:%s:%llu:%d reference=%s fragmentPhone=%d:%s date=%d amount=%lld currency=%s cryptoAmount=%lld cryptoCurrency=%s url=%s customUsernames=%d count=%zu visualPeerBadge=%d:%llu forceOffline=%d openLinks=%d noPhoneOnAdd=%d callbackHover=%d customTon=%d:%llu customStars=%d:%llu blockTyping=%d blockRead=%d messageSettings=%d typing=%d readReceipts=%d localDrafts=%d factCheck=%d factCheckText=%s factCheckCountry=%s factCheckHash=%lld factCheckNeedCheck=%d localPremium=%d disableMonetization=%d appConfig=%d premiumUI=%d gifts=%d paidReactions=%d emojiStatuses=%d starsTonCollectibles=%d boosts=%d monetizationReadReceipts=%d noPremiumAnim=%d disableSpoilers=%d scheduledSend=%d sensitiveBlur=%d hideStories=%d disableAds=%d telegramAds=%d proxySponsor=%d image=%s",
                reason ? reason : "load",
                g_bot_verification_enabled ? 1 : 0,
                target_mode,
                (unsigned long long)g_configured_icon_id,
                description,
                (long long)g_configured_description_utf16_size,
                g_custom_level_rating_enabled ? 1 : 0,
                rating_target_mode,
                (int)g_custom_level_rating_level,
                (int)g_custom_level_rating_rating,
                (int)g_custom_level_rating_current_level_rating,
                (int)g_custom_level_rating_next_level_rating,
                g_hide_self_phone_enabled ? 1 : 0,
                g_self_identity_override_enabled ? 1 : 0,
                g_custom_phone_number_enabled ? 1 : 0,
                patchgram_target_mode_value_name(g_self_phone_target_mode),
                (long long)g_configured_self_phone_utf16_size,
                g_custom_user_id_enabled ? 1 : 0,
                patchgram_target_mode_value_name((enum PatchgramTargetMode)g_self_user_id_target_mode),
                (unsigned long long)g_configured_self_display_user_id,
                g_local_personal_channel_enabled ? 1 : 0,
                patchgram_target_mode_value_name(g_local_personal_channel_target_mode),
                (unsigned long long)g_local_personal_channel_id,
                (int)g_local_personal_channel_message_id,
                personal_channel_reference,
                g_fragment_phone_enabled ? 1 : 0,
                patchgram_target_mode_value_name((enum PatchgramTargetMode)g_fragment_phone_target_mode),
                (int)g_fragment_phone_purchase_date,
                (long long)g_fragment_phone_amount,
                g_fragment_phone_currency,
                (long long)g_fragment_phone_crypto_amount,
                g_fragment_phone_crypto_currency,
                g_fragment_phone_url,
                g_custom_list_usernames_enabled ? 1 : 0,
                g_custom_username_entry_count,
                g_visual_peer_badge_enabled ? 1 : 0,
                (unsigned long long)g_visual_peer_badge_value,
                g_force_offline_enabled ? 1 : 0,
                g_open_links_without_warning_enabled ? 1 : 0,
                g_no_phone_on_add_enabled ? 1 : 0,
                g_callback_hover_enabled ? 1 : 0,
                g_custom_ton_enabled ? 1 : 0,
                (unsigned long long)g_custom_ton_value,
                g_custom_stars_enabled ? 1 : 0,
                (unsigned long long)g_custom_stars_value,
                g_block_typing_enabled ? 1 : 0,
                g_block_read_messages_enabled ? 1 : 0,
                g_message_settings_enabled ? 1 : 0,
                g_message_typing_enabled ? 1 : 0,
                g_message_read_receipts_enabled ? 1 : 0,
                g_message_local_drafts_enabled ? 1 : 0,
                g_message_fact_check_enabled ? 1 : 0,
                g_message_fact_check_text,
                g_message_fact_check_country,
                (long long)g_message_fact_check_hash,
                g_message_fact_check_need_check ? 1 : 0,
                g_local_premium_enabled ? 1 : 0,
                g_disable_monetization_enabled ? 1 : 0,
                g_disable_monetization_app_config_enabled ? 1 : 0,
                g_disable_monetization_premium_ui_enabled ? 1 : 0,
                g_disable_monetization_gifts_enabled ? 1 : 0,
                g_disable_monetization_paid_reactions_enabled ? 1 : 0,
                g_disable_monetization_emoji_statuses_enabled ? 1 : 0,
                g_disable_monetization_stars_ton_collectibles_enabled ? 1 : 0,
                g_disable_monetization_boosts_enabled ? 1 : 0,
                g_disable_monetization_read_receipts_enabled ? 1 : 0,
                g_no_premium_anim_enabled ? 1 : 0,
                g_disable_spoilers_enabled ? 1 : 0,
                g_scheduled_send_enabled ? 1 : 0,
                g_sensitive_blur_enabled ? 1 : 0,
                g_hide_stories_enabled ? 1 : 0,
                g_disable_ads_enabled ? 1 : 0,
                g_disable_telegram_ads_enabled ? 1 : 0,
                g_disable_proxy_sponsor_enabled ? 1 : 0,
                patchgram_main_image_name()
            );
            patchgram_log(
                "SCHEDULED SEND config reason=%s enabled=%d messageSettings=%d typing=%d readReceipts=%d localDrafts=%d factCheck=%d delaySeconds=%d sendMessageHook=%d sendMediaHook=%d status=%s",
                reason ? reason : "load",
                g_scheduled_send_enabled ? 1 : 0,
                g_message_settings_enabled ? 1 : 0,
                g_message_typing_enabled ? 1 : 0,
                g_message_read_receipts_enabled ? 1 : 0,
                g_message_local_drafts_enabled ? 1 : 0,
                g_message_fact_check_enabled ? 1 : 0,
                PATCHGRAM_SCHEDULED_SEND_DELAY_SECONDS,
                g_scheduled_send_message_hook_installed ? 1 : 0,
                g_scheduled_send_media_hook_installed ? 1 : 0,
                (g_scheduled_send_message_hook_installed && g_scheduled_send_media_hook_installed) ? "hooked" : "pending-hook-install"
            );
            free(json);

            if (apply_memory_patches) {
                patchgram_apply_memory_patches(reason);
            }
            patchgram_apply_tracked_user_runtime_values(reason ? reason : "config");
            return true;
        }

        static void *patchgram_runtime_reload_thread(void *context) {
            (void)context;
            for (;;) {
                sleep(1);
                bool changed = false;
                if (patchgram_refresh_config_mtime(g_config_path, &changed) && changed) {
                    patchgram_log("CONFIG changed, live reload");
                    patchgram_load_runtime_config(g_config_path, true, "reload");
                }
                patchgram_apply_tracked_user_runtime_values("periodic");
            }
            return NULL;
        }

        static void patchgram_start_runtime_reload_thread(void) {
            pthread_t thread;
            const int result = pthread_create(&thread, NULL, patchgram_runtime_reload_thread, NULL);
            if (result == 0) {
                pthread_detach(thread);
                patchgram_log("READY runtime config live reload thread");
            } else {
                patchgram_log("ERROR Could not start runtime reload thread: %d", result);
            }
        }

        static uint64_t patchgram_raw_peer_id_from_peer(void *peer);
        static uint64_t patchgram_user_id_from_peer(void *peer);
        static uint8_t patchgram_peer_type_from_peer(void *peer);
        static bool patchgram_peer_is_user_peer(void *peer);
        static const char *patchgram_target_mode_name(void);
        static const char *patchgram_target_mode_value_name(enum PatchgramTargetMode target_mode);
        static bool patchgram_peer_is_self_user(void *peer);
        static uint64_t patchgram_display_user_id_for_peer(void *peer);
        static bool patchgram_should_patch_peer_for_mode(
            void *peer,
            bool hook_is_user,
            enum PatchgramTargetMode target_mode,
            const char *log_prefix
        );
        static void patchgram_track_user_data_peer(void *peer, const char *source);
        static void patchgram_clear_self_phone_field(void *peer, const char *source);
        static void patchgram_write_self_phone_field(void *peer, const char *source);
        static void patchgram_write_custom_level_rating(void *peer, const char *source);
        static void patchgram_write_local_personal_channel(void *peer, const char *source);
        static void patchgram_apply_custom_usernames(void *peer, const char *source);
        static void patchgram_apply_raw_qstring(uint8_t *destination, const uint16_t *text, int64_t size);
        static void patchgram_configure_fact_check_text(const char *text, const char *country);

        static uint64_t patchgram_details_u64(void *details, size_t offset) {
            if (!details) {
                return 0;
            }
            uint64_t value = 0;
            memcpy(&value, (const uint8_t *)details + offset, sizeof(value));
            return value;
        }

        static int64_t patchgram_details_description_utf16_size(void *details) {
            if (!details) {
                return 0;
            }
            int64_t size = 0;
            memcpy(
                &size,
                (const uint8_t *)details
                    + PATCHGRAM_DETAILS_DESCRIPTION_OFFSET
                    + PATCHGRAM_QSTRING_SIZE_OFFSET,
                sizeof(size)
            );
            return size;
        }

        static bool patchgram_details_has_value(void *details) {
            return patchgram_details_u64(details, PATCHGRAM_DETAILS_BOT_ID_OFFSET) != 0
                || patchgram_details_u64(details, PATCHGRAM_DETAILS_ICON_ID_OFFSET) != 0
                || patchgram_details_description_utf16_size(details) > 0;
        }

        static void patchgram_log_bot_verify_details(
            const char *stage,
            void *peer,
            void *details,
            bool is_user,
            bool is_self,
            bool should_patch
        ) {
            if (g_bot_verify_setter_logs >= 96) {
                return;
            }
            g_bot_verify_setter_logs++;
            const uint8_t raw_type = patchgram_peer_type_from_peer(peer);
            const bool raw_is_user = patchgram_peer_is_user_peer(peer);
            patchgram_log(
                "BOT VERIFY %s peer=%p raw_peer=0x%llx peer_id=%llu hook_is_user=%d raw_type=%u raw_is_user=%d is_self=%d should_patch=%d targetMode=%s known_self=%llu details=%p hasValue=%d bot_id=%llu icon_id=%llu descriptionUtf16Length=%lld configuredIcon=%llu configuredDescriptionUtf16Length=%lld enabled=%d",
                stage ? stage : "details",
                peer,
                (unsigned long long)patchgram_raw_peer_id_from_peer(peer),
                (unsigned long long)patchgram_user_id_from_peer(peer),
                is_user ? 1 : 0,
                (unsigned)raw_type,
                raw_is_user ? 1 : 0,
                is_self ? 1 : 0,
                should_patch ? 1 : 0,
                patchgram_target_mode_name(),
                (unsigned long long)g_self_user_id,
                details,
                patchgram_details_has_value(details) ? 1 : 0,
                (unsigned long long)patchgram_details_u64(details, PATCHGRAM_DETAILS_BOT_ID_OFFSET),
                (unsigned long long)patchgram_details_u64(details, PATCHGRAM_DETAILS_ICON_ID_OFFSET),
                (long long)patchgram_details_description_utf16_size(details),
                (unsigned long long)g_configured_icon_id,
                (long long)g_configured_description_utf16_size,
                g_bot_verification_enabled ? 1 : 0
            );
        }

        static void patchgram_record_self_user_id(void *peer, uint32_t flags, const char *source) {
            if (!peer || (flags & PATCHGRAM_USER_SELF_FLAG) == 0) {
                return;
            }
            const uint64_t user_id = patchgram_user_id_from_peer(peer);
            if (g_bot_verify_self_candidate_logs < 24) {
                g_bot_verify_self_candidate_logs++;
                patchgram_log(
                    "SELF candidate raw_peer=0x%llx peer_id=%llu known_self=%llu source=%s flags=0x%x",
                    (unsigned long long)patchgram_raw_peer_id_from_peer(peer),
                    (unsigned long long)user_id,
                    (unsigned long long)g_self_user_id,
                    source,
                    flags
                );
            }
            if (!user_id) {
                if (!g_warned_unknown_self_user_id) {
                    g_warned_unknown_self_user_id = true;
                    patchgram_log(
                        "SELF user id missing raw_peer=0x%llx source=%s flags=0x%x",
                        (unsigned long long)patchgram_raw_peer_id_from_peer(peer),
                        source,
                        flags
                    );
                }
                return;
            }
            if (!g_self_user_id) {
                g_self_user_id = user_id;
                patchgram_log("SELF user id=%llu source=%s flags=0x%x", (unsigned long long)user_id, source, flags);
            } else if (g_self_user_id != user_id && g_bot_verify_self_ignored_logs < 24) {
                g_bot_verify_self_ignored_logs++;
                patchgram_log(
                    "SELF candidate ignored raw_peer=0x%llx peer_id=%llu known_self=%llu source=%s flags=0x%x",
                    (unsigned long long)patchgram_raw_peer_id_from_peer(peer),
                    (unsigned long long)user_id,
                    (unsigned long long)g_self_user_id,
                    source,
                    flags
                );
            }
        }

        static void patchgram_user_set_flags(void *peer, uint32_t flags) {
            patchgram_record_self_user_id(peer, flags, "UserData::setFlags.before");
            if (g_original_user_set_flags) {
                g_original_user_set_flags(peer, flags);
            }
            patchgram_record_self_user_id(peer, flags, "UserData::setFlags.after");
            patchgram_track_user_data_peer(peer, "UserData::setFlags.after");
            patchgram_write_self_phone_field(peer, "UserData::setFlags.after");
            patchgram_clear_self_phone_field(peer, "UserData::setFlags.after");
            patchgram_write_custom_level_rating(peer, "UserData::setFlags.after");
            patchgram_write_local_personal_channel(peer, "UserData::setFlags.after");
            patchgram_apply_custom_usernames(peer, "UserData::setFlags.after");
        }

        static bool patchgram_user_is_self(void *peer) {
            if (!peer) {
                return false;
            }
            const uint64_t user_id = patchgram_user_id_from_peer(peer);
            if (user_id != 0 && g_self_user_id != 0 && user_id == g_self_user_id) {
                return true;
            }
            const uint32_t flags = *(const uint32_t *)((const uint8_t *)peer + PATCHGRAM_USER_FLAGS_OFFSET);
            if ((flags & PATCHGRAM_USER_SELF_FLAG) != 0 && !g_self_user_id) {
                if (user_id) {
                    g_self_user_id = user_id;
                }
                return true;
            }
            if ((flags & PATCHGRAM_USER_SELF_FLAG) != 0 && user_id != g_self_user_id && g_bot_verify_self_ignored_logs < 24) {
                g_bot_verify_self_ignored_logs++;
                patchgram_log(
                    "SELF flag ignored raw_peer=0x%llx peer_id=%llu known_self=%llu flags=0x%x",
                    (unsigned long long)patchgram_raw_peer_id_from_peer(peer),
                    (unsigned long long)user_id,
                    (unsigned long long)g_self_user_id,
                    flags
                );
            }
            return false;
        }

        static void *patchgram_phone_or_hidden_value_user(void *value) {
            if (!value) {
                return NULL;
            }
            void *peer = NULL;
            memcpy(&peer, (const uint8_t *)value + PATCHGRAM_PHONE_OR_HIDDEN_VALUE_USER_OFFSET, sizeof(peer));
            return peer;
        }

        static void patchgram_clear_text_with_entities(void *value) {
            if (!value) {
                return;
            }
            memset(value, 0, PATCHGRAM_TEXT_WITH_ENTITIES_SIZE);
        }

        static int64_t patchgram_qstring_size_at(void *value) {
            if (!value) {
                return 0;
            }
            int64_t size = 0;
            memcpy(&size, (const uint8_t *)value + PATCHGRAM_QSTRING_SIZE_OFFSET, sizeof(size));
            return size;
        }

        static void patchgram_clear_qstring(void *value) {
            if (!value) {
                return;
            }
            memset(value, 0, PATCHGRAM_QT_ARRAY_DATA_POINTER_SIZE);
        }

        static void patchgram_copy_qstring_ascii(void *value, char *destination, size_t capacity) {
            if (!destination || capacity == 0) {
                return;
            }
            destination[0] = '\0';
            if (!value) {
                return;
            }
            uint16_t *utf16 = NULL;
            int64_t size = 0;
            memcpy(&utf16, (const uint8_t *)value + PATCHGRAM_QSTRING_PTR_OFFSET, sizeof(utf16));
            memcpy(&size, (const uint8_t *)value + PATCHGRAM_QSTRING_SIZE_OFFSET, sizeof(size));
            if (!utf16 || size <= 0) {
                return;
            }
            size_t out = 0;
            for (int64_t i = 0; i < size && out + 1 < capacity; i++) {
                const uint16_t ch = utf16[i];
                if (ch == 0) {
                    break;
                }
                destination[out++] = (ch <= 0x7f) ? (char)ch : '?';
            }
            destination[out] = '\0';
        }

        static bool patchgram_fragment_phone_link_char_is_safe(char ch) {
            return (ch >= '0' && ch <= '9') || ch == '+' || ch == '-' || ch == ' ';
        }

        static bool patchgram_fragment_phone_link_text_is_safe(const char *text) {
            if (!text || !text[0]) {
                return false;
            }
            bool has_digit = false;
            for (const char *cursor = text; *cursor; ++cursor) {
                if (!patchgram_fragment_phone_link_char_is_safe(*cursor)) {
                    return false;
                }
                if (*cursor >= '0' && *cursor <= '9') {
                    has_digit = true;
                }
            }
            return has_digit;
        }

        static void patchgram_fragment_phone_request_text_for_peer(
                void *peer,
                char *destination,
                size_t capacity) {
            if (!destination || capacity == 0) {
                return;
            }
            destination[0] = '\0';
            if (!peer) {
                return;
            }
            patchgram_copy_qstring_ascii(
                (uint8_t *)peer + PATCHGRAM_USER_PHONE_OFFSET,
                destination,
                capacity
            );
            if (patchgram_fragment_phone_link_text_is_safe(destination)) {
                return;
            }
            destination[0] = '\0';
        }

        static const char *patchgram_fragment_phone_without_plus(const char *phone) {
            if (!phone) {
                return "";
            }
            return phone[0] == '+' ? phone + 1 : phone;
        }

        static void patchgram_remember_fragment_phone_self(void *peer) {
            if (!peer || !patchgram_peer_is_self_user(peer)) {
                return;
            }
            patchgram_fragment_phone_request_text_for_peer(
                peer,
                g_fragment_phone_self_phone_utf8,
                sizeof(g_fragment_phone_self_phone_utf8)
            );
        }

        static void patchgram_track_fragment_phone_request(int32_t request_id, const char *username) {
            if (request_id <= 0) {
                return;
            }
            pthread_mutex_lock(&g_fragment_phone_request_ids_mutex);
            size_t empty_index = PATCHGRAM_MAX_TRACKED_FRAGMENT_REQUESTS;
            for (size_t i = 0; i < PATCHGRAM_MAX_TRACKED_FRAGMENT_REQUESTS; i++) {
                if (g_fragment_phone_request_ids[i].request_id == request_id) {
                    snprintf(
                        g_fragment_phone_request_ids[i].username,
                        sizeof(g_fragment_phone_request_ids[i].username),
                        "%s",
                        username ? username : ""
                    );
                    pthread_mutex_unlock(&g_fragment_phone_request_ids_mutex);
                    return;
                }
                if (g_fragment_phone_request_ids[i].request_id == 0
                    && empty_index == PATCHGRAM_MAX_TRACKED_FRAGMENT_REQUESTS) {
                    empty_index = i;
                }
            }
            if (empty_index != PATCHGRAM_MAX_TRACKED_FRAGMENT_REQUESTS) {
                g_fragment_phone_request_ids[empty_index].request_id = request_id;
                snprintf(
                    g_fragment_phone_request_ids[empty_index].username,
                    sizeof(g_fragment_phone_request_ids[empty_index].username),
                    "%s",
                    username ? username : ""
                );
            } else {
                g_fragment_phone_request_ids[0].request_id = request_id;
                snprintf(
                    g_fragment_phone_request_ids[0].username,
                    sizeof(g_fragment_phone_request_ids[0].username),
                    "%s",
                    username ? username : ""
                );
            }
            pthread_mutex_unlock(&g_fragment_phone_request_ids_mutex);
        }

        static bool patchgram_take_fragment_phone_request(int32_t request_id, char *username, size_t username_capacity) {
            if (request_id <= 0) {
                return false;
            }
            if (username && username_capacity > 0) {
                username[0] = '\0';
            }
            bool found = false;
            pthread_mutex_lock(&g_fragment_phone_request_ids_mutex);
            for (size_t i = 0; i < PATCHGRAM_MAX_TRACKED_FRAGMENT_REQUESTS; i++) {
                if (g_fragment_phone_request_ids[i].request_id == request_id) {
                    if (username && username_capacity > 0) {
                        snprintf(username, username_capacity, "%s", g_fragment_phone_request_ids[i].username);
                    }
                    g_fragment_phone_request_ids[i].request_id = 0;
                    g_fragment_phone_request_ids[i].username[0] = '\0';
                    found = true;
                    break;
                }
            }
            pthread_mutex_unlock(&g_fragment_phone_request_ids_mutex);
            return found;
        }

        static size_t patchgram_tl_string_length(const char *value) {
            const size_t length = value ? strlen(value) : 0;
            if (length < 254) {
                return 1 + length + ((4 - ((1 + length) & 3)) & 3);
            }
            return 4 + length + ((4 - ((4 + length) & 3)) & 3);
        }

        static void patchgram_tl_write_u32(uint8_t *buffer, size_t *offset, uint32_t value) {
            memcpy(buffer + *offset, &value, sizeof(value));
            *offset += sizeof(value);
        }

        static void patchgram_tl_write_i32(uint8_t *buffer, size_t *offset, int32_t value) {
            memcpy(buffer + *offset, &value, sizeof(value));
            *offset += sizeof(value);
        }

        static void patchgram_tl_write_i64(uint8_t *buffer, size_t *offset, int64_t value) {
            memcpy(buffer + *offset, &value, sizeof(value));
            *offset += sizeof(value);
        }

        static void patchgram_tl_write_string(uint8_t *buffer, size_t *offset, const char *value) {
            const uint8_t *bytes = (const uint8_t *)(value ? value : "");
            const size_t length = value ? strlen(value) : 0;
            const size_t prefix = (length < 254) ? 1 : 4;
            if (length < 254) {
                buffer[(*offset)++] = (uint8_t)length;
            } else {
                buffer[(*offset)++] = 254;
                buffer[(*offset)++] = (uint8_t)(length & 0xffU);
                buffer[(*offset)++] = (uint8_t)((length >> 8) & 0xffU);
                buffer[(*offset)++] = (uint8_t)((length >> 16) & 0xffU);
            }
            if (length > 0) {
                memcpy(buffer + *offset, bytes, length);
                *offset += length;
            }
            const size_t padding = (4 - ((prefix + length) & 3)) & 3;
            memset(buffer + *offset, 0, padding);
            *offset += padding;
        }

        static bool patchgram_tl_read_string_ascii(
            const uint8_t *buffer,
            size_t length,
            size_t offset,
            char *destination,
            size_t capacity
        ) {
            if (!buffer || !destination || capacity == 0 || offset >= length) {
                return false;
            }
            destination[0] = '\0';
            size_t size = buffer[offset++];
            if (size == 254) {
                if (offset + 3 > length) {
                    return false;
                }
                size = (size_t)buffer[offset]
                    | ((size_t)buffer[offset + 1] << 8)
                    | ((size_t)buffer[offset + 2] << 16);
                offset += 3;
            }
            if (offset + size > length) {
                return false;
            }
            const size_t copied = (size + 1 < capacity) ? size : (capacity - 1);
            memcpy(destination, buffer + offset, copied);
            destination[copied] = '\0';
            return true;
        }

        static bool patchgram_tl_read_string_ascii_next(
            const uint8_t *buffer,
            size_t length,
            size_t offset,
            char *destination,
            size_t capacity,
            size_t *next_offset
        ) {
            if (next_offset) {
                *next_offset = offset;
            }
            if (!buffer || !destination || capacity == 0 || offset >= length) {
                return false;
            }
            destination[0] = '\0';
            const size_t prefix_offset = offset;
            size_t size = buffer[offset++];
            size_t prefix = 1;
            if (size == 254) {
                if (offset + 3 > length) {
                    return false;
                }
                size = (size_t)buffer[offset]
                    | ((size_t)buffer[offset + 1] << 8)
                    | ((size_t)buffer[offset + 2] << 16);
                offset += 3;
                prefix = 4;
            }
            if (offset + size > length) {
                return false;
            }
            const size_t copied = (size + 1 < capacity) ? size : (capacity - 1);
            memcpy(destination, buffer + offset, copied);
            destination[copied] = '\0';
            offset += size;
            const size_t padding = (4 - ((prefix + size) & 3)) & 3;
            if (offset + padding > length) {
                return false;
            }
            offset += padding;
            if (offset <= prefix_offset) {
                return false;
            }
            if (next_offset) {
                *next_offset = offset;
            }
            return true;
        }

        static bool patchgram_tl_read_i32_at(
            const uint8_t *buffer,
            size_t length,
            size_t offset,
            int32_t *value_out
        ) {
            if (!buffer || !value_out || offset + sizeof(int32_t) > length) {
                return false;
            }
            memcpy(value_out, buffer + offset, sizeof(int32_t));
            return true;
        }

        static bool patchgram_tl_read_u64_at(
            const uint8_t *buffer,
            size_t length,
            size_t offset,
            uint64_t *value_out
        ) {
            if (!buffer || !value_out || offset + sizeof(uint64_t) > length) {
                return false;
            }
            memcpy(value_out, buffer + offset, sizeof(uint64_t));
            return true;
        }

        static const char *patchgram_tl_username_method_name(uint32_t constructor) {
            switch (constructor) {
            case PATCHGRAM_TL_ACCOUNT_CHECK_USERNAME:
                return "account.checkUsername";
            case PATCHGRAM_TL_ACCOUNT_UPDATE_USERNAME:
                return "account.updateUsername";
            case PATCHGRAM_TL_ACCOUNT_REORDER_USERNAMES:
                return "account.reorderUsernames";
            case PATCHGRAM_TL_ACCOUNT_TOGGLE_USERNAME:
                return "account.toggleUsername";
            case PATCHGRAM_TL_USERS_GET_USERS:
                return "users.getUsers";
            case PATCHGRAM_TL_USERS_GET_FULL_USER:
                return "users.getFullUser";
            default:
                return NULL;
            }
        }

        static void patchgram_log_tl_words(
            const char *prefix,
            int32_t request_id,
            const uint32_t *words,
            int64_t word_count
        ) {
            if (!prefix || !words || word_count <= 0) {
                return;
            }
            char buffer[512];
            size_t used = 0;
            const size_t limit = (word_count < 28) ? (size_t)word_count : 28;
            for (size_t i = 0; i < limit; i++) {
                int written = snprintf(
                    buffer + used,
                    sizeof(buffer) - used,
                    "%s%zu:%08x",
                    (i == 0) ? "" : " ",
                    i,
                    words[i]
                );
                if (written <= 0) {
                    break;
                }
                if ((size_t)written >= sizeof(buffer) - used) {
                    used = sizeof(buffer) - 1;
                    break;
                }
                used += (size_t)written;
            }
            buffer[sizeof(buffer) - 1] = '\0';
            patchgram_log(
                "%s requestId=%d wordCount=%lld words=%s%s",
                prefix,
                (int)request_id,
                (long long)word_count,
                buffer,
                ((int64_t)limit < word_count) ? " ..." : ""
            );
        }

        static void patchgram_append_diag_text(char *buffer, size_t capacity, const char *text) {
            if (!buffer || capacity == 0 || !text) {
                return;
            }
            const size_t used = strlen(buffer);
            if (used + 1 >= capacity) {
                return;
            }
            snprintf(buffer + used, capacity - used, "%s", text);
        }

        static void patchgram_append_diag_username_list(
            char *buffer,
            size_t capacity,
            const char *username,
            int32_t flags
        ) {
            if (!buffer || capacity == 0 || !username) {
                return;
            }
            char item[PATCHGRAM_MAX_USERNAME_UTF8 + 64];
            snprintf(
                item,
                sizeof(item),
                "%s@%s(flags=%d editable=%d active=%d)",
                buffer[0] ? ", " : "",
                username,
                (int)flags,
                (flags & 1) ? 1 : 0,
                (flags & 2) ? 1 : 0
            );
            patchgram_append_diag_text(buffer, capacity, item);
        }

        static void patchgram_log_tl_string_vector(
            const char *prefix,
            int32_t request_id,
            const uint8_t *bytes,
            size_t byte_count,
            size_t offset
        ) {
            if (!prefix || !bytes || offset + sizeof(uint32_t) * 2 > byte_count) {
                return;
            }
            uint32_t constructor = 0;
            int32_t count = 0;
            memcpy(&constructor, bytes + offset, sizeof(constructor));
            memcpy(&count, bytes + offset + sizeof(uint32_t), sizeof(count));
            if (constructor != PATCHGRAM_TL_VECTOR || count < 0 || count > 64) {
                patchgram_log(
                    "%s requestId=%d vector=invalid constructor=%08x count=%d offset=%zu",
                    prefix,
                    (int)request_id,
                    constructor,
                    (int)count,
                    offset
                );
                return;
            }
            char joined[512] = {0};
            size_t cursor = offset + sizeof(uint32_t) * 2;
            for (int32_t i = 0; i < count && i < 12; i++) {
                char value[PATCHGRAM_MAX_USERNAME_UTF8] = {0};
                size_t next = cursor;
                if (!patchgram_tl_read_string_ascii_next(bytes, byte_count, cursor, value, sizeof(value), &next)) {
                    patchgram_append_diag_text(joined, sizeof(joined), joined[0] ? ", <bad-string>" : "<bad-string>");
                    break;
                }
                if (joined[0]) {
                    patchgram_append_diag_text(joined, sizeof(joined), ", ");
                }
                patchgram_append_diag_text(joined, sizeof(joined), value);
                cursor = next;
            }
            patchgram_log(
                "%s requestId=%d vectorCount=%d values=[%s]%s",
                prefix,
                (int)request_id,
                (int)count,
                joined,
                count > 12 ? " ..." : ""
            );
        }

        static void patchgram_log_tl_username_vector(
            const char *prefix,
            int32_t request_id,
            const uint8_t *bytes,
            size_t byte_count,
            size_t offset
        ) {
            if (!prefix || !bytes || offset + sizeof(uint32_t) * 2 > byte_count) {
                return;
            }
            uint32_t constructor = 0;
            int32_t count = 0;
            memcpy(&constructor, bytes + offset, sizeof(constructor));
            memcpy(&count, bytes + offset + sizeof(uint32_t), sizeof(count));
            if (constructor != PATCHGRAM_TL_VECTOR || count < 0 || count > 64) {
                patchgram_log(
                    "%s requestId=%d vector=invalid constructor=%08x count=%d offset=%zu",
                    prefix,
                    (int)request_id,
                    constructor,
                    (int)count,
                    offset
                );
                return;
            }
            char joined[768] = {0};
            size_t cursor = offset + sizeof(uint32_t) * 2;
            for (int32_t i = 0; i < count && i < 12; i++) {
                uint32_t username_constructor = 0;
                int32_t flags = 0;
                if (cursor + sizeof(uint32_t) * 2 > byte_count) {
                    patchgram_append_diag_text(joined, sizeof(joined), joined[0] ? ", <truncated>" : "<truncated>");
                    break;
                }
                memcpy(&username_constructor, bytes + cursor, sizeof(username_constructor));
                memcpy(&flags, bytes + cursor + sizeof(uint32_t), sizeof(flags));
                if (username_constructor != PATCHGRAM_TL_USERNAME) {
                    char item[64];
                    snprintf(
                        item,
                        sizeof(item),
                        "%s<unexpected:%08x>",
                        joined[0] ? ", " : "",
                        username_constructor
                    );
                    patchgram_append_diag_text(joined, sizeof(joined), item);
                    break;
                }
                char username[PATCHGRAM_MAX_USERNAME_UTF8] = {0};
                size_t next = cursor + sizeof(uint32_t) * 2;
                if (!patchgram_tl_read_string_ascii_next(bytes, byte_count, next, username, sizeof(username), &next)) {
                    patchgram_append_diag_text(joined, sizeof(joined), joined[0] ? ", <bad-username>" : "<bad-username>");
                    break;
                }
                patchgram_append_diag_username_list(joined, sizeof(joined), username, flags);
                cursor = next;
            }
            patchgram_log(
                "%s requestId=%d vectorCount=%d values=[%s]%s",
                prefix,
                (int)request_id,
                (int)count,
                joined,
                count > 12 ? " ..." : ""
            );
        }

        static void patchgram_log_custom_username_request_tl(void *request_ref, int64_t ms_can_wait) {
            if (!request_ref || g_custom_username_tl_request_diag_logs >= 160) {
                return;
            }
            void *request_data = NULL;
            memcpy(&request_data, request_ref, sizeof(request_data));
            if (!request_data) {
                return;
            }
            uint32_t *words = NULL;
            int64_t word_count = 0;
            memcpy(&words, (const uint8_t *)request_data + PATCHGRAM_QVECTOR_PTR_OFFSET, sizeof(words));
            memcpy(&word_count, (const uint8_t *)request_data + PATCHGRAM_QVECTOR_SIZE_OFFSET, sizeof(word_count));
            if (!words || word_count <= PATCHGRAM_SERIALIZED_REQUEST_BODY_POSITION) {
                return;
            }
            int32_t request_id = 0;
            memcpy(&request_id, (const uint8_t *)request_data + PATCHGRAM_REQUEST_DATA_REQUEST_ID_OFFSET, sizeof(request_id));
            const uint8_t *bytes = (const uint8_t *)words;
            const size_t byte_count = (size_t)word_count * sizeof(uint32_t);
            const size_t max_scan = (word_count < 256) ? (size_t)word_count : 256;
            for (size_t i = PATCHGRAM_SERIALIZED_REQUEST_BODY_POSITION; i < max_scan; i++) {
                const uint32_t constructor = words[i];
                const char *method = patchgram_tl_username_method_name(constructor);
                if (!method) {
                    continue;
                }
                g_custom_username_tl_request_diag_logs++;
                patchgram_log(
                    "CUSTOM USERNAMES TL request method=%s constructor=%08x requestId=%d index=%zu words=%lld msCanWait=%lld enabled=%d configured=%zu",
                    method,
                    constructor,
                    (int)request_id,
                    i,
                    (long long)word_count,
                    (long long)ms_can_wait,
                    g_custom_list_usernames_enabled ? 1 : 0,
                    g_custom_username_entry_count
                );
                patchgram_log_tl_words("CUSTOM USERNAMES TL request dump", request_id, words, word_count);
                if (constructor == PATCHGRAM_TL_ACCOUNT_CHECK_USERNAME
                    || constructor == PATCHGRAM_TL_ACCOUNT_UPDATE_USERNAME
                    || constructor == PATCHGRAM_TL_ACCOUNT_TOGGLE_USERNAME) {
                    char username[PATCHGRAM_MAX_USERNAME_UTF8] = {0};
                    size_t next = 0;
                    if (patchgram_tl_read_string_ascii_next(
                            bytes,
                            byte_count,
                            (i + 1) * sizeof(uint32_t),
                            username,
                            sizeof(username),
                            &next)) {
                        uint32_t active_constructor = 0;
                        if (constructor == PATCHGRAM_TL_ACCOUNT_TOGGLE_USERNAME
                            && next + sizeof(active_constructor) <= byte_count) {
                            memcpy(&active_constructor, bytes + next, sizeof(active_constructor));
                        }
                        patchgram_log(
                            "CUSTOM USERNAMES TL request args method=%s requestId=%d username=%s nextOffset=%zu activeConstructor=%08x",
                            method,
                            (int)request_id,
                            username,
                            next,
                            active_constructor
                        );
                    }
                } else if (constructor == PATCHGRAM_TL_ACCOUNT_REORDER_USERNAMES) {
                    patchgram_log_tl_string_vector(
                        "CUSTOM USERNAMES TL request reorder",
                        request_id,
                        bytes,
                        byte_count,
                        (i + 1) * sizeof(uint32_t)
                    );
                }
                if (g_custom_username_tl_request_diag_logs >= 160) {
                    break;
                }
            }
        }

        static void patchgram_track_custom_username_full_user_request(int32_t request_id) {
            if (request_id <= 0) {
                return;
            }
            pthread_mutex_lock(&g_custom_username_full_user_request_ids_mutex);
            for (size_t i = 0; i < PATCHGRAM_MAX_TRACKED_FRAGMENT_REQUESTS; i++) {
                if (g_custom_username_full_user_request_ids[i] == request_id) {
                    pthread_mutex_unlock(&g_custom_username_full_user_request_ids_mutex);
                    return;
                }
            }
            for (size_t i = 0; i < PATCHGRAM_MAX_TRACKED_FRAGMENT_REQUESTS; i++) {
                if (g_custom_username_full_user_request_ids[i] == 0) {
                    g_custom_username_full_user_request_ids[i] = request_id;
                    pthread_mutex_unlock(&g_custom_username_full_user_request_ids_mutex);
                    return;
                }
            }
            g_custom_username_full_user_request_ids[0] = request_id;
            pthread_mutex_unlock(&g_custom_username_full_user_request_ids_mutex);
        }

        static bool patchgram_take_custom_username_full_user_request(int32_t request_id) {
            if (request_id <= 0) {
                return false;
            }
            bool found = false;
            pthread_mutex_lock(&g_custom_username_full_user_request_ids_mutex);
            for (size_t i = 0; i < PATCHGRAM_MAX_TRACKED_FRAGMENT_REQUESTS; i++) {
                if (g_custom_username_full_user_request_ids[i] == request_id) {
                    g_custom_username_full_user_request_ids[i] = 0;
                    found = true;
                    break;
                }
            }
            pthread_mutex_unlock(&g_custom_username_full_user_request_ids_mutex);
            return found;
        }

        static bool patchgram_custom_username_full_user_request_should_be_local(
            void *request_ref,
            int32_t *request_id_out
        ) {
            if (request_id_out) {
                *request_id_out = 0;
            }
            if (!g_custom_list_usernames_enabled || g_custom_username_entry_count == 0 || !request_ref) {
                return false;
            }
            void *request_data = NULL;
            memcpy(&request_data, request_ref, sizeof(request_data));
            if (!request_data) {
                return false;
            }
            uint32_t *words = NULL;
            int64_t word_count = 0;
            memcpy(&words, (const uint8_t *)request_data + PATCHGRAM_QVECTOR_PTR_OFFSET, sizeof(words));
            memcpy(&word_count, (const uint8_t *)request_data + PATCHGRAM_QVECTOR_SIZE_OFFSET, sizeof(word_count));
            if (!words || word_count <= PATCHGRAM_SERIALIZED_REQUEST_BODY_POSITION) {
                return false;
            }
            int32_t request_id = 0;
            memcpy(&request_id, (const uint8_t *)request_data + PATCHGRAM_REQUEST_DATA_REQUEST_ID_OFFSET, sizeof(request_id));
            if (request_id <= 0) {
                return false;
            }
            const size_t max_scan = (word_count < 64) ? (size_t)word_count : 64;
            for (size_t i = PATCHGRAM_SERIALIZED_REQUEST_BODY_POSITION; i < max_scan; i++) {
                if (words[i] != PATCHGRAM_TL_USERS_GET_FULL_USER) {
                    continue;
                }
                if (request_id_out) {
                    *request_id_out = request_id;
                }
                return true;
            }
            return false;
        }

        static bool patchgram_response_has_custom_username_tl(const uint32_t *words, int64_t word_count) {
            if (!words || word_count <= 0) {
                return false;
            }
            const size_t max_scan = (word_count < 512) ? (size_t)word_count : 512;
            for (size_t i = 0; i < max_scan; i++) {
                switch (words[i]) {
                case PATCHGRAM_TL_UPDATE_USER_NAME:
                case PATCHGRAM_TL_USERNAME:
                case PATCHGRAM_TL_USER:
                case PATCHGRAM_TL_USER_FULL:
                case PATCHGRAM_TL_USERS_USER_FULL:
                    return true;
                default:
                    break;
                }
            }
            return false;
        }

        static void patchgram_log_update_user_name_details(
            int32_t request_id,
            const uint8_t *bytes,
            size_t byte_count,
            size_t word_index
        ) {
            uint64_t user_id = 0;
            patchgram_tl_read_u64_at(bytes, byte_count, (word_index + 1) * sizeof(uint32_t), &user_id);
            char first_name[PATCHGRAM_MAX_USERNAME_UTF8] = {0};
            char last_name[PATCHGRAM_MAX_USERNAME_UTF8] = {0};
            size_t next = (word_index + 3) * sizeof(uint32_t);
            patchgram_tl_read_string_ascii_next(bytes, byte_count, next, first_name, sizeof(first_name), &next);
            patchgram_tl_read_string_ascii_next(bytes, byte_count, next, last_name, sizeof(last_name), &next);
            patchgram_log(
                "CUSTOM USERNAMES TL response updateUserName requestId=%d userId=%llu first=%s last=%s vectorOffset=%zu",
                (int)request_id,
                (unsigned long long)user_id,
                first_name,
                last_name,
                next
            );
            patchgram_log_tl_username_vector(
                "CUSTOM USERNAMES TL response updateUserName usernames",
                request_id,
                bytes,
                byte_count,
                next
            );
        }

        static uint8_t *patchgram_build_custom_username_tl_vector(size_t *byte_count_out) {
            if (byte_count_out) {
                *byte_count_out = 0;
            }
            if (!g_custom_list_usernames_enabled || g_custom_username_entry_count == 0) {
                return NULL;
            }
            size_t byte_count = sizeof(uint32_t) + sizeof(int32_t);
            for (size_t i = 0; i < g_custom_username_entry_count; i++) {
                byte_count += sizeof(uint32_t) + sizeof(int32_t)
                    + patchgram_tl_string_length(g_custom_username_entries[i].username);
            }
            const size_t padded_count = (byte_count + 3U) & ~(size_t)3U;
            uint8_t *buffer = (uint8_t *)calloc(padded_count, 1);
            if (!buffer) {
                return NULL;
            }
            size_t offset = 0;
            patchgram_tl_write_u32(buffer, &offset, PATCHGRAM_TL_VECTOR);
            patchgram_tl_write_i32(buffer, &offset, (int32_t)g_custom_username_entry_count);
            for (size_t i = 0; i < g_custom_username_entry_count; i++) {
                const int32_t flags = (i == 0) ? 3 : 2;
                patchgram_tl_write_u32(buffer, &offset, PATCHGRAM_TL_USERNAME);
                patchgram_tl_write_i32(buffer, &offset, flags);
                patchgram_tl_write_string(buffer, &offset, g_custom_username_entries[i].username);
            }
            if (byte_count_out) {
                *byte_count_out = padded_count;
            }
            return buffer;
        }

        static bool patchgram_tl_username_object_end(
            const uint8_t *bytes,
            size_t byte_count,
            size_t offset,
            size_t *end_out
        ) {
            if (end_out) {
                *end_out = offset;
            }
            if (!bytes || offset + sizeof(uint32_t) * 2 > byte_count) {
                return false;
            }
            uint32_t constructor = 0;
            memcpy(&constructor, bytes + offset, sizeof(constructor));
            if (constructor != PATCHGRAM_TL_USERNAME) {
                return false;
            }
            char username[PATCHGRAM_MAX_USERNAME_UTF8] = {0};
            size_t next = offset + sizeof(uint32_t) * 2;
            if (!patchgram_tl_read_string_ascii_next(bytes, byte_count, next, username, sizeof(username), &next)
                || !username[0]) {
                return false;
            }
            if (end_out) {
                *end_out = next;
            }
            return true;
        }

        static bool patchgram_tl_skip_string(
            const uint8_t *bytes,
            size_t byte_count,
            size_t *offset
        ) {
            char ignored[1] = {0};
            size_t next = offset ? *offset : 0;
            if (!offset || !patchgram_tl_read_string_ascii_next(bytes, byte_count, *offset, ignored, sizeof(ignored), &next)) {
                return false;
            }
            *offset = next;
            return true;
        }

        static bool patchgram_tl_skip_bytes(
            const uint8_t *bytes,
            size_t byte_count,
            size_t *offset
        ) {
            return patchgram_tl_skip_string(bytes, byte_count, offset);
        }

        static bool patchgram_tl_skip_u32(size_t byte_count, size_t *offset) {
            if (!offset || *offset + sizeof(uint32_t) > byte_count) {
                return false;
            }
            *offset += sizeof(uint32_t);
            return true;
        }

        static bool patchgram_tl_skip_i64(size_t byte_count, size_t *offset) {
            if (!offset || *offset + sizeof(int64_t) > byte_count) {
                return false;
            }
            *offset += sizeof(int64_t);
            return true;
        }

        static bool patchgram_tl_skip_user_profile_photo(
            const uint8_t *bytes,
            size_t byte_count,
            size_t *offset
        ) {
            if (!offset || *offset + sizeof(uint32_t) > byte_count) {
                return false;
            }
            uint32_t constructor = 0;
            memcpy(&constructor, bytes + *offset, sizeof(constructor));
            *offset += sizeof(uint32_t);
            if (constructor == 0x4f11bae1U) {
                return true;
            }
            if (constructor != 0x82d1f706U) {
                return false;
            }
            uint32_t flags = 0;
            if (*offset + sizeof(flags) > byte_count) {
                return false;
            }
            memcpy(&flags, bytes + *offset, sizeof(flags));
            *offset += sizeof(flags);
            if (!patchgram_tl_skip_i64(byte_count, offset)) {
                return false;
            }
            if ((flags & (1U << 1)) != 0 && !patchgram_tl_skip_bytes(bytes, byte_count, offset)) {
                return false;
            }
            return patchgram_tl_skip_u32(byte_count, offset);
        }

        static bool patchgram_tl_skip_user_status(
            const uint8_t *bytes,
            size_t byte_count,
            size_t *offset
        ) {
            if (!offset || *offset + sizeof(uint32_t) > byte_count) {
                return false;
            }
            uint32_t constructor = 0;
            memcpy(&constructor, bytes + *offset, sizeof(constructor));
            *offset += sizeof(uint32_t);
            switch (constructor) {
            case 0x09d05049U:
            case 0x7b197dc8U:
            case 0x541a1d1aU:
            case 0x65899777U:
            case 0xcf7d64b1U:
                if (constructor == 0x7b197dc8U
                    || constructor == 0x541a1d1aU
                    || constructor == 0x65899777U) {
                    return patchgram_tl_skip_u32(byte_count, offset);
                }
                return true;
            case 0xedb93949U:
            case 0x8c703fU:
                return patchgram_tl_skip_u32(byte_count, offset);
            default:
                return false;
            }
        }

        static bool patchgram_tl_skip_restriction_reason_vector(
            const uint8_t *bytes,
            size_t byte_count,
            size_t *offset
        ) {
            if (!offset || *offset + sizeof(uint32_t) * 2 > byte_count) {
                return false;
            }
            uint32_t constructor = 0;
            int32_t count = 0;
            memcpy(&constructor, bytes + *offset, sizeof(constructor));
            memcpy(&count, bytes + *offset + sizeof(uint32_t), sizeof(count));
            if (constructor != PATCHGRAM_TL_VECTOR || count < 0 || count > 64) {
                return false;
            }
            *offset += sizeof(uint32_t) * 2;
            for (int32_t i = 0; i < count; i++) {
                uint32_t item_constructor = 0;
                if (*offset + sizeof(item_constructor) > byte_count) {
                    return false;
                }
                memcpy(&item_constructor, bytes + *offset, sizeof(item_constructor));
                if (item_constructor != 0xd072acb4U) {
                    return false;
                }
                *offset += sizeof(item_constructor);
                if (!patchgram_tl_skip_string(bytes, byte_count, offset)
                    || !patchgram_tl_skip_string(bytes, byte_count, offset)
                    || !patchgram_tl_skip_string(bytes, byte_count, offset)) {
                    return false;
                }
            }
            return true;
        }

        static bool patchgram_tl_skip_emoji_status(
            const uint8_t *bytes,
            size_t byte_count,
            size_t *offset
        ) {
            if (!offset || *offset + sizeof(uint32_t) > byte_count) {
                return false;
            }
            uint32_t constructor = 0;
            memcpy(&constructor, bytes + *offset, sizeof(constructor));
            *offset += sizeof(uint32_t);
            if (constructor == 0x2de11aaeU) {
                return true;
            }
            uint32_t flags = 0;
            if (*offset + sizeof(flags) > byte_count) {
                return false;
            }
            memcpy(&flags, bytes + *offset, sizeof(flags));
            *offset += sizeof(flags);
            if (constructor == 0xe7ff068aU) {
                if (!patchgram_tl_skip_i64(byte_count, offset)) {
                    return false;
                }
                return ((flags & 1U) == 0) || patchgram_tl_skip_u32(byte_count, offset);
            }
            if (constructor != 0x7184603bU) {
                return false;
            }
            if (!patchgram_tl_skip_i64(byte_count, offset)
                || !patchgram_tl_skip_i64(byte_count, offset)
                || !patchgram_tl_skip_string(bytes, byte_count, offset)
                || !patchgram_tl_skip_string(bytes, byte_count, offset)
                || !patchgram_tl_skip_i64(byte_count, offset)
                || !patchgram_tl_skip_u32(byte_count, offset)
                || !patchgram_tl_skip_u32(byte_count, offset)
                || !patchgram_tl_skip_u32(byte_count, offset)
                || !patchgram_tl_skip_u32(byte_count, offset)) {
                return false;
            }
            return ((flags & 1U) == 0) || patchgram_tl_skip_u32(byte_count, offset);
        }

        static bool patchgram_find_missing_username_insert_after_user(
            const uint32_t *words,
            int64_t word_count,
            size_t user_word_index,
            struct PatchgramTLRange *range_out
        ) {
            if (range_out) {
                range_out->start = 0;
                range_out->end = 0;
                range_out->flags2_word_index = 0;
                range_out->inserts_missing_field = false;
            }
            if (!words || word_count <= 0 || user_word_index + 5 >= (size_t)word_count) {
                return false;
            }
            const uint8_t *bytes = (const uint8_t *)words;
            const size_t byte_count = (size_t)word_count * sizeof(uint32_t);
            const uint32_t flags = words[user_word_index + 1];
            const uint32_t flags2 = words[user_word_index + 2];
            if ((flags & (1U << 10)) == 0 || (flags2 & 1U) != 0) {
                return false;
            }
            size_t offset = (user_word_index + 3) * sizeof(uint32_t);
            if (!patchgram_tl_skip_i64(byte_count, &offset)) {
                return false;
            }
            if ((flags & (1U << 0)) != 0 && !patchgram_tl_skip_i64(byte_count, &offset)) {
                return false;
            }
            if ((flags & (1U << 1)) != 0 && !patchgram_tl_skip_string(bytes, byte_count, &offset)) {
                return false;
            }
            if ((flags & (1U << 2)) != 0 && !patchgram_tl_skip_string(bytes, byte_count, &offset)) {
                return false;
            }
            if ((flags & (1U << 3)) != 0 && !patchgram_tl_skip_string(bytes, byte_count, &offset)) {
                return false;
            }
            if ((flags & (1U << 4)) != 0 && !patchgram_tl_skip_string(bytes, byte_count, &offset)) {
                return false;
            }
            if ((flags & (1U << 5)) != 0 && !patchgram_tl_skip_user_profile_photo(bytes, byte_count, &offset)) {
                return false;
            }
            if ((flags & (1U << 6)) != 0 && !patchgram_tl_skip_user_status(bytes, byte_count, &offset)) {
                return false;
            }
            if ((flags & (1U << 14)) != 0 && !patchgram_tl_skip_u32(byte_count, &offset)) {
                return false;
            }
            if ((flags & (1U << 18)) != 0 && !patchgram_tl_skip_restriction_reason_vector(bytes, byte_count, &offset)) {
                return false;
            }
            if ((flags & (1U << 19)) != 0 && !patchgram_tl_skip_string(bytes, byte_count, &offset)) {
                return false;
            }
            if ((flags & (1U << 22)) != 0 && !patchgram_tl_skip_string(bytes, byte_count, &offset)) {
                return false;
            }
            if ((flags & (1U << 30)) != 0 && !patchgram_tl_skip_emoji_status(bytes, byte_count, &offset)) {
                return false;
            }
            if (offset > byte_count) {
                return false;
            }
            if (range_out) {
                range_out->start = offset;
                range_out->end = offset;
                range_out->flags2_word_index = user_word_index + 2;
                range_out->inserts_missing_field = true;
            }
            return true;
        }

        static bool patchgram_find_username_vector_range_after_user(
            const uint32_t *words,
            int64_t word_count,
            size_t user_word_index,
            struct PatchgramTLRange *range_out,
            int32_t *count_out
        ) {
            if (range_out) {
                range_out->start = 0;
                range_out->end = 0;
                range_out->flags2_word_index = user_word_index + 2;
                range_out->inserts_missing_field = false;
            }
            if (count_out) {
                *count_out = 0;
            }
            if (!words || word_count <= 0 || user_word_index + 5 >= (size_t)word_count) {
                return false;
            }
            const uint8_t *bytes = (const uint8_t *)words;
            const size_t byte_count = (size_t)word_count * sizeof(uint32_t);
            const size_t scan_end = ((size_t)word_count < user_word_index + 220)
                ? (size_t)word_count
                : user_word_index + 220;
            for (size_t i = user_word_index + 5; i + 2 < scan_end; i++) {
                if (words[i] != PATCHGRAM_TL_VECTOR) {
                    continue;
                }
                int32_t count = 0;
                if (!patchgram_tl_read_i32_at(bytes, byte_count, (i + 1) * sizeof(uint32_t), &count)
                    || count <= 0
                    || count > 64) {
                    continue;
                }
                size_t cursor = (i + 2) * sizeof(uint32_t);
                bool valid = true;
                for (int32_t item = 0; item < count; item++) {
                    size_t next = cursor;
                    if (!patchgram_tl_username_object_end(bytes, byte_count, cursor, &next)) {
                        valid = false;
                        break;
                    }
                    cursor = next;
                }
                if (!valid) {
                    continue;
                }
                if (range_out) {
                    range_out->start = i * sizeof(uint32_t);
                    range_out->end = cursor;
                    range_out->flags2_word_index = user_word_index + 2;
                    range_out->inserts_missing_field = false;
                }
                if (count_out) {
                    *count_out = count;
                }
                return true;
            }
            return false;
        }

        static size_t patchgram_collect_self_username_vector_ranges(
            const uint32_t *words,
            int64_t word_count,
            struct PatchgramTLRange *ranges,
            int32_t *counts,
            size_t capacity
        ) {
            if (!words || word_count <= 0 || !ranges || capacity == 0) {
                return 0;
            }
            size_t range_count = 0;
            const size_t max_scan = (word_count < 8192) ? (size_t)word_count : 8192;
            for (size_t i = 0; i + 5 < max_scan && range_count < capacity; i++) {
                if (words[i] != PATCHGRAM_TL_USER) {
                    continue;
                }
                const uint32_t flags = words[i + 1];
                const uint32_t flags2 = words[i + 2];
                if ((flags & (1U << 10)) == 0 || (flags2 & 1U) == 0) {
                    continue;
                }
                struct PatchgramTLRange range;
                int32_t old_count = 0;
                if (!patchgram_find_username_vector_range_after_user(words, word_count, i, &range, &old_count)) {
                    if (!patchgram_find_missing_username_insert_after_user(words, word_count, i, &range)) {
                        if (g_custom_username_tl_patch_logs < 96) {
                            g_custom_username_tl_patch_logs++;
                            patchgram_log(
                                "CUSTOM USERNAMES TL patch skipped reason=self-vector-not-found userIndex=%zu flags=%08x flags2=%08x",
                                i,
                                flags,
                                flags2
                            );
                        }
                        continue;
                    }
                    old_count = 0;
                    if (g_custom_username_tl_patch_logs < 96) {
                        g_custom_username_tl_patch_logs++;
                        patchgram_log(
                            "CUSTOM USERNAMES TL patch insert planned userIndex=%zu flags=%08x flags2=%08x insertOffset=%zu",
                            i,
                            flags,
                            flags2,
                            range.start
                        );
                    }
                }
                bool duplicate = false;
                for (size_t existing = 0; existing < range_count; existing++) {
                    if (ranges[existing].start == range.start) {
                        duplicate = true;
                        break;
                    }
                }
                if (duplicate) {
                    continue;
                }
                ranges[range_count] = range;
                if (counts) {
                    counts[range_count] = old_count;
                }
                range_count++;
            }
            return range_count;
        }

        static bool patchgram_apply_custom_username_list_response(void *response) {
            if (!response || !g_custom_list_usernames_enabled || g_custom_username_entry_count == 0) {
                return false;
            }
            int32_t request_id = 0;
            memcpy(&request_id, (const uint8_t *)response + PATCHGRAM_RESPONSE_REQUEST_ID_OFFSET, sizeof(request_id));
            if (!patchgram_take_custom_username_full_user_request(request_id)) {
                return false;
            }
            uint32_t *words = NULL;
            int64_t word_count = 0;
            memcpy(&words, (const uint8_t *)response + PATCHGRAM_QVECTOR_PTR_OFFSET, sizeof(words));
            memcpy(&word_count, (const uint8_t *)response + PATCHGRAM_QVECTOR_SIZE_OFFSET, sizeof(word_count));
            if (!words || word_count <= 0 || !patchgram_response_has_custom_username_tl(words, word_count)) {
                return false;
            }
            struct PatchgramTLRange ranges[PATCHGRAM_MAX_USERNAME_TL_REPLACEMENTS];
            int32_t old_counts[PATCHGRAM_MAX_USERNAME_TL_REPLACEMENTS] = {0};
            const size_t range_count = patchgram_collect_self_username_vector_ranges(
                words,
                word_count,
                ranges,
                old_counts,
                PATCHGRAM_MAX_USERNAME_TL_REPLACEMENTS
            );
            if (range_count == 0) {
                return false;
            }
            size_t replacement_byte_count = 0;
            uint8_t *replacement = patchgram_build_custom_username_tl_vector(&replacement_byte_count);
            if (!replacement || replacement_byte_count == 0) {
                free(replacement);
                return false;
            }
            const uint8_t *old_bytes = (const uint8_t *)words;
            const size_t old_byte_count = (size_t)word_count * sizeof(uint32_t);
            size_t new_byte_count = old_byte_count;
            for (size_t i = 0; i < range_count; i++) {
                if (ranges[i].end <= ranges[i].start || ranges[i].end > old_byte_count) {
                    free(replacement);
                    return false;
                }
                new_byte_count = new_byte_count - (ranges[i].end - ranges[i].start) + replacement_byte_count;
            }
            new_byte_count = (new_byte_count + 3U) & ~(size_t)3U;
            uint8_t *new_bytes = (uint8_t *)calloc(new_byte_count, 1);
            if (!new_bytes) {
                free(replacement);
                return false;
            }
            size_t source_offset = 0;
            size_t destination_offset = 0;
            for (size_t i = 0; i < range_count; i++) {
                const size_t before_count = ranges[i].start - source_offset;
                memcpy(new_bytes + destination_offset, old_bytes + source_offset, before_count);
                destination_offset += before_count;
                memcpy(new_bytes + destination_offset, replacement, replacement_byte_count);
                destination_offset += replacement_byte_count;
                source_offset = ranges[i].end;
            }
            if (source_offset < old_byte_count) {
                memcpy(new_bytes + destination_offset, old_bytes + source_offset, old_byte_count - source_offset);
                destination_offset += old_byte_count - source_offset;
            }
            free(replacement);
            size_t inserted_count = 0;
            for (size_t i = 0; i < range_count; i++) {
                if (!ranges[i].inserts_missing_field) {
                    continue;
                }
                const size_t old_flags2_offset = ranges[i].flags2_word_index * sizeof(uint32_t);
                size_t new_flags2_offset = old_flags2_offset;
                for (size_t j = 0; j < range_count; j++) {
                    if (ranges[j].start > old_flags2_offset) {
                        break;
                    }
                    const size_t old_range_size = ranges[j].end - ranges[j].start;
                    new_flags2_offset = new_flags2_offset - old_range_size + replacement_byte_count;
                }
                if (new_flags2_offset + sizeof(uint32_t) <= new_byte_count) {
                    uint32_t flags2 = 0;
                    memcpy(&flags2, new_bytes + new_flags2_offset, sizeof(flags2));
                    flags2 |= 1U;
                    memcpy(new_bytes + new_flags2_offset, &flags2, sizeof(flags2));
                    inserted_count++;
                }
            }
            int64_t new_word_count = (int64_t)(new_byte_count / sizeof(uint32_t));
            void *data_header = NULL;
            memcpy((uint8_t *)response + PATCHGRAM_QVECTOR_D_OFFSET, &data_header, sizeof(data_header));
            memcpy((uint8_t *)response + PATCHGRAM_QVECTOR_PTR_OFFSET, &new_bytes, sizeof(new_bytes));
            memcpy((uint8_t *)response + PATCHGRAM_QVECTOR_SIZE_OFFSET, &new_word_count, sizeof(new_word_count));
            if (g_custom_username_tl_patch_logs < 160) {
                g_custom_username_tl_patch_logs++;
                patchgram_log(
                    "CUSTOM USERNAMES TL response substituted requestId=%d replacements=%zu inserted=%zu oldWords=%lld newWords=%lld configured=%zu first=%s oldFirstCount=%d",
                    (int)request_id,
                    range_count,
                    inserted_count,
                    (long long)word_count,
                    (long long)new_word_count,
                    g_custom_username_entry_count,
                    g_custom_username_entries[0].username,
                    (int)old_counts[0]
                );
            }
            return true;
        }

        static void patchgram_log_custom_username_response_tl(void *response) {
            if (!response || g_custom_username_tl_response_diag_logs >= 160) {
                return;
            }
            int32_t request_id = 0;
            memcpy(&request_id, (const uint8_t *)response + PATCHGRAM_RESPONSE_REQUEST_ID_OFFSET, sizeof(request_id));
            uint32_t *words = NULL;
            int64_t word_count = 0;
            memcpy(&words, (const uint8_t *)response + PATCHGRAM_QVECTOR_PTR_OFFSET, sizeof(words));
            memcpy(&word_count, (const uint8_t *)response + PATCHGRAM_QVECTOR_SIZE_OFFSET, sizeof(word_count));
            if (!words || word_count <= 0 || !patchgram_response_has_custom_username_tl(words, word_count)) {
                return;
            }
            g_custom_username_tl_response_diag_logs++;
            const uint8_t *bytes = (const uint8_t *)words;
            const size_t byte_count = (size_t)word_count * sizeof(uint32_t);
            patchgram_log(
                "CUSTOM USERNAMES TL response seen requestId=%d words=%lld enabled=%d configured=%zu",
                (int)request_id,
                (long long)word_count,
                g_custom_list_usernames_enabled ? 1 : 0,
                g_custom_username_entry_count
            );
            patchgram_log_tl_words("CUSTOM USERNAMES TL response dump", request_id, words, word_count);
            const size_t max_scan = (word_count < 512) ? (size_t)word_count : 512;
            size_t username_logs = 0;
            for (size_t i = 0; i < max_scan && username_logs < 16; i++) {
                const uint32_t constructor = words[i];
                if (constructor == PATCHGRAM_TL_UPDATE_USER_NAME) {
                    patchgram_log_update_user_name_details(request_id, bytes, byte_count, i);
                } else if (constructor == PATCHGRAM_TL_USERNAME) {
                    int32_t flags = 0;
                    patchgram_tl_read_i32_at(bytes, byte_count, (i + 1) * sizeof(uint32_t), &flags);
                    char username[PATCHGRAM_MAX_USERNAME_UTF8] = {0};
                    patchgram_tl_read_string_ascii(
                        bytes,
                        byte_count,
                        (i + 2) * sizeof(uint32_t),
                        username,
                        sizeof(username)
                    );
                    patchgram_log(
                        "CUSTOM USERNAMES TL response username requestId=%d index=%zu flags=%d editable=%d active=%d username=%s",
                        (int)request_id,
                        i,
                        (int)flags,
                        (flags & 1) ? 1 : 0,
                        (flags & 2) ? 1 : 0,
                        username
                    );
                    username_logs++;
                } else if (constructor == PATCHGRAM_TL_USER && i + 3 < max_scan) {
                    const uint32_t flags = words[i + 1];
                    const uint32_t flags2 = words[i + 2];
                    patchgram_log(
                        "CUSTOM USERNAMES TL response user constructor requestId=%d index=%zu flags=%08x flags2=%08x self=%d hasUsernames=%d",
                        (int)request_id,
                        i,
                        flags,
                        flags2,
                        (flags & (1U << 10)) ? 1 : 0,
                        (flags2 & 1U) ? 1 : 0
                    );
                }
            }
        }

        static void patchgram_track_fact_check_request(int32_t request_id, int32_t count) {
            if (request_id <= 0 || count <= 0) {
                return;
            }
            pthread_mutex_lock(&g_fact_check_requests_mutex);
            size_t empty_index = PATCHGRAM_MAX_TRACKED_FACT_CHECK_REQUESTS;
            for (size_t i = 0; i < PATCHGRAM_MAX_TRACKED_FACT_CHECK_REQUESTS; i++) {
                if (g_fact_check_requests[i].request_id == request_id) {
                    g_fact_check_requests[i].count = count;
                    pthread_mutex_unlock(&g_fact_check_requests_mutex);
                    return;
                }
                if (g_fact_check_requests[i].request_id == 0 && empty_index == PATCHGRAM_MAX_TRACKED_FACT_CHECK_REQUESTS) {
                    empty_index = i;
                }
            }
            if (empty_index != PATCHGRAM_MAX_TRACKED_FACT_CHECK_REQUESTS) {
                g_fact_check_requests[empty_index].request_id = request_id;
                g_fact_check_requests[empty_index].count = count;
            } else {
                g_fact_check_requests[0].request_id = request_id;
                g_fact_check_requests[0].count = count;
            }
            pthread_mutex_unlock(&g_fact_check_requests_mutex);
        }

        static int32_t patchgram_take_fact_check_request(int32_t request_id) {
            if (request_id <= 0) {
                return 0;
            }
            int32_t count = 0;
            pthread_mutex_lock(&g_fact_check_requests_mutex);
            for (size_t i = 0; i < PATCHGRAM_MAX_TRACKED_FACT_CHECK_REQUESTS; i++) {
                if (g_fact_check_requests[i].request_id == request_id) {
                    count = g_fact_check_requests[i].count;
                    g_fact_check_requests[i].request_id = 0;
                    g_fact_check_requests[i].count = 0;
                    break;
                }
            }
            pthread_mutex_unlock(&g_fact_check_requests_mutex);
            return count;
        }

        static bool patchgram_fact_check_request_should_be_local(
            void *request_ref,
            int32_t *request_id_out,
            int32_t *count_out
        ) {
            if (request_id_out) {
                *request_id_out = 0;
            }
            if (count_out) {
                *count_out = 0;
            }
            if (!g_message_settings_enabled || !g_message_fact_check_enabled || !request_ref) {
                return false;
            }
            if (!g_message_fact_check_text[0]) {
                if (g_message_fact_check_request_skip_logs < 32) {
                    g_message_fact_check_request_skip_logs++;
                    patchgram_log("FACT CHECK request skipped reason=empty-text");
                }
                return false;
            }
            void *request_data = NULL;
            memcpy(&request_data, request_ref, sizeof(request_data));
            if (!request_data) {
                return false;
            }
            uint32_t *words = NULL;
            int64_t word_count = 0;
            memcpy(&words, (const uint8_t *)request_data + PATCHGRAM_QVECTOR_PTR_OFFSET, sizeof(words));
            memcpy(&word_count, (const uint8_t *)request_data + PATCHGRAM_QVECTOR_SIZE_OFFSET, sizeof(word_count));
            if (!words || word_count <= PATCHGRAM_SERIALIZED_REQUEST_BODY_POSITION) {
                return false;
            }
            int32_t request_id = 0;
            memcpy(&request_id, (const uint8_t *)request_data + PATCHGRAM_REQUEST_DATA_REQUEST_ID_OFFSET, sizeof(request_id));
            const uint8_t *bytes = (const uint8_t *)words;
            const size_t byte_count = (size_t)word_count * sizeof(uint32_t);
            const size_t max_scan = (word_count < 512) ? (size_t)word_count : 512;
            bool has_method = false;
            int32_t count = 0;
            for (size_t i = PATCHGRAM_SERIALIZED_REQUEST_BODY_POSITION; i < max_scan; i++) {
                if (words[i] != PATCHGRAM_TL_MESSAGES_GET_FACT_CHECK) {
                    continue;
                }
                has_method = true;
                for (size_t j = i + 1; j + 1 < max_scan; j++) {
                    if (words[j] != PATCHGRAM_TL_VECTOR) {
                        continue;
                    }
                    int32_t candidate_count = 0;
                    if (patchgram_tl_read_i32_at(bytes, byte_count, (j + 1) * sizeof(uint32_t), &candidate_count)
                        && candidate_count > 0
                        && candidate_count <= 256
                        && j + 2 + (size_t)candidate_count <= max_scan) {
                        count = candidate_count;
                        break;
                    }
                }
                break;
            }
            if (has_method && g_message_fact_check_request_logs < 96) {
                g_message_fact_check_request_logs++;
                patchgram_log(
                    "FACT CHECK getFactCheck seen requestId=%d count=%d words=%lld enabled=%d textLength=%zu",
                    (int)request_id,
                    (int)count,
                    (long long)word_count,
                    g_message_fact_check_enabled ? 1 : 0,
                    strlen(g_message_fact_check_text)
                );
            }
            if (!has_method || count <= 0 || request_id <= 0) {
                if ((has_method || request_id > 0) && g_message_fact_check_request_skip_logs < 96) {
                    g_message_fact_check_request_skip_logs++;
                    patchgram_log(
                        "FACT CHECK request skipped reason=%s requestId=%d count=%d hasMethod=%d",
                        !has_method ? "missing-method" : (count <= 0 ? "missing-msg-ids" : "missing-request-id"),
                        (int)request_id,
                        (int)count,
                        has_method ? 1 : 0
                    );
                }
                return false;
            }
            if (request_id_out) {
                *request_id_out = request_id;
            }
            if (count_out) {
                *count_out = count;
            }
            return true;
        }

        static bool patchgram_fragment_request_should_be_local(
                void *request_ref,
                int32_t *request_id_out,
                char *username_out,
                size_t username_capacity) {
            if (request_id_out) {
                *request_id_out = 0;
            }
            if (username_out && username_capacity > 0) {
                username_out[0] = '\0';
            }
            if ((!g_fragment_phone_enabled && !g_custom_list_usernames_enabled) || !request_ref) {
                return false;
            }
            void *request_data = NULL;
            memcpy(&request_data, request_ref, sizeof(request_data));
            if (!request_data) {
                return false;
            }
            uint32_t *words = NULL;
            int64_t word_count = 0;
            memcpy(&words, (const uint8_t *)request_data + PATCHGRAM_QVECTOR_PTR_OFFSET, sizeof(words));
            memcpy(&word_count, (const uint8_t *)request_data + PATCHGRAM_QVECTOR_SIZE_OFFSET, sizeof(word_count));
            if (!words || word_count <= PATCHGRAM_SERIALIZED_REQUEST_BODY_POSITION) {
                return false;
            }
            int32_t request_id = 0;
            memcpy(&request_id, (const uint8_t *)request_data + PATCHGRAM_REQUEST_DATA_REQUEST_ID_OFFSET, sizeof(request_id));
            bool has_get_collectible_info = false;
            bool has_input_phone = false;
            bool has_input_username = false;
            char phone[PATCHGRAM_MAX_FRAGMENT_PHONE_UTF8] = {0};
            char username[PATCHGRAM_MAX_USERNAME_UTF8] = {0};
            const size_t max_scan = (word_count < 512) ? (size_t)word_count : 512;
            for (size_t i = PATCHGRAM_SERIALIZED_REQUEST_BODY_POSITION; i < max_scan; i++) {
                const uint32_t word = words[i];
                if (word == PATCHGRAM_TL_FRAGMENT_GET_COLLECTIBLE_INFO) {
                    has_get_collectible_info = true;
                } else if (word == PATCHGRAM_TL_INPUT_COLLECTIBLE_PHONE) {
                    has_input_phone = true;
                    patchgram_tl_read_string_ascii(
                        (const uint8_t *)words,
                        (size_t)word_count * sizeof(uint32_t),
                        (i + 1) * sizeof(uint32_t),
                        phone,
                        sizeof(phone)
                    );
                } else if (word == PATCHGRAM_TL_INPUT_COLLECTIBLE_USERNAME) {
                    has_input_username = true;
                    patchgram_tl_read_string_ascii(
                        (const uint8_t *)words,
                        (size_t)word_count * sizeof(uint32_t),
                        (i + 1) * sizeof(uint32_t),
                        username,
                        sizeof(username)
                    );
                }
            }
            if (has_get_collectible_info || has_input_phone || has_input_username) {
                if (g_fragment_phone_request_logs < 96) {
                    g_fragment_phone_request_logs++;
                    patchgram_log(
                        "FRAGMENT getCollectibleInfo seen requestId=%d hasMethod=%d hasInputPhone=%d hasInputUsername=%d phone=%s username=%s selfPhone=%s targetMode=%s words=%lld phoneEnabled=%d usernameEnabled=%d",
                        (int)request_id,
                        has_get_collectible_info ? 1 : 0,
                        has_input_phone ? 1 : 0,
                        has_input_username ? 1 : 0,
                        phone,
                        username,
                        g_fragment_phone_self_phone_utf8,
                        patchgram_target_mode_value_name((enum PatchgramTargetMode)g_fragment_phone_target_mode),
                        (long long)word_count,
                        g_fragment_phone_enabled ? 1 : 0,
                        g_custom_list_usernames_enabled ? 1 : 0
                    );
                }
            }
            if (!has_get_collectible_info || (!has_input_phone && !has_input_username)) {
                if ((has_get_collectible_info || has_input_phone || has_input_username) && g_fragment_phone_request_skip_logs < 96) {
                    g_fragment_phone_request_skip_logs++;
                    patchgram_log(
                        "FRAGMENT request skipped reason=missing-method-or-input requestId=%d hasMethod=%d hasInputPhone=%d hasInputUsername=%d phone=%s username=%s",
                        (int)request_id,
                        has_get_collectible_info ? 1 : 0,
                        has_input_phone ? 1 : 0,
                        has_input_username ? 1 : 0,
                        phone,
                        username
                    );
                }
                return false;
            }
            if (has_input_username) {
                struct PatchgramUsernameConfigEntry *entry = patchgram_custom_username_entry(username);
                if (!g_custom_list_usernames_enabled || !entry || !entry->collectible) {
                    if (g_fragment_phone_request_skip_logs < 96) {
                        g_fragment_phone_request_skip_logs++;
                        patchgram_log(
                            "CUSTOM USERNAMES request skipped reason=username-not-configured requestId=%d username=%s configured=%d collectible=%d",
                            (int)request_id,
                            username,
                            entry ? 1 : 0,
                            (entry && entry->collectible) ? 1 : 0
                        );
                    }
                    return false;
                }
                if (username_out && username_capacity > 0) {
                    snprintf(username_out, username_capacity, "%s", username);
                }
            } else if (!g_fragment_phone_enabled) {
                return false;
            }
            if (has_input_phone && (enum PatchgramTargetMode)g_fragment_phone_target_mode == PatchgramTargetOnlySelf) {
                if (!g_fragment_phone_self_phone_utf8[0] || !phone[0]) {
                    if (g_fragment_phone_request_skip_logs < 96) {
                        g_fragment_phone_request_skip_logs++;
                        patchgram_log(
                            "FRAGMENT PHONE request skipped reason=onlySelf-missing-phone requestId=%d phone=%s selfPhone=%s",
                            (int)request_id,
                            phone,
                            g_fragment_phone_self_phone_utf8
                        );
                    }
                    return false;
                }
                if (strcmp(
                        patchgram_fragment_phone_without_plus(phone),
                        patchgram_fragment_phone_without_plus(g_fragment_phone_self_phone_utf8)
                    ) != 0) {
                    if (g_fragment_phone_request_skip_logs < 96) {
                        g_fragment_phone_request_skip_logs++;
                        patchgram_log(
                            "FRAGMENT PHONE request skipped reason=onlySelf-phone-mismatch requestId=%d phone=%s selfPhone=%s",
                            (int)request_id,
                            phone,
                            g_fragment_phone_self_phone_utf8
                        );
                    }
                    return false;
                }
            }
            if (request_id <= 0 && g_fragment_phone_request_skip_logs < 96) {
                g_fragment_phone_request_skip_logs++;
                patchgram_log(
                    "FRAGMENT PHONE request skipped reason=missing-request-id requestId=%d phone=%s selfPhone=%s",
                    (int)request_id,
                    phone,
                    g_fragment_phone_self_phone_utf8
                );
            }
            if (request_id_out) {
                *request_id_out = request_id;
            }
            return request_id > 0;
        }

        static uint32_t *patchgram_build_fragment_collectible_info_reply(
                int64_t *word_count_out,
                struct PatchgramUsernameConfigEntry *username_entry) {
            if (word_count_out) {
                *word_count_out = 0;
            }
            const int32_t purchase_date = username_entry ? username_entry->purchase_date : g_fragment_phone_purchase_date;
            const int64_t amount = username_entry ? username_entry->amount : g_fragment_phone_amount;
            const int64_t crypto_amount = username_entry ? username_entry->crypto_amount : g_fragment_phone_crypto_amount;
            const char *currency = username_entry
                ? (username_entry->currency[0] ? username_entry->currency : "USD")
                : (g_fragment_phone_currency[0] ? g_fragment_phone_currency : "TON");
            const char *crypto_currency = username_entry
                ? (username_entry->crypto_currency[0] ? username_entry->crypto_currency : "TON")
                : (g_fragment_phone_crypto_currency[0] ? g_fragment_phone_crypto_currency : "TON");
            const char *url = username_entry
                ? (username_entry->url[0] ? username_entry->url : "https://fragment.com/")
                : (g_fragment_phone_url[0] ? g_fragment_phone_url : "https://fragment.com/");
            const size_t byte_count = sizeof(uint32_t)
                + sizeof(int32_t)
                + patchgram_tl_string_length(currency)
                + sizeof(int64_t)
                + patchgram_tl_string_length(crypto_currency)
                + sizeof(int64_t)
                + patchgram_tl_string_length(url);
            const size_t padded_count = (byte_count + 3U) & ~(size_t)3U;
            uint8_t *buffer = (uint8_t *)calloc(padded_count, 1);
            if (!buffer) {
                return NULL;
            }
            size_t offset = 0;
            patchgram_tl_write_u32(buffer, &offset, PATCHGRAM_TL_FRAGMENT_COLLECTIBLE_INFO);
            patchgram_tl_write_i32(buffer, &offset, purchase_date);
            patchgram_tl_write_string(buffer, &offset, currency);
            patchgram_tl_write_i64(buffer, &offset, amount);
            patchgram_tl_write_string(buffer, &offset, crypto_currency);
            patchgram_tl_write_i64(buffer, &offset, crypto_amount);
            patchgram_tl_write_string(buffer, &offset, url);
            if (word_count_out) {
                *word_count_out = (int64_t)(padded_count / sizeof(uint32_t));
            }
            return (uint32_t *)buffer;
        }

        static bool patchgram_apply_fragment_phone_response(void *response) {
            if (!response || (!g_fragment_phone_enabled && !g_custom_list_usernames_enabled)) {
                return false;
            }
            int32_t request_id = 0;
            memcpy(&request_id, (const uint8_t *)response + PATCHGRAM_RESPONSE_REQUEST_ID_OFFSET, sizeof(request_id));
            char username[PATCHGRAM_MAX_USERNAME_UTF8] = {0};
            if (!patchgram_take_fragment_phone_request(request_id, username, sizeof(username))) {
                return false;
            }
            struct PatchgramUsernameConfigEntry *username_entry = username[0]
                ? patchgram_custom_username_entry(username)
                : NULL;
            int64_t word_count = 0;
            uint32_t *words = patchgram_build_fragment_collectible_info_reply(&word_count, username_entry);
            if (!words || word_count <= 0) {
                free(words);
                return false;
            }
            void *data_header = NULL;
            memcpy((uint8_t *)response + PATCHGRAM_QVECTOR_D_OFFSET, &data_header, sizeof(data_header));
            memcpy((uint8_t *)response + PATCHGRAM_QVECTOR_PTR_OFFSET, &words, sizeof(words));
            memcpy((uint8_t *)response + PATCHGRAM_QVECTOR_SIZE_OFFSET, &word_count, sizeof(word_count));
            if (g_fragment_phone_response_logs < 48) {
                g_fragment_phone_response_logs++;
                patchgram_log(
                    "FRAGMENT PHONE response substituted requestId=%d words=%lld date=%d amount=%lld currency=%s cryptoAmount=%lld cryptoCurrency=%s url=%s",
                    (int)request_id,
                    (long long)word_count,
                    username_entry ? (int)username_entry->purchase_date : (int)g_fragment_phone_purchase_date,
                    username_entry ? (long long)username_entry->amount : (long long)g_fragment_phone_amount,
                    username_entry ? username_entry->currency : g_fragment_phone_currency,
                    username_entry ? (long long)username_entry->crypto_amount : (long long)g_fragment_phone_crypto_amount,
                    username_entry ? username_entry->crypto_currency : g_fragment_phone_crypto_currency,
                    username_entry ? username_entry->url : g_fragment_phone_url
                );
            }
            if (username_entry && g_custom_username_response_logs < 96) {
                g_custom_username_response_logs++;
                patchgram_log(
                    "CUSTOM USERNAMES response substituted requestId=%d username=%s date=%d amount=%lld currency=%s cryptoAmount=%lld cryptoCurrency=%s url=%s",
                    (int)request_id,
                    username_entry->username,
                    (int)username_entry->purchase_date,
                    (long long)username_entry->amount,
                    username_entry->currency,
                    (long long)username_entry->crypto_amount,
                    username_entry->crypto_currency,
                    username_entry->url
                );
            }
            return true;
        }

        static uint32_t *patchgram_build_fact_check_reply(int32_t count, int64_t *word_count_out) {
            if (word_count_out) {
                *word_count_out = 0;
            }
            if (count <= 0 || !g_message_fact_check_text[0]) {
                return NULL;
            }
            const char *country = g_message_fact_check_country;
            const char *text = g_message_fact_check_text;
            const int32_t flags = (g_message_fact_check_need_check ? 1 : 0) | 2;
            const size_t one_fact_check_size = sizeof(uint32_t)
                + sizeof(int32_t)
                + patchgram_tl_string_length(country)
                + sizeof(uint32_t)
                + patchgram_tl_string_length(text)
                + sizeof(uint32_t)
                + sizeof(int32_t)
                + sizeof(int64_t);
            const size_t byte_count = sizeof(uint32_t) + sizeof(int32_t) + one_fact_check_size * (size_t)count;
            const size_t padded_count = (byte_count + 3U) & ~(size_t)3U;
            uint8_t *buffer = (uint8_t *)calloc(padded_count, 1);
            if (!buffer) {
                return NULL;
            }
            size_t offset = 0;
            patchgram_tl_write_u32(buffer, &offset, PATCHGRAM_TL_VECTOR);
            patchgram_tl_write_i32(buffer, &offset, count);
            for (int32_t i = 0; i < count; i++) {
                patchgram_tl_write_u32(buffer, &offset, PATCHGRAM_TL_FACT_CHECK);
                patchgram_tl_write_i32(buffer, &offset, flags);
                patchgram_tl_write_string(buffer, &offset, country);
                patchgram_tl_write_u32(buffer, &offset, PATCHGRAM_TL_TEXT_WITH_ENTITIES);
                patchgram_tl_write_string(buffer, &offset, text);
                patchgram_tl_write_u32(buffer, &offset, PATCHGRAM_TL_VECTOR);
                patchgram_tl_write_i32(buffer, &offset, 0);
                patchgram_tl_write_i64(buffer, &offset, g_message_fact_check_hash);
            }
            if (word_count_out) {
                *word_count_out = (int64_t)(padded_count / sizeof(uint32_t));
            }
            return (uint32_t *)buffer;
        }

        static bool patchgram_apply_fact_check_response(void *response) {
            if (!response || !g_message_settings_enabled || !g_message_fact_check_enabled) {
                return false;
            }
            int32_t request_id = 0;
            memcpy(&request_id, (const uint8_t *)response + PATCHGRAM_RESPONSE_REQUEST_ID_OFFSET, sizeof(request_id));
            const int32_t count = patchgram_take_fact_check_request(request_id);
            if (count <= 0) {
                return false;
            }
            int64_t word_count = 0;
            uint32_t *words = patchgram_build_fact_check_reply(count, &word_count);
            if (!words || word_count <= 0) {
                free(words);
                return false;
            }
            void *data_header = NULL;
            memcpy((uint8_t *)response + PATCHGRAM_QVECTOR_D_OFFSET, &data_header, sizeof(data_header));
            memcpy((uint8_t *)response + PATCHGRAM_QVECTOR_PTR_OFFSET, &words, sizeof(words));
            memcpy((uint8_t *)response + PATCHGRAM_QVECTOR_SIZE_OFFSET, &word_count, sizeof(word_count));
            if (g_message_fact_check_response_logs < 96) {
                g_message_fact_check_response_logs++;
                patchgram_log(
                    "FACT CHECK response substituted requestId=%d count=%d words=%lld text=%s country=%s hash=%lld needCheck=%d",
                    (int)request_id,
                    (int)count,
                    (long long)word_count,
                    g_message_fact_check_text,
                    g_message_fact_check_country,
                    (long long)g_message_fact_check_hash,
                    g_message_fact_check_need_check ? 1 : 0
                );
            }
            return true;
        }

        static bool patchgram_should_force_fact_check_item(void *item) {
            if (!item) {
                return false;
            }
            bool should_force = false;
            pthread_mutex_lock(&g_forced_fact_check_items_mutex);
            size_t empty_index = PATCHGRAM_MAX_FORCED_FACT_CHECK_ITEMS;
            for (size_t i = 0; i < PATCHGRAM_MAX_FORCED_FACT_CHECK_ITEMS; i++) {
                if (g_forced_fact_check_items[i].item == item) {
                    if (g_forced_fact_check_items[i].attempts < 8) {
                        g_forced_fact_check_items[i].attempts++;
                        should_force = true;
                    }
                    pthread_mutex_unlock(&g_forced_fact_check_items_mutex);
                    return should_force;
                }
                if (!g_forced_fact_check_items[i].item && empty_index == PATCHGRAM_MAX_FORCED_FACT_CHECK_ITEMS) {
                    empty_index = i;
                }
            }
            if (empty_index != PATCHGRAM_MAX_FORCED_FACT_CHECK_ITEMS) {
                g_forced_fact_check_items[empty_index].item = item;
                g_forced_fact_check_items[empty_index].attempts = 1;
            } else {
                g_forced_fact_check_items[0].item = item;
                g_forced_fact_check_items[0].attempts = 1;
            }
            should_force = true;
            pthread_mutex_unlock(&g_forced_fact_check_items_mutex);
            return should_force;
        }

        static bool patchgram_set_local_fact_check_on_item(void *item) {
            if (!item
                || !g_history_item_set_factcheck
                || !g_message_settings_enabled
                || !g_message_fact_check_enabled
                || g_message_fact_check_text_utf16_size <= 0) {
                return false;
            }
            uint8_t info[PATCHGRAM_MESSAGE_FACTCHECK_SIZE];
            memset(info, 0, sizeof(info));
            patchgram_apply_raw_qstring(
                info + PATCHGRAM_MESSAGE_FACTCHECK_TEXT_OFFSET + PATCHGRAM_QSTRING_D_OFFSET,
                g_message_fact_check_text_utf16,
                g_message_fact_check_text_utf16_size
            );
            memset(
                info + PATCHGRAM_MESSAGE_FACTCHECK_TEXT_OFFSET + PATCHGRAM_TEXT_WITH_ENTITIES_ENTITIES_OFFSET,
                0,
                PATCHGRAM_QT_ARRAY_DATA_POINTER_SIZE
            );
            patchgram_apply_raw_qstring(
                info + PATCHGRAM_MESSAGE_FACTCHECK_COUNTRY_OFFSET,
                g_message_fact_check_country_utf16,
                g_message_fact_check_country_utf16_size
            );
            uint64_t effective_hash = (uint64_t)g_message_fact_check_hash;
            if (effective_hash == 0) {
                effective_hash = 1;
            }
            memcpy(info + PATCHGRAM_MESSAGE_FACTCHECK_HASH_OFFSET, &effective_hash, sizeof(effective_hash));
            const uint8_t need_check = g_message_fact_check_need_check ? 1 : 0;
            memcpy(info + PATCHGRAM_MESSAGE_FACTCHECK_NEED_CHECK_OFFSET, &need_check, sizeof(need_check));
            g_history_item_set_factcheck(item, info);
            if (g_message_fact_check_direct_set_logs < 256) {
                g_message_fact_check_direct_set_logs++;
                patchgram_log(
                    "FACT CHECK direct set item=%p textLength=%lld countryLength=%lld hash=%llu configuredHash=%lld needCheck=%d",
                    item,
                    (long long)g_message_fact_check_text_utf16_size,
                    (long long)g_message_fact_check_country_utf16_size,
                    (unsigned long long)effective_hash,
                    (long long)g_message_fact_check_hash,
                    g_message_fact_check_need_check ? 1 : 0
                );
            }
            return true;
        }

        static bool patchgram_history_item_has_unrequested_factcheck(void *item) {
            const bool original = g_original_history_item_has_unrequested_factcheck
                ? g_original_history_item_has_unrequested_factcheck(item)
                : false;
            if (original
                || !g_message_settings_enabled
                || !g_message_fact_check_enabled
                || !g_message_fact_check_text[0]) {
                return original;
            }
            const bool forced = patchgram_should_force_fact_check_item(item);
            const bool direct_set = forced && patchgram_set_local_fact_check_on_item(item);
            if (forced && g_message_fact_check_trigger_logs < 256) {
                g_message_fact_check_trigger_logs++;
                patchgram_log(
                    "FACT CHECK trigger forced item=%p textLength=%zu directSet=%d",
                    item,
                    strlen(g_message_fact_check_text),
                    direct_set ? 1 : 0
                );
            }
            if (direct_set) {
                return false;
            }
            return forced;
        }

        static void patchgram_history_item_create_view(
            void *result,
            void *item,
            void *delegate,
            void *replacing
        ) {
            const bool direct_set = patchgram_set_local_fact_check_on_item(item);
            if (direct_set && g_message_fact_check_early_layout_logs < 256) {
                g_message_fact_check_early_layout_logs++;
                patchgram_log(
                    "FACT CHECK early createView item=%p result=%p delegate=%p replacing=%p",
                    item,
                    result,
                    delegate,
                    replacing
                );
            }
            if (g_original_history_item_create_view) {
                g_original_history_item_create_view(result, item, delegate, replacing);
            }
        }

        static void patchgram_data_factchecks_request_for(void *factchecks, void *item) {
            if (g_message_settings_enabled
                && g_message_fact_check_enabled
                && g_message_fact_check_text[0]
                && g_message_fact_check_request_for_logs < 256) {
                g_message_fact_check_request_for_logs++;
                patchgram_log(
                    "FACT CHECK requestFor called factchecks=%p item=%p textLength=%zu country=%s hash=%lld needCheck=%d",
                    factchecks,
                    item,
                    strlen(g_message_fact_check_text),
                    g_message_fact_check_country,
                    (long long)g_message_fact_check_hash,
                    g_message_fact_check_need_check ? 1 : 0
                );
            }
            if (g_original_data_factchecks_request_for) {
                g_original_data_factchecks_request_for(factchecks, item);
            }
        }

        static void patchgram_apply_fragment_phone_received_queue(void *session_private) {
            if (!session_private) {
                return;
            }
            void *session_data = NULL;
            memcpy(&session_data, (const uint8_t *)session_private + PATCHGRAM_SESSION_PRIVATE_DATA_OFFSET, sizeof(session_data));
            if (!session_data) {
                return;
            }
            uint8_t *begin = NULL;
            uint8_t *end = NULL;
            memcpy(&begin, (const uint8_t *)session_data + PATCHGRAM_SESSION_DATA_RECEIVED_BEGIN_OFFSET, sizeof(begin));
            memcpy(&end, (const uint8_t *)session_data + PATCHGRAM_SESSION_DATA_RECEIVED_END_OFFSET, sizeof(end));
            if (!begin || !end || end < begin) {
                return;
            }
            const size_t byte_count = (size_t)(end - begin);
            if (byte_count == 0 || (byte_count % PATCHGRAM_RESPONSE_SIZE) != 0 || byte_count > PATCHGRAM_RESPONSE_SIZE * 512U) {
                return;
            }
            for (uint8_t *response = begin; response < end; response += PATCHGRAM_RESPONSE_SIZE) {
                patchgram_apply_custom_username_list_response(response);
                patchgram_log_custom_username_response_tl(response);
                if (g_fragment_phone_enabled || g_custom_list_usernames_enabled) {
                    patchgram_apply_fragment_phone_response(response);
                }
                if (g_message_fact_check_enabled) {
                    patchgram_apply_fact_check_response(response);
                }
            }
        }

        static void patchgram_session_private_try_to_receive(void *session_private) {
            patchgram_apply_fragment_phone_received_queue(session_private);
            if (g_original_session_private_try_to_receive) {
                g_original_session_private_try_to_receive(session_private);
            }
        }

        static void patchgram_session_send_prepared(void *session, void *request_ref, int64_t ms_can_wait) {
            patchgram_log_custom_username_request_tl(request_ref, ms_can_wait);
            int32_t custom_username_full_user_request_id = 0;
            if (patchgram_custom_username_full_user_request_should_be_local(
                    request_ref,
                    &custom_username_full_user_request_id)) {
                patchgram_track_custom_username_full_user_request(custom_username_full_user_request_id);
                if (g_custom_username_request_logs < 96) {
                    g_custom_username_request_logs++;
                    patchgram_log(
                        "CUSTOM USERNAMES full user request tracked requestId=%d msCanWait=%lld configured=%zu first=%s",
                        (int)custom_username_full_user_request_id,
                        (long long)ms_can_wait,
                        g_custom_username_entry_count,
                        g_custom_username_entries[0].username
                    );
                }
            }
            int32_t request_id = 0;
            char collectible_username[PATCHGRAM_MAX_USERNAME_UTF8] = {0};
            if (patchgram_fragment_request_should_be_local(
                    request_ref,
                    &request_id,
                    collectible_username,
                    sizeof(collectible_username))) {
                patchgram_track_fragment_phone_request(request_id, collectible_username);
                if (g_fragment_phone_request_logs < 48) {
                    g_fragment_phone_request_logs++;
                    patchgram_log(
                        "FRAGMENT request tracked requestId=%d username=%s msCanWait=%lld selfPhone=%s targetMode=%s",
                        (int)request_id,
                        collectible_username,
                        (long long)ms_can_wait,
                        g_fragment_phone_self_phone_utf8,
                        patchgram_target_mode_value_name((enum PatchgramTargetMode)g_fragment_phone_target_mode)
                    );
                }
                if (collectible_username[0] && g_custom_username_request_logs < 96) {
                    g_custom_username_request_logs++;
                    patchgram_log(
                        "CUSTOM USERNAMES request tracked requestId=%d username=%s msCanWait=%lld",
                        (int)request_id,
                        collectible_username,
                        (long long)ms_can_wait
                    );
                }
            }
            int32_t fact_check_request_id = 0;
            int32_t fact_check_count = 0;
            if (patchgram_fact_check_request_should_be_local(request_ref, &fact_check_request_id, &fact_check_count)) {
                patchgram_track_fact_check_request(fact_check_request_id, fact_check_count);
                if (g_message_fact_check_request_logs < 96) {
                    g_message_fact_check_request_logs++;
                    patchgram_log(
                        "FACT CHECK request tracked requestId=%d count=%d msCanWait=%lld text=%s",
                        (int)fact_check_request_id,
                        (int)fact_check_count,
                        (long long)ms_can_wait,
                        g_message_fact_check_text
                    );
                }
            }
            if (g_original_session_send_prepared) {
                g_original_session_send_prepared(session, request_ref, ms_can_wait);
            }
        }

        static void patchgram_write_self_phone_field(void *peer, const char *source) {
            if (!g_self_identity_override_enabled
                || !g_custom_phone_number_enabled
                || g_configured_self_phone_utf16_size <= 0
                || !patchgram_should_patch_peer_for_mode(
                    peer,
                    true,
                    g_self_phone_target_mode,
                    "SELF PHONE"
                )) {
                return;
            }
            void *phone = (uint8_t *)peer + PATCHGRAM_USER_PHONE_OFFSET;
            const int64_t before_size = patchgram_qstring_size_at(phone);
            patchgram_apply_raw_qstring(
                phone,
                g_configured_self_phone_utf16,
                g_configured_self_phone_utf16_size
            );
            if (g_self_identity_phone_logs < 48) {
                g_self_identity_phone_logs++;
                patchgram_log(
                    "SELF IDENTITY phone wrote source=%s raw_peer=0x%llx peer_id=%llu displayUserId=%llu beforeSize=%lld afterSize=%lld known_self=%llu",
                    source ? source : "unknown",
                    (unsigned long long)patchgram_raw_peer_id_from_peer(peer),
                    (unsigned long long)patchgram_user_id_from_peer(peer),
                    (unsigned long long)g_configured_self_display_user_id,
                    (long long)before_size,
                    (long long)patchgram_qstring_size_at(phone),
                    (unsigned long long)g_self_user_id
                );
            }
        }

        static void patchgram_clear_self_phone_field(void *peer, const char *source) {
            if (!g_hide_self_phone_enabled || !patchgram_peer_is_self_user(peer)) {
                return;
            }
            void *phone = (uint8_t *)peer + PATCHGRAM_USER_PHONE_OFFSET;
            const int64_t before_size = patchgram_qstring_size_at(phone);
            patchgram_clear_qstring(phone);
            if (g_hide_self_phone_field_logs < 24) {
                g_hide_self_phone_field_logs++;
                patchgram_log(
                    "HIDE SELF PHONE field cleared source=%s raw_peer=0x%llx peer_id=%llu beforeSize=%lld afterSize=%lld known_self=%llu",
                    source ? source : "unknown",
                    (unsigned long long)patchgram_raw_peer_id_from_peer(peer),
                    (unsigned long long)patchgram_user_id_from_peer(peer),
                    (long long)before_size,
                    (long long)patchgram_qstring_size_at(phone),
                    (unsigned long long)g_self_user_id
                );
            }
        }

        static void patchgram_phone_or_hidden_value_map(void *value, void *input) {
            void *peer = patchgram_phone_or_hidden_value_user(value);
            patchgram_apply_custom_usernames(peer, "PhoneOrHiddenValue.before");
            const bool hide = g_hide_self_phone_enabled && patchgram_peer_is_self_user(peer);
            if (hide) {
                patchgram_clear_self_phone_field(peer, "PhoneOrHiddenValue.before");
            } else {
                patchgram_write_self_phone_field(peer, "PhoneOrHiddenValue.before");
            }
            if (g_original_phone_or_hidden_value_map) {
                g_original_phone_or_hidden_value_map(value, input);
            } else {
                patchgram_clear_text_with_entities(value);
            }
            if (hide) {
                patchgram_clear_text_with_entities(value);
                if (g_hide_self_phone_logs < 24) {
                    g_hide_self_phone_logs++;
                    patchgram_log(
                        "HIDE SELF PHONE row suppressed raw_peer=0x%llx peer_id=%llu known_self=%llu",
                        (unsigned long long)patchgram_raw_peer_id_from_peer(peer),
                        (unsigned long long)patchgram_user_id_from_peer(peer),
                        (unsigned long long)g_self_user_id
                    );
                }
                return;
            }
        }

        static bool patchgram_is_collectible_phone(void *peer) {
            const bool original = g_original_is_collectible_phone
                ? g_original_is_collectible_phone(peer)
                : false;
            if (!g_fragment_phone_enabled) {
                return original;
            }
            const bool should_patch = patchgram_should_patch_peer_for_mode(
                peer,
                true,
                (enum PatchgramTargetMode)g_fragment_phone_target_mode,
                "FRAGMENT PHONE"
            );
            if (!should_patch) {
                return original;
            }
            patchgram_remember_fragment_phone_self(peer);
            if (g_fragment_phone_logs < 48) {
                g_fragment_phone_logs++;
                patchgram_log(
                    "FRAGMENT PHONE collectible source=IsCollectiblePhone raw_peer=0x%llx peer_id=%llu original=%d targetMode=%s selfPhone=%s date=%d amount=%lld currency=%s cryptoAmount=%lld cryptoCurrency=%s url=%s",
                    (unsigned long long)patchgram_raw_peer_id_from_peer(peer),
                    (unsigned long long)patchgram_user_id_from_peer(peer),
                    original ? 1 : 0,
                    patchgram_target_mode_value_name((enum PatchgramTargetMode)g_fragment_phone_target_mode),
                    g_fragment_phone_self_phone_utf8,
                    (int)g_fragment_phone_purchase_date,
                    (long long)g_fragment_phone_amount,
                    g_fragment_phone_currency,
                    (long long)g_fragment_phone_crypto_amount,
                    g_fragment_phone_crypto_currency,
                    g_fragment_phone_url
                );
            }
            return true;
        }

        static const char *patchgram_target_mode_name(void) {
            switch (g_target_mode) {
            case PatchgramTargetOnlySelf:
                return "onlySelf";
            case PatchgramTargetAllExceptSelf:
                return "allExceptSelf";
            case PatchgramTargetAll:
            default:
                return "all";
            }
        }

        static const char *patchgram_target_mode_value_name(enum PatchgramTargetMode target_mode) {
            switch (target_mode) {
            case PatchgramTargetOnlySelf:
                return "onlySelf";
            case PatchgramTargetAllExceptSelf:
                return "allExceptSelf";
            case PatchgramTargetAll:
            default:
                return "all";
            }
        }

        static uint64_t patchgram_raw_peer_id_from_peer(void *peer) {
            if (!peer) {
                return 0;
            }
            return *(const uint64_t *)((const uint8_t *)peer + PATCHGRAM_PEER_ID_OFFSET);
        }

        static uint64_t patchgram_user_id_from_peer(void *peer) {
            const uint64_t peer_id = patchgram_raw_peer_id_from_peer(peer);
            return peer_id & PATCHGRAM_PEER_ID_VALUE_MASK;
        }

        static uint8_t patchgram_peer_type_from_peer(void *peer) {
            return (uint8_t)((patchgram_raw_peer_id_from_peer(peer) >> PATCHGRAM_PEER_ID_TYPE_SHIFT) & 0xffU);
        }

        static bool patchgram_peer_is_user_peer(void *peer) {
            return patchgram_peer_type_from_peer(peer) == 0;
        }

        static bool patchgram_peer_is_self_user(void *peer) {
            if (!peer || !patchgram_peer_is_user_peer(peer)) {
                return false;
            }
            const uint64_t user_id = patchgram_user_id_from_peer(peer);
            if (user_id != 0 && g_self_user_id != 0 && user_id == g_self_user_id) {
                return true;
            }
            return patchgram_user_is_self(peer);
        }

        static uint64_t patchgram_display_user_id_for_peer(void *peer) {
            if (g_self_identity_override_enabled
                && g_custom_user_id_enabled
                && g_configured_self_display_user_id != 0
                && patchgram_should_patch_peer_for_mode(
                    peer,
                    true,
                    (enum PatchgramTargetMode)g_self_user_id_target_mode,
                    "SELF USER ID"
                )) {
                return g_configured_self_display_user_id;
            }
            return patchgram_user_id_from_peer(peer);
        }

        static bool patchgram_should_patch_peer_for_mode(
            void *peer,
            bool hook_is_user,
            enum PatchgramTargetMode target_mode,
            const char *log_prefix
        ) {
            const uint8_t raw_type = patchgram_peer_type_from_peer(peer);
            const bool raw_is_user = patchgram_peer_is_user_peer(peer);
            const bool is_self = patchgram_peer_is_self_user(peer);
            if (is_self) {
                const uint64_t user_id = patchgram_user_id_from_peer(peer);
                if (user_id) {
                    g_self_user_id = user_id;
                }
            } else if (target_mode == PatchgramTargetOnlySelf && g_bot_verify_skip_nonself_logs < 12) {
                g_bot_verify_skip_nonself_logs++;
                patchgram_log(
                    "%s skip non-self raw_peer=0x%llx peer_id=%llu hook_is_user=%d raw_type=%u raw_is_user=%d known_self=%llu",
                    log_prefix,
                    (unsigned long long)patchgram_raw_peer_id_from_peer(peer),
                    (unsigned long long)patchgram_user_id_from_peer(peer),
                    hook_is_user ? 1 : 0,
                    (unsigned)raw_type,
                    raw_is_user ? 1 : 0,
                    (unsigned long long)g_self_user_id
                );
            }
            bool result = true;
            switch (target_mode) {
            case PatchgramTargetOnlySelf:
                result = is_self;
                break;
            case PatchgramTargetAllExceptSelf:
                result = !is_self;
                break;
            case PatchgramTargetAll:
            default:
                result = true;
                break;
            }
            if (g_bot_verify_should_patch_logs < 48) {
                g_bot_verify_should_patch_logs++;
                patchgram_log(
                    "%s target decision raw_peer=0x%llx peer_id=%llu hook_is_user=%d raw_type=%u raw_is_user=%d is_self=%d targetMode=%s result=%d known_self=%llu",
                    log_prefix,
                    (unsigned long long)patchgram_raw_peer_id_from_peer(peer),
                    (unsigned long long)patchgram_user_id_from_peer(peer),
                    hook_is_user ? 1 : 0,
                    (unsigned)raw_type,
                    raw_is_user ? 1 : 0,
                    is_self ? 1 : 0,
                    patchgram_target_mode_value_name(target_mode),
                    result ? 1 : 0,
                    (unsigned long long)g_self_user_id
                );
            }
            return result;
        }

        static bool patchgram_should_patch_peer(void *peer, bool is_user) {
            return patchgram_should_patch_peer_for_mode(peer, is_user, g_target_mode, "BOT VERIFY");
        }

        static void patchgram_apply_raw_qstring(uint8_t *destination, const uint16_t *text, int64_t size) {
            // Qt 6 QString is QArrayDataPointer<char16_t> (d, ptr, size);
            // d = NULL mirrors QString::fromRawData, so destructors leave our static buffer alone.
            void *data_header = NULL;
            uint16_t *data_pointer = (uint16_t *)text;
            memcpy(destination + PATCHGRAM_QSTRING_D_OFFSET, &data_header, sizeof(data_header));
            memcpy(destination + PATCHGRAM_QSTRING_PTR_OFFSET, &data_pointer, sizeof(data_pointer));
            memcpy(destination + PATCHGRAM_QSTRING_SIZE_OFFSET, &size, sizeof(size));
        }

        static void patchgram_apply_plain_text_entities(uint8_t *destination) {
            if (g_configured_description_utf16_size <= 0) {
                return;
            }
            patchgram_apply_raw_qstring(
                destination,
                g_configured_description_utf16,
                g_configured_description_utf16_size
            );
            memset(
                destination + PATCHGRAM_TEXT_WITH_ENTITIES_ENTITIES_OFFSET,
                0,
                PATCHGRAM_QT_ARRAY_DATA_POINTER_SIZE
            );
        }

        static bool patchgram_apply_bot_verification_details(void *peer, void *details, bool is_user) {
            const bool is_self = patchgram_peer_is_self_user(peer);
            const bool should_patch = patchgram_should_patch_peer(peer, is_user);
            if (!details || !g_configured_icon_id || !should_patch) {
                return false;
            }
            uint8_t *bytes = (uint8_t *)details;
            uint64_t bot_id = g_self_identity_override_enabled
                && g_custom_user_id_enabled
                && g_configured_self_display_user_id != 0
                ? g_configured_self_display_user_id
                : g_self_user_id;
            if (!bot_id && is_self) {
                bot_id = patchgram_display_user_id_for_peer(peer);
            }
            memcpy(bytes + PATCHGRAM_DETAILS_ICON_ID_OFFSET, &g_configured_icon_id, sizeof(g_configured_icon_id));
            patchgram_apply_plain_text_entities(bytes + PATCHGRAM_DETAILS_DESCRIPTION_OFFSET);
            if (bot_id) {
                memcpy(bytes + PATCHGRAM_DETAILS_BOT_ID_OFFSET, &bot_id, sizeof(bot_id));
            }
            if (g_bot_verify_apply_logs < 48) {
                g_bot_verify_apply_logs++;
                patchgram_log(
                    "BOT VERIFY applied peer=%p raw_peer=0x%llx peer_id=%llu hook_is_user=%d raw_type=%u raw_is_user=%d is_self=%d bot_id=%llu icon_id=%llu descriptionUtf16Length=%lld targetMode=%s",
                    peer,
                    (unsigned long long)patchgram_raw_peer_id_from_peer(peer),
                    (unsigned long long)patchgram_display_user_id_for_peer(peer),
                    is_user ? 1 : 0,
                    (unsigned)patchgram_peer_type_from_peer(peer),
                    patchgram_peer_is_user_peer(peer) ? 1 : 0,
                    is_self ? 1 : 0,
                    (unsigned long long)bot_id,
                    (unsigned long long)g_configured_icon_id,
                    (long long)g_configured_description_utf16_size,
                    patchgram_target_mode_name()
                );
            }
            return true;
        }

        static void *patchgram_details_or_generated(void *peer, void *details, bool is_user, uint8_t *generated) {
            const bool is_self = patchgram_peer_is_self_user(peer);
            const bool should_patch = patchgram_should_patch_peer(peer, is_user);
            patchgram_log_bot_verify_details("incoming", peer, details, is_user, is_self, should_patch);
            if (!g_bot_verification_enabled || !g_configured_icon_id || !should_patch) {
                return details;
            }
            if (details) {
                patchgram_apply_bot_verification_details(peer, details, is_user);
                patchgram_log_bot_verify_details("patched-existing", peer, details, is_user, is_self, should_patch);
                return details;
            }
            memset(generated, 0, PATCHGRAM_GENERATED_DETAILS_SIZE);
            if (patchgram_apply_bot_verification_details(peer, generated, is_user)) {
                if (g_bot_verify_generated_logs < 24) {
                    g_bot_verify_generated_logs++;
                    patchgram_log(
                        "BOT VERIFY generated details is_user=%d is_self=%d peer_id=%llu self_id=%llu targetMode=%s",
                        is_user ? 1 : 0,
                        is_self ? 1 : 0,
                        (unsigned long long)patchgram_user_id_from_peer(peer),
                        (unsigned long long)g_self_user_id,
                        patchgram_target_mode_name()
                    );
                }
                patchgram_log_bot_verify_details("generated", peer, generated, is_user, is_self, should_patch);
                return generated;
            }
            return details;
        }

        static void patchgram_user_set_bot_verify_details(void *peer, void *details) {
            if (patchgram_peer_is_user_peer(peer)) {
                patchgram_track_user_data_peer(peer, "UserData::setBotVerifyDetails");
            }
            details = patchgram_details_or_generated(peer, details, true, g_generated_user_details);
            if (g_original_user_set_bot_verify_details) {
                g_original_user_set_bot_verify_details(peer, details);
            }
            if (patchgram_peer_is_user_peer(peer)) {
                patchgram_write_self_phone_field(peer, "UserData::setBotVerifyDetails.after");
                patchgram_clear_self_phone_field(peer, "UserData::setBotVerifyDetails.after");
                patchgram_write_custom_level_rating(peer, "UserData::setBotVerifyDetails.after");
                patchgram_write_local_personal_channel(peer, "UserData::setBotVerifyDetails.after");
            }
        }

        static void patchgram_track_user_data_peer(void *peer, const char *source) {
            if (!peer) {
                return;
            }
            pthread_mutex_lock(&g_tracked_user_peers_mutex);
            for (size_t index = 0; index < g_tracked_user_peer_count; index++) {
                if (g_tracked_user_peers[index] == peer) {
                    pthread_mutex_unlock(&g_tracked_user_peers_mutex);
                    return;
                }
            }
            if (g_tracked_user_peer_count < PATCHGRAM_MAX_TRACKED_USER_PEERS) {
                g_tracked_user_peers[g_tracked_user_peer_count++] = peer;
                if (g_tracked_user_peer_count <= 32) {
                    patchgram_log(
                        "TRACK UserData peer=%p raw_peer=0x%llx peer_id=%llu raw_type=%u source=%s tracked=%zu",
                        peer,
                        (unsigned long long)patchgram_raw_peer_id_from_peer(peer),
                        (unsigned long long)patchgram_user_id_from_peer(peer),
                        (unsigned)patchgram_peer_type_from_peer(peer),
                        source ? source : "unknown",
                        g_tracked_user_peer_count
                    );
                }
            }
            pthread_mutex_unlock(&g_tracked_user_peers_mutex);
        }

        static struct PatchgramStarsRating patchgram_custom_level_rating_value(void) {
            struct PatchgramStarsRating value;
            value.level = g_custom_level_rating_level;
            value.stars = g_custom_level_rating_rating;
            value.thisLevelStars = g_custom_level_rating_current_level_rating;
            value.nextLevelStars = g_custom_level_rating_next_level_rating;
            return value;
        }

        static void patchgram_write_custom_level_rating(void *peer, const char *source) {
            if (!g_custom_level_rating_enabled || !peer) {
                return;
            }
            const bool should_patch = patchgram_should_patch_peer_for_mode(
                peer,
                true,
                g_level_rating_target_mode,
                "LEVEL RATING"
            );
            if (!should_patch) {
                return;
            }
            const struct PatchgramStarsRating value = patchgram_custom_level_rating_value();
            const uint64_t first = ((uint64_t)(uint32_t)value.level)
                | (((uint64_t)(uint32_t)value.stars) << 32);
            const uint64_t second = ((uint64_t)(uint32_t)value.thisLevelStars)
                | (((uint64_t)(uint32_t)value.nextLevelStars) << 32);
            uint8_t *rating = (uint8_t *)peer + PATCHGRAM_USER_STARS_RATING_OFFSET;
            uint64_t previous_first = 0;
            uint64_t previous_second = 0;
            memcpy(&previous_first, rating, sizeof(previous_first));
            memcpy(&previous_second, rating + sizeof(previous_first), sizeof(previous_second));
            if (previous_first == first && previous_second == second) {
                return;
            }
            memcpy(rating, &first, sizeof(first));
            memcpy(rating + sizeof(first), &second, sizeof(second));
            if (g_level_rating_logs < 96) {
                g_level_rating_logs++;
                patchgram_log(
                    "LEVEL RATING wrote source=%s raw_peer=0x%llx peer_id=%llu raw_type=%u targetMode=%s level=%d rating=%d current=%d next=%d previous=0x%llx:0x%llx",
                    source ? source : "unknown",
                    (unsigned long long)patchgram_raw_peer_id_from_peer(peer),
                    (unsigned long long)patchgram_user_id_from_peer(peer),
                    (unsigned)patchgram_peer_type_from_peer(peer),
                    patchgram_target_mode_value_name(g_level_rating_target_mode),
                    (int)value.level,
                    (int)value.stars,
                    (int)value.thisLevelStars,
                    (int)value.nextLevelStars,
                    (unsigned long long)previous_first,
                    (unsigned long long)previous_second
                );
            }
        }

        static void patchgram_write_local_personal_channel(void *peer, const char *source) {
            if (!g_local_personal_channel_enabled
                || g_local_personal_channel_id == 0
                || !patchgram_should_patch_peer_for_mode(
                    peer,
                    true,
                    g_local_personal_channel_target_mode,
                    "PERSONAL CHANNEL"
                )) {
                return;
            }
            uint8_t *channel = (uint8_t *)peer + PATCHGRAM_USER_PERSONAL_CHANNEL_ID_OFFSET;
            uint8_t *message = (uint8_t *)peer + PATCHGRAM_USER_PERSONAL_CHANNEL_MESSAGE_ID_OFFSET;
            uint64_t previous_channel = 0;
            int32_t previous_message = 0;
            memcpy(&previous_channel, channel, sizeof(previous_channel));
            memcpy(&previous_message, message, sizeof(previous_message));
            if (previous_channel == g_local_personal_channel_id
                && previous_message == g_local_personal_channel_message_id) {
                return;
            }
            memcpy(channel, &g_local_personal_channel_id, sizeof(g_local_personal_channel_id));
            memcpy(message, &g_local_personal_channel_message_id, sizeof(g_local_personal_channel_message_id));
            if (g_local_personal_channel_logs < 48) {
                g_local_personal_channel_logs++;
                patchgram_log(
                    "PERSONAL CHANNEL wrote source=%s raw_peer=0x%llx peer_id=%llu channel=%llu message=%d previous=%llu:%d known_self=%llu",
                    source ? source : "unknown",
                    (unsigned long long)patchgram_raw_peer_id_from_peer(peer),
                    (unsigned long long)patchgram_user_id_from_peer(peer),
                    (unsigned long long)g_local_personal_channel_id,
                    (int)g_local_personal_channel_message_id,
                    (unsigned long long)previous_channel,
                    (int)previous_message,
                    (unsigned long long)g_self_user_id
                );
            }
        }

        static void patchgram_write_username_vector(
                void *peer,
                struct PatchgramUsernameConfigEntry *entries,
                size_t count,
                int32_t editable_index,
                const char *source) {
            if (!peer) {
                return;
            }
            if (count > 0 && editable_index < 0) {
                editable_index = 0;
            }
            uint8_t *info = (uint8_t *)peer + PATCHGRAM_USER_USERNAME_INFO_OFFSET;
            if (count == 0) {
                void *empty = NULL;
                editable_index = -1;
                memcpy(info + PATCHGRAM_USERNAME_INFO_VECTOR_OFFSET, &empty, sizeof(empty));
                memcpy(info + PATCHGRAM_USERNAME_INFO_VECTOR_OFFSET + sizeof(empty), &empty, sizeof(empty));
                memcpy(info + PATCHGRAM_USERNAME_INFO_VECTOR_OFFSET + sizeof(empty) * 2, &empty, sizeof(empty));
                memcpy(info + PATCHGRAM_USERNAME_INFO_EDITABLE_INDEX_OFFSET, &editable_index, sizeof(editable_index));
                return;
            }
            uint8_t *current_begin = NULL;
            uint8_t *current_end = NULL;
            int32_t current_editable_index = -2;
            memcpy(&current_begin, info + PATCHGRAM_USERNAME_INFO_VECTOR_OFFSET, sizeof(current_begin));
            memcpy(&current_end, info + PATCHGRAM_USERNAME_INFO_VECTOR_OFFSET + sizeof(current_begin), sizeof(current_end));
            memcpy(
                &current_editable_index,
                info + PATCHGRAM_USERNAME_INFO_EDITABLE_INDEX_OFFSET,
                sizeof(current_editable_index)
            );
            const size_t current_count = (current_begin && current_end && current_end >= current_begin)
                ? (size_t)(current_end - current_begin) / PATCHGRAM_QT_ARRAY_DATA_POINTER_SIZE
                : 0;
            if (current_count == count && current_editable_index == editable_index) {
                bool already_matches = true;
                if (!current_begin) {
                    already_matches = false;
                }
                for (size_t i = 0; already_matches && i < count; i++) {
                    char current_username[PATCHGRAM_MAX_USERNAME_UTF8] = {0};
                    patchgram_copy_qstring_ascii(
                        current_begin + i * PATCHGRAM_QT_ARRAY_DATA_POINTER_SIZE,
                        current_username,
                        sizeof(current_username)
                    );
                    if (!patchgram_username_equal(current_username, entries[i].username)) {
                        already_matches = false;
                    }
                }
                if (already_matches) {
                    return;
                }
            }
            const size_t byte_count = count * PATCHGRAM_QT_ARRAY_DATA_POINTER_SIZE;
            uint8_t *items = (uint8_t *)patchgram_cxx_operator_new(byte_count);
            if (!items) {
                return;
            }
            memset(items, 0, byte_count);
            for (size_t i = 0; i < count; i++) {
                patchgram_apply_raw_qstring(
                    items + i * PATCHGRAM_QT_ARRAY_DATA_POINTER_SIZE,
                    entries[i].username_utf16,
                    entries[i].username_utf16_size
                );
            }
            g_custom_username_vector_items = items;
            g_custom_username_vector_count = count;
            g_custom_username_vector_editable_index = editable_index;
            void *begin = items;
            void *end = items + count * PATCHGRAM_QT_ARRAY_DATA_POINTER_SIZE;
            void *cap = end;
            memcpy(info + PATCHGRAM_USERNAME_INFO_VECTOR_OFFSET, &begin, sizeof(begin));
            memcpy(info + PATCHGRAM_USERNAME_INFO_VECTOR_OFFSET + sizeof(begin), &end, sizeof(end));
            memcpy(info + PATCHGRAM_USERNAME_INFO_VECTOR_OFFSET + sizeof(begin) * 2, &cap, sizeof(cap));
            memcpy(info + PATCHGRAM_USERNAME_INFO_EDITABLE_INDEX_OFFSET, &editable_index, sizeof(editable_index));
            if (g_custom_usernames_logs < 96) {
                g_custom_usernames_logs++;
                patchgram_log(
                    "CUSTOM USERNAMES wrote source=%s raw_peer=0x%llx peer_id=%llu count=%zu editableIndex=%d first=%s known_self=%llu",
                    source ? source : "unknown",
                    (unsigned long long)patchgram_raw_peer_id_from_peer(peer),
                    (unsigned long long)patchgram_user_id_from_peer(peer),
                    count,
                    (int)editable_index,
                    entries[0].username,
                    (unsigned long long)g_self_user_id
                );
            }
        }

        static void patchgram_capture_original_usernames(void *peer, const char *source) {
            if (!peer || g_original_usernames_captured) {
                return;
            }
            uint8_t *info = (uint8_t *)peer + PATCHGRAM_USER_USERNAME_INFO_OFFSET;
            uint8_t *begin = NULL;
            uint8_t *end = NULL;
            memcpy(&begin, info + PATCHGRAM_USERNAME_INFO_VECTOR_OFFSET, sizeof(begin));
            memcpy(&end, info + PATCHGRAM_USERNAME_INFO_VECTOR_OFFSET + sizeof(begin), sizeof(end));
            memcpy(&g_original_username_editable_index, info + PATCHGRAM_USERNAME_INFO_EDITABLE_INDEX_OFFSET, sizeof(g_original_username_editable_index));
            g_original_username_entry_count = 0;
            if (begin && end && end >= begin) {
                size_t count = (size_t)(end - begin) / PATCHGRAM_QT_ARRAY_DATA_POINTER_SIZE;
                if (count > PATCHGRAM_MAX_CUSTOM_USERNAMES) {
                    count = PATCHGRAM_MAX_CUSTOM_USERNAMES;
                }
                for (size_t i = 0; i < count; i++) {
                    char username[PATCHGRAM_MAX_USERNAME_UTF8] = {0};
                    patchgram_copy_qstring_ascii(
                        begin + i * PATCHGRAM_QT_ARRAY_DATA_POINTER_SIZE,
                        username,
                        sizeof(username)
                    );
                    if (!username[0]) {
                        continue;
                    }
                    struct PatchgramUsernameConfigEntry *entry = &g_original_username_entries[g_original_username_entry_count++];
                    snprintf(entry->username, sizeof(entry->username), "%s", username);
                    patchgram_configure_custom_username_entry_utf16(entry);
                }
            }
            if (g_original_username_entry_count == 0) {
                g_original_username_editable_index = -1;
            }
            g_original_usernames_captured = true;
            if (g_custom_usernames_logs < 96) {
                g_custom_usernames_logs++;
                patchgram_log(
                    "CUSTOM USERNAMES captured original source=%s raw_peer=0x%llx peer_id=%llu count=%zu editableIndex=%d",
                    source ? source : "unknown",
                    (unsigned long long)patchgram_raw_peer_id_from_peer(peer),
                    (unsigned long long)patchgram_user_id_from_peer(peer),
                    g_original_username_entry_count,
                    (int)g_original_username_editable_index
                );
            }
        }

        static void patchgram_apply_custom_usernames(void *peer, const char *source) {
            if (!peer || !patchgram_peer_is_self_user(peer)) {
                return;
            }
            if (!g_custom_list_usernames_enabled || g_custom_username_entry_count == 0) {
                return;
            }
            if (!patchgram_resolve_cxx_operator_new()) {
                if (g_custom_usernames_logs < 96) {
                    g_custom_usernames_logs++;
                    patchgram_log(
                        "CUSTOM USERNAMES model sync skipped reason=missing-allocator source=%s raw_peer=0x%llx peer_id=%llu count=%zu known_self=%llu first=%s",
                        source ? source : "unknown",
                        (unsigned long long)patchgram_raw_peer_id_from_peer(peer),
                        (unsigned long long)patchgram_user_id_from_peer(peer),
                        g_custom_username_entry_count,
                        (unsigned long long)g_self_user_id,
                        g_custom_username_entries[0].username
                    );
                }
                return;
            }
            patchgram_capture_original_usernames(peer, source ? source : "custom-usernames");
            patchgram_write_username_vector(
                peer,
                g_custom_username_entries,
                g_custom_username_entry_count,
                0,
                source ? source : "custom-usernames"
            );
            if (g_custom_usernames_logs < 96) {
                g_custom_usernames_logs++;
                patchgram_log(
                    "CUSTOM USERNAMES model sync applied source=%s raw_peer=0x%llx peer_id=%llu count=%zu known_self=%llu first=%s",
                    source ? source : "unknown",
                    (unsigned long long)patchgram_raw_peer_id_from_peer(peer),
                    (unsigned long long)patchgram_user_id_from_peer(peer),
                    g_custom_username_entry_count,
                    (unsigned long long)g_self_user_id,
                    g_custom_username_entries[0].username
                );
            }
        }

        static void patchgram_apply_tracked_user_runtime_values(const char *source) {
            void *peers[PATCHGRAM_MAX_TRACKED_USER_PEERS];
            pthread_mutex_lock(&g_tracked_user_peers_mutex);
            const size_t count = g_tracked_user_peer_count;
            if (count > 0) {
                memcpy(peers, g_tracked_user_peers, count * sizeof(void *));
            }
            pthread_mutex_unlock(&g_tracked_user_peers_mutex);
            for (size_t index = 0; index < count; index++) {
                patchgram_write_self_phone_field(peers[index], source ? source : "tracked");
                patchgram_clear_self_phone_field(peers[index], source ? source : "tracked");
                patchgram_write_custom_level_rating(peers[index], source ? source : "tracked");
                patchgram_write_local_personal_channel(peers[index], source ? source : "tracked");
                patchgram_apply_custom_usernames(peers[index], source ? source : "tracked");
            }
        }

        static void patchgram_channel_set_bot_verify_details(void *peer, void *details) {
            details = patchgram_details_or_generated(peer, details, false, g_generated_channel_details);
            if (g_original_channel_set_bot_verify_details) {
                g_original_channel_set_bot_verify_details(peer, details);
            }
        }

        static void patchgram_apply_scheduled_send_request(
            void *request,
            uint32_t flags_offset,
            uint32_t schedule_date_offset,
            const char *method
        ) {
            if (!g_scheduled_send_enabled || !request) {
                return;
            }
            uint32_t *flags = (uint32_t *)((uint8_t *)request + flags_offset);
            int32_t *scheduled = (int32_t *)((uint8_t *)request + schedule_date_offset);
            const uint32_t previous_flags = *flags;
            const int32_t previous_scheduled = *scheduled;
            const int32_t value = (int32_t)(time(NULL) + PATCHGRAM_SCHEDULED_SEND_DELAY_SECONDS);
            *flags |= PATCHGRAM_MESSAGES_FLAG_SCHEDULE_DATE;
            *scheduled = value;
            if (g_scheduled_send_logs < 96) {
                g_scheduled_send_logs++;
                patchgram_log(
                    "SCHEDULED SEND %s request wrote flags=0x%x->0x%x schedule_date=%d->%d delay=%d request=0x%llx",
                    method ? method : "unknown",
                    (unsigned)previous_flags,
                    (unsigned)*flags,
                    (int)previous_scheduled,
                    (int)value,
                    PATCHGRAM_SCHEDULED_SEND_DELAY_SECONDS,
                    (unsigned long long)(uintptr_t)request
                );
            }
        }

        static void patchgram_messages_send_message_serialize(
            void *request,
            void *stream,
            uint64_t argument2,
            uint64_t argument3
        ) {
            patchgram_apply_scheduled_send_request(
                request,
                PATCHGRAM_MESSAGES_SEND_MESSAGE_FLAGS_OFFSET,
                PATCHGRAM_MESSAGES_SEND_MESSAGE_SCHEDULE_DATE_OFFSET,
                "sendMessage"
            );
            if (g_original_messages_send_message_serialize) {
                g_original_messages_send_message_serialize(
                    request,
                    stream,
                    argument2,
                    argument3
                );
            }
        }

        static void patchgram_messages_send_media_serialize(
            void *request,
            void *stream,
            uint64_t argument2,
            uint64_t argument3
        ) {
            patchgram_apply_scheduled_send_request(
                request,
                PATCHGRAM_MESSAGES_SEND_MEDIA_FLAGS_OFFSET,
                PATCHGRAM_MESSAGES_SEND_MEDIA_SCHEDULE_DATE_OFFSET,
                "sendMedia"
            );
            if (g_original_messages_send_media_serialize) {
                g_original_messages_send_media_serialize(
                    request,
                    stream,
                    argument2,
                    argument3
                );
            }
        }

        static void patchgram_install_bot_verification_hooks(void) {
            static const uint8_t user_flags_expected[] = {
                0xff, 0x43, 0x02, 0xd1, 0xfa, 0x67, 0x04, 0xa9,
                0xf8, 0x5f, 0x05, 0xa9, 0xf6, 0x57, 0x06, 0xa9,
                0xf4, 0x4f, 0x07, 0xa9, 0xfd, 0x7b, 0x08, 0xa9,
                0xfd, 0x03, 0x02, 0x91, 0xf3, 0x03, 0x00, 0xaa
            };
            static const uint8_t user_expected[] = {
                0xff, 0x43, 0x01, 0xd1, 0xf6, 0x57, 0x02, 0xa9,
                0xf4, 0x4f, 0x03, 0xa9, 0xfd, 0x7b, 0x04, 0xa9,
                0xfd, 0x03, 0x01, 0x91, 0xf3, 0x03, 0x00, 0xaa,
                0x28, 0x04, 0x40, 0xf9, 0x15, 0xd0, 0x41, 0xf9
            };
            static const uint8_t channel_expected[] = {
                0xff, 0x43, 0x01, 0xd1, 0xf6, 0x57, 0x02, 0xa9,
                0xf4, 0x4f, 0x03, 0xa9, 0xfd, 0x7b, 0x04, 0xa9,
                0xfd, 0x03, 0x01, 0x91, 0xf3, 0x03, 0x00, 0xaa,
                0x28, 0x04, 0x40, 0xf9, 0x15, 0x5c, 0x41, 0xf9
            };
            static const uint8_t phone_or_hidden_value_expected[] = {
                0xff, 0xc3, 0x03, 0xd1, 0xf4, 0x4f, 0x0d, 0xa9,
                0xfd, 0x7b, 0x0e, 0xa9, 0xfd, 0x83, 0x03, 0x91
            };
            static const uint8_t is_collectible_phone_expected[] = {
                0xff, 0x83, 0x02, 0xd1, 0xf6, 0x57, 0x07, 0xa9,
                0xf4, 0x4f, 0x08, 0xa9, 0xfd, 0x7b, 0x09, 0xa9
            };
            static const uint8_t history_item_create_view_expected[] = {
                0xe9, 0x23, 0xb9, 0x6d, 0xfc, 0x6f, 0x01, 0xa9,
                0xfa, 0x67, 0x02, 0xa9, 0xf8, 0x5f, 0x03, 0xa9
            };
            static const uint8_t history_item_has_unrequested_factcheck_expected[] = {
                0xfd, 0x7b, 0xbf, 0xa9, 0xfd, 0x03, 0x00, 0x91,
                0x08, 0x14, 0x40, 0xf9, 0x08, 0x05, 0x63, 0x92,
                0x09, 0x00, 0xa4, 0x52, 0x1f, 0x01, 0x09, 0xeb
            };
            static const uint8_t data_factchecks_request_for_expected[] = {
                0xff, 0xc3, 0x01, 0xd1, 0xf8, 0x5f, 0x03, 0xa9,
                0xf6, 0x57, 0x04, 0xa9, 0xf4, 0x4f, 0x05, 0xa9,
                0xfd, 0x7b, 0x06, 0xa9, 0xfd, 0x83, 0x01, 0x91
            };
            static const uint8_t session_private_try_to_receive_expected[] = {
                0xfc, 0x6f, 0xba, 0xa9, 0xfa, 0x67, 0x01, 0xa9,
                0xf8, 0x5f, 0x02, 0xa9, 0xf6, 0x57, 0x03, 0xa9
            };
            static const uint8_t session_send_prepared_expected[] = {
                0xff, 0x83, 0x02, 0xd1, 0xf8, 0x5f, 0x06, 0xa9,
                0xf6, 0x57, 0x07, 0xa9, 0xf4, 0x4f, 0x08, 0xa9
            };
            static const uint8_t messages_send_message_serialize_expected[] = {
                0xfc, 0x6f, 0xba, 0xa9, 0xfa, 0x67, 0x01, 0xa9,
                0xf8, 0x5f, 0x02, 0xa9, 0xf6, 0x57, 0x03, 0xa9
            };
            static const uint8_t messages_send_media_serialize_expected[] = {
                0xff, 0xc3, 0x03, 0xd1, 0xfa, 0x67, 0x0a, 0xa9,
                0xf8, 0x5f, 0x0b, 0xa9, 0xf6, 0x57, 0x0c, 0xa9
            };
            static const uint8_t format_count_decimal_expected[] = {
                0x09, 0x00, 0x40, 0xf9, 0x2a, 0x19, 0x40, 0xb9,
                0x0b, 0x04, 0x80, 0x52, 0x65, 0x15, 0x2a, 0x0a
            };

            g_profile_peer_id_text_return = (uintptr_t)patchgram_resolve_vmaddr(
                PATCHGRAM_PROFILE_PEER_ID_TEXT_RETURN_VMADDR
            );
            g_history_item_set_factcheck = (PatchgramHistoryItemSetFactcheckFn)patchgram_resolve_vmaddr(
                PATCHGRAM_HISTORY_ITEM_SET_FACTCHECK_VMADDR
            );

            const bool user_flags_hook = patchgram_install_inline_hook(
                patchgram_resolve_vmaddr(PATCHGRAM_USER_SET_FLAGS_VMADDR),
                patchgram_user_set_flags,
                user_flags_expected,
                sizeof(user_flags_expected),
                (void **)&g_original_user_set_flags,
                "UserData::setFlags"
            );
            const bool user_hook = patchgram_install_inline_hook(
                patchgram_resolve_vmaddr(PATCHGRAM_USER_SET_BOT_VERIFY_DETAILS_VMADDR),
                patchgram_user_set_bot_verify_details,
                user_expected,
                sizeof(user_expected),
                (void **)&g_original_user_set_bot_verify_details,
                "UserData::setBotVerifyDetails"
            );
            const bool channel_hook = patchgram_install_inline_hook(
                patchgram_resolve_vmaddr(PATCHGRAM_CHANNEL_SET_BOT_VERIFY_DETAILS_VMADDR),
                patchgram_channel_set_bot_verify_details,
                channel_expected,
                sizeof(channel_expected),
                (void **)&g_original_channel_set_bot_verify_details,
                "ChannelData::setBotVerifyDetails"
            );
            const bool phone_hook = patchgram_install_inline_hook(
                patchgram_resolve_vmaddr(PATCHGRAM_PHONE_OR_HIDDEN_VALUE_MAP_VMADDR),
                patchgram_phone_or_hidden_value_map,
                phone_or_hidden_value_expected,
                sizeof(phone_or_hidden_value_expected),
                (void **)&g_original_phone_or_hidden_value_map,
                "Info::Profile::PhoneOrHiddenValue"
            );
            const bool is_collectible_phone_hook = patchgram_install_inline_hook(
                patchgram_resolve_vmaddr(PATCHGRAM_IS_COLLECTIBLE_PHONE_VMADDR),
                patchgram_is_collectible_phone,
                is_collectible_phone_expected,
                sizeof(is_collectible_phone_expected),
                (void **)&g_original_is_collectible_phone,
                "Info::Profile::IsCollectiblePhone"
            );
            bool history_item_create_view_hook = false;
            if (PATCHGRAM_HISTORY_ITEM_CREATE_VIEW_VMADDR != 0) {
                history_item_create_view_hook = patchgram_install_inline_hook(
                    patchgram_resolve_vmaddr(PATCHGRAM_HISTORY_ITEM_CREATE_VIEW_VMADDR),
                    patchgram_history_item_create_view,
                    history_item_create_view_expected,
                    sizeof(history_item_create_view_expected),
                    (void **)&g_original_history_item_create_view,
                    "HistoryItem::createView"
                );
            } else {
                patchgram_log("SKIP HistoryItem::createView hook: vmaddr not configured");
            }
            bool history_item_fact_check_hook = false;
            if (PATCHGRAM_HISTORY_ITEM_HAS_UNREQUESTED_FACTCHECK_VMADDR != 0) {
                history_item_fact_check_hook = patchgram_install_inline_hook(
                    patchgram_resolve_vmaddr(PATCHGRAM_HISTORY_ITEM_HAS_UNREQUESTED_FACTCHECK_VMADDR),
                    patchgram_history_item_has_unrequested_factcheck,
                    history_item_has_unrequested_factcheck_expected,
                    sizeof(history_item_has_unrequested_factcheck_expected),
                    (void **)&g_original_history_item_has_unrequested_factcheck,
                    "HistoryItem::hasUnrequestedFactcheck"
                );
            } else {
                patchgram_log("SKIP HistoryItem::hasUnrequestedFactcheck hook: vmaddr not configured");
            }
            bool data_factchecks_request_for_hook = false;
            if (PATCHGRAM_DATA_FACTCHECKS_REQUEST_FOR_VMADDR != 0) {
                data_factchecks_request_for_hook = patchgram_install_inline_hook(
                    patchgram_resolve_vmaddr(PATCHGRAM_DATA_FACTCHECKS_REQUEST_FOR_VMADDR),
                    patchgram_data_factchecks_request_for,
                    data_factchecks_request_for_expected,
                    sizeof(data_factchecks_request_for_expected),
                    (void **)&g_original_data_factchecks_request_for,
                    "Data::Factchecks::requestFor"
                );
            } else {
                patchgram_log("SKIP Data::Factchecks::requestFor hook: vmaddr not configured");
            }
            const bool session_try_to_receive_hook = patchgram_install_inline_hook(
                patchgram_resolve_vmaddr(PATCHGRAM_SESSION_PRIVATE_TRY_TO_RECEIVE_VMADDR),
                patchgram_session_private_try_to_receive,
                session_private_try_to_receive_expected,
                sizeof(session_private_try_to_receive_expected),
                (void **)&g_original_session_private_try_to_receive,
                "MTP::details::SessionPrivate::tryToReceive"
            );
            const bool session_send_prepared_hook = patchgram_install_inline_hook(
                patchgram_resolve_vmaddr(PATCHGRAM_SESSION_SEND_PREPARED_VMADDR),
                patchgram_session_send_prepared,
                session_send_prepared_expected,
                sizeof(session_send_prepared_expected),
                (void **)&g_original_session_send_prepared,
                "MTP::details::Session::sendPrepared"
            );
            g_scheduled_send_message_hook_installed = patchgram_install_inline_hook(
                patchgram_resolve_vmaddr(PATCHGRAM_MESSAGES_SEND_MESSAGE_SERIALIZE_VMADDR),
                patchgram_messages_send_message_serialize,
                messages_send_message_serialize_expected,
                sizeof(messages_send_message_serialize_expected),
                (void **)&g_original_messages_send_message_serialize,
                "MTPmessages_SendMessage::serialize"
            );
            g_scheduled_send_media_hook_installed = patchgram_install_inline_hook(
                patchgram_resolve_vmaddr(PATCHGRAM_MESSAGES_SEND_MEDIA_SERIALIZE_VMADDR),
                patchgram_messages_send_media_serialize,
                messages_send_media_serialize_expected,
                sizeof(messages_send_media_serialize_expected),
                (void **)&g_original_messages_send_media_serialize,
                "MTPmessages_SendMedia::serialize"
            );
            const bool profile_id_text_hook = patchgram_install_inline_hook(
                patchgram_resolve_vmaddr(PATCHGRAM_FORMAT_COUNT_DECIMAL_VMADDR),
                patchgram_format_count_decimal,
                format_count_decimal_expected,
                sizeof(format_count_decimal_expected),
                &g_original_format_count_decimal,
                "Lang::FormatCountDecimal"
            );
            patchgram_log(
                "READY hooks userFlags=%d starsRating=direct user=%d channel=%d phone=%d isCollectiblePhone=%d factCheckCreateView=%d factCheckTrigger=%d factCheckRequestFor=%d sessionTryReceive=%d sessionSendPrepared=%d scheduledSendMessage=%d scheduledSendMedia=%d profileIdText=%d",
                user_flags_hook ? 1 : 0,
                user_hook ? 1 : 0,
                channel_hook ? 1 : 0,
                phone_hook ? 1 : 0,
                is_collectible_phone_hook ? 1 : 0,
                history_item_create_view_hook ? 1 : 0,
                history_item_fact_check_hook ? 1 : 0,
                data_factchecks_request_for_hook ? 1 : 0,
                session_try_to_receive_hook ? 1 : 0,
                session_send_prepared_hook ? 1 : 0,
                g_scheduled_send_message_hook_installed ? 1 : 0,
                g_scheduled_send_media_hook_installed ? 1 : 0,
                profile_id_text_hook ? 1 : 0
            );
        }

        __attribute__((constructor))
        static void patchgram_bot_verification_init(void) {
            const char *config_path = getenv("PATCHGRAM_RUNTIME_CONFIG");
            if (!config_path || !config_path[0]) {
                config_path = getenv("PATCHGRAM_BOT_VERIFICATION_CONFIG");
            }
            patchgram_set_log_path(config_path);
            patchgram_log("BEGIN Patchgram runtime hook");
            (void)g_patchgram_runtime_build_marker;

            if (!config_path || !config_path[0]) {
                patchgram_log("ERROR Missing PATCHGRAM_RUNTIME_CONFIG");
                return;
            }
            snprintf(g_config_path, sizeof(g_config_path), "%s", config_path);
            if (!patchgram_has_telegram_executable_image()) {
                patchgram_log("SKIP Patchgram runtime hook for non-Telegram image=%s", patchgram_main_image_name());
                return;
            }
            if (!patchgram_load_runtime_config(g_config_path, true, "initial")) {
                return;
            }
            if (g_bot_verification_enabled && !g_configured_icon_id) {
                patchgram_log("ERROR Missing customEmojiId");
            }
            patchgram_install_bot_verification_hooks();
            patchgram_start_runtime_reload_thread();
        }
        """#
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
