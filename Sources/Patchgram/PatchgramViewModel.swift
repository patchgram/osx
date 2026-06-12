import AppKit
import Foundation
import PatchgramCore
import SwiftUI
import UniformTypeIdentifiers

struct BinaryRuleRowState: Identifiable, Hashable {
    private static let dylibRuleIds: Set<String> = [
        "binary.account.custom_settings",
        "binary.visual.bot_verification",
        "binary.visual.custom_level_rating",
        "binary.visual.hide_self_phone",
        "binary.visual.self_identity_override",
        "binary.visual.local_personal_channel",
        "binary.visual.fragment_phone",
        "binary.visual.custom_list_usernames",
        "binary.visual.peer_badge",
        "binary.visual.no_premium_anim",
        "binary.visual.disable_spoilers",
        "binary.presence.force_offline",
        "binary.privacy.no_phone_on_add",
        "binary.links.open_without_warning",
        "binary.inline.callback_hover",
        "binary.display.custom_ton",
        "binary.display.custom_stars",
        "binary.config.disable_monetization",
        "binary.activity.block_typing",
        "binary.read_receipts.block_history_read",
        "binary.messages.settings",
        "binary.premium.local",
        "binary.visual.sensitive_blur",
        "binary.stories.hide",
        "binary.ads.disable_sponsored",
        "binary.overlay.profile_rain"
    ]

    var id: String { status.id }
    var status: BinaryRuleStatus
    var desiredEnabled: Bool
    var parameterValue: UInt64?
    var botVerificationConfig: BotVerificationPatchConfig?
    var customLevelRatingConfig: CustomLevelRatingPatchConfig?
    var selfIdentityConfig: SelfIdentityPatchConfig?
    var localPersonalChannelConfig: LocalPersonalChannelPatchConfig?
    var fragmentPhoneConfig: FragmentPhonePatchConfig?
    var customListUsernamesConfig: CustomListUsernamesPatchConfig?
    var messageFactCheckConfig: MessageFactCheckPatchConfig?
    var subpatches: [BinarySubpatchRowState] = []

    var patchDeliveryLabel: String {
        Self.dylibRuleIds.contains(id) ? "dylib" : "binary"
    }

    var usesDylibPatch: Bool {
        Self.dylibRuleIds.contains(id)
    }

    var configurationDisplayValue: String? {
        if status.rule.kind == .botVerification {
            return botVerificationConfig?.displayValue
        }
        if status.rule.kind == .customLevelRating {
            return customLevelRatingConfig?.displayValue
        }
        if status.rule.kind == .selfIdentityOverride {
            return selfIdentityConfig?.displayValue
        }
        if status.rule.kind == .localPersonalChannel {
            return localPersonalChannelConfig?.displayValue
        }
        if status.rule.kind == .fragmentPhone {
            return fragmentPhoneConfig?.displayValue
        }
        if status.rule.kind == .customListUsernames {
            return customListUsernamesConfig?.displayValue
        }
        guard let parameter = status.rule.parameter, let parameterValue else { return nil }
        return parameter.displayValue(parameterValue)
    }

    var canUpdateAppliedPatch: Bool {
        (desiredEnabled && status.state == .partial)
            // Applied rule whose definition changed under it (e.g. a fetched patch update) — offer
            // to re-apply the new definition cleanly.
            || (status.state == .applied && status.definitionChanged)
            || (status.state == .applied && (status.rule.parameter != nil
                || status.rule.kind == .botVerification
                || status.rule.kind == .customLevelRating
                || status.rule.kind == .selfIdentityOverride
                || status.rule.kind == .localPersonalChannel
                || status.rule.kind == .fragmentPhone
                || status.rule.kind == .customListUsernames))
    }

    var updateButtonTitle: String? {
        guard canUpdateAppliedPatch else { return nil }
        return (status.rule.parameter == nil
            && status.rule.kind != .botVerification
            && status.rule.kind != .customLevelRating
            && status.rule.kind != .selfIdentityOverride
            && status.rule.kind != .localPersonalChannel
            && status.rule.kind != .customListUsernames) ? "Update" : "Change"
    }

    var needsApply: Bool {
        if subpatches.contains(where: { $0.desiredEnabled != $0.appliedEnabled || $0.parametersChanged }) {
            return true
        }
        return desiredEnabled != status.state.isEnabled || (desiredEnabled && status.state == .partial)
    }

    var subpatchSummary: String? {
        guard !subpatches.isEmpty else { return nil }
        let selected = subpatches.filter(\.desiredEnabled).count
        let total = subpatches.count
        let turningOn = subpatches.filter { $0.desiredEnabled && !$0.appliedEnabled }.count
        let turningOff = subpatches.filter { !$0.desiredEnabled && $0.appliedEnabled }.count
        let changingParameters = subpatches.filter(\.parametersChanged).count
        var parts = ["\(selected)/\(total) subpatches"]
        if turningOn > 0 {
            parts.append("+\(turningOn)")
        }
        if turningOff > 0 {
            parts.append("-\(turningOff)")
        }
        if changingParameters > 0 {
            parts.append("~\(changingParameters)")
        }
        return parts.joined(separator: " ")
    }
}

struct BinarySubpatchRowState: Identifiable, Hashable {
    let id: String
    let title: String
    let showsSettingsButton: Bool
    let showsChangeButton: Bool
    var desiredEnabled: Bool
    var appliedEnabled: Bool
    var parametersChanged: Bool
}

private struct BinaryCompositeSubpatchDefinition: Identifiable, Hashable {
    let id: String
    let title: String
    let internalRuleId: String?
    let alternativeGroup: String?
    let showsSettingsButton: Bool
    let showsChangeButton: Bool

    init(
        id: String,
        title: String,
        internalRuleId: String? = nil,
        alternativeGroup: String? = nil,
        showsSettingsButton: Bool = false,
        showsChangeButton: Bool = false
    ) {
        self.id = id
        self.title = title
        self.internalRuleId = internalRuleId
        self.alternativeGroup = alternativeGroup
        self.showsSettingsButton = showsSettingsButton
        self.showsChangeButton = showsChangeButton
    }
}

struct BotVerificationUserPreset: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var customEmojiId: UInt64
    var description: String

    var normalizedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedDescription: String {
        description.trimmingCharacters(in: .whitespacesAndNewlines)
    }

}

extension BotVerificationUserPreset {
    func matchesConfig(_ config: BotVerificationPatchConfig) -> Bool {
        customEmojiId == config.customEmojiId
            && normalizedDescription == config.description.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension BotVerificationPatchConfig {
    func matchesPreset(_ preset: BotVerificationUserPreset) -> Bool {
        customEmojiId == preset.customEmojiId
            && description.trimmingCharacters(in: .whitespacesAndNewlines) == preset.normalizedDescription
    }
}

private struct BotVerificationPresetOption: Hashable {
    let title: String
    let customEmojiId: UInt64
    let description: String
    let isScaredCat: Bool

    var configPreset: BotVerificationPreset {
        isScaredCat ? .scaredCat : .custom
    }
}

enum WriteAccessRetryAction: Equatable {
    case updateAppliedPatch(ruleId: String)
    case applyBinaryChanges
    case disableAllBinary
    case restoreOriginalBinary
}

struct WriteAccessAlert: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let retryAction: WriteAccessRetryAction
}

enum PatchDeliveryFilter: String, CaseIterable, Identifiable {
    case all
    case dylib
    case binary

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all:
            return "All"
        case .dylib:
            return "dylib"
        case .binary:
            return "binary"
        }
    }
}

enum PatchSortOrder: String, CaseIterable, Identifiable {
    case original
    case az
    case za

    var id: String { rawValue }

    var label: String {
        switch self {
        case .original:
            return "Default"
        case .az:
            return "A-Z"
        case .za:
            return "Z-A"
        }
    }
}

@MainActor
final class PatchgramViewModel: ObservableObject {
    @Published var appURL: URL?
    @Published var binaryRows: [BinaryRuleRowState] = []
    @Published var isValidApp = false
    @Published var appInfo = "No app selected"
    @Published var selectedAppIcon: NSImage?
    @Published var executableSize = "-"
    @Published var statusMessage = "Select Telegram.app or a copied app bundle to begin."
    @Published var isWorking = false
    @Published var operationProgress: Double?
    @Published var lastChangedFiles: [String] = []
    @Published var searchText = ""
    @Published var deliveryFilter: PatchDeliveryFilter = .all
    @Published var sortOrder: PatchSortOrder = .original
    @Published var binaryParameterValues: [String: UInt64] = [:]
    @Published var botVerificationConfigs: [String: BotVerificationPatchConfig] = [:]
    @Published var botVerificationUserPresets: [BotVerificationUserPreset] = []
    @Published var isShowingBotVerificationSettings = false
    @Published var customLevelRatingConfigs: [String: CustomLevelRatingPatchConfig] = [:]
    @Published var selfIdentityConfigs: [String: SelfIdentityPatchConfig] = [:]
    @Published var localPersonalChannelConfigs: [String: LocalPersonalChannelPatchConfig] = [:]
    @Published var fragmentPhoneConfigs: [String: FragmentPhonePatchConfig] = [:]
    @Published var customListUsernamesConfigs: [String: CustomListUsernamesPatchConfig] = [:]
    @Published var isShowingCustomListUsernamesSettings = false
    @Published var messageFactCheckConfigs: [String: MessageFactCheckPatchConfig] = [:]
    @Published var writeAccessAlert: WriteAccessAlert?
    @Published var updateChecksEnabled: Bool {
        didSet {
            UserDefaults.standard.set(updateChecksEnabled, forKey: Self.updateChecksEnabledKey)
        }
    }
    @Published var isShowingAppSettings = false
    @Published var availableUpdate: PatchgramAvailableUpdate?
    @Published var isCheckingForUpdates = false
    @Published var isUpdatingPatches = false

    private let binaryEngine = BinaryPatchEngine()
    private static let updateChecksEnabledKey = "Patchgram.updateChecks.enabled"
    private static let binaryParameterDefaultsPrefix = "Patchgram.binaryParameter."
    private static let botVerificationDefaultsPrefix = "Patchgram.botVerificationConfig."
    private static let customLevelRatingDefaultsPrefix = "Patchgram.customLevelRatingConfig."
    private static let selfIdentityDefaultsPrefix = "Patchgram.selfIdentityConfig."
    private static let localPersonalChannelDefaultsPrefix = "Patchgram.localPersonalChannelConfig."
    private static let fragmentPhoneDefaultsPrefix = "Patchgram.fragmentPhoneConfig."
    private static let customListUsernamesDefaultsPrefix = "Patchgram.customListUsernamesConfig."
    private static let messageFactCheckDefaultsPrefix = "Patchgram.messageFactCheckConfig."
    private static let botVerificationPresetsFileName = "BotVerificationPresets.json"
    private static let customAccountDesiredSubpatchIdsKey = "Patchgram.customAccountSubpatches.desired"
    private static let customAccountAppliedSubpatchIdsKey = "Patchgram.customAccountSubpatches.applied"
    private static let customAccountFeatureRuleId = "binary.account.custom_settings"
    private static let customPhoneNumberSubpatchId = "custom_phone_number"
    private static let customUserIdSubpatchId = "custom_user_id"
    private static let customPhoneNumberAlternativeGroup = "self_identity.custom_phone_number"
    private static let customUserIdAlternativeGroup = "self_identity.custom_user_id"
    private static let selfIdentityOverrideRuleId = "binary.visual.self_identity_override"
    private static let localPersonalChannelRuleId = "binary.visual.local_personal_channel"
    private static let fragmentPhoneRuleId = "binary.visual.fragment_phone"
    private static let customListUsernamesRuleId = "binary.visual.custom_list_usernames"
    private static let dylibInjectionRuleId = "binary.dylib.inject"
    private static let appConfigDesiredSubpatchIdsKey = "Patchgram.appConfigSubpatches.desired"
    private static let appConfigAppliedSubpatchIdsKey = "Patchgram.appConfigSubpatches.applied"
    private static let appConfigFeatureRuleId = "binary.config.disable_monetization"
    private static let messageSettingsDesiredSubpatchIdsKey = "Patchgram.messageSettingsSubpatches.desired"
    private static let messageSettingsAppliedSubpatchIdsKey = "Patchgram.messageSettingsSubpatches.applied"
    private static let messageSettingsFeatureRuleId = "binary.messages.settings"
    private static let messageFactCheckSubpatchId = "fact_check"
    private static let messageFactCheckAlternativeGroup = "messages.fact_check.local"
    private static let adsDesiredSubpatchIdsKey = "Patchgram.adsSubpatches.desired"
    private static let adsAppliedSubpatchIdsKey = "Patchgram.adsSubpatches.applied"
    private static let adsFeatureRuleId = "binary.ads.disable_sponsored"
    private static let appConfigConflictingRuleIds: Set<String> = [
        "binary.display.custom_ton",
        "binary.display.custom_stars",
        "binary.visual.custom_level_rating",
        "binary.premium.local"
    ]
    private static let runtimeRuleIds: Set<String> = [
        "binary.dylib.inject",
        "binary.overlay.profile_rain",
        "binary.visual.bot_verification",
        "binary.visual.custom_level_rating",
        "binary.visual.hide_self_phone",
        "binary.visual.self_identity_override",
        "binary.visual.local_personal_channel",
        "binary.visual.custom_list_usernames",
        "binary.visual.peer_badge",
        "binary.visual.no_premium_anim",
        "binary.visual.disable_spoilers",
        "binary.presence.force_offline",
        "binary.privacy.no_phone_on_add",
        "binary.links.open_without_warning",
        "binary.inline.callback_hover",
        "binary.display.custom_ton",
        "binary.display.custom_stars",
        appConfigFeatureRuleId,
        "binary.activity.block_typing",
        "binary.read_receipts.block_history_read",
        messageSettingsFeatureRuleId,
        "binary.premium.local",
        "binary.visual.sensitive_blur",
        "binary.stories.hide",
        adsFeatureRuleId
    ]
    private static let compositeFeatureRuleIds: Set<String> = [
        customAccountFeatureRuleId,
        appConfigFeatureRuleId,
        messageSettingsFeatureRuleId,
        adsFeatureRuleId
    ]
    private static let hiddenCustomAccountRuleIds: Set<String> = [
        "binary.display.custom_stars",
        "binary.display.custom_ton",
        "binary.visual.custom_level_rating",
        "binary.visual.peer_badge",
        "binary.visual.bot_verification",
        "binary.premium.local",
        selfIdentityOverrideRuleId,
        localPersonalChannelRuleId,
        fragmentPhoneRuleId,
        customListUsernamesRuleId
    ]
    private static let messageSettingsSubpatchDefinitions: [BinaryCompositeSubpatchDefinition] = [
        BinaryCompositeSubpatchDefinition(id: "typing", title: "Typing activity"),
        BinaryCompositeSubpatchDefinition(id: "read_receipts", title: "Read receipts"),
        BinaryCompositeSubpatchDefinition(id: "local_drafts", title: "Local drafts"),
        BinaryCompositeSubpatchDefinition(id: "scheduled_send", title: "Scheduled send"),
        BinaryCompositeSubpatchDefinition(id: messageFactCheckSubpatchId, title: "Custom Fact Check", showsChangeButton: true),
        BinaryCompositeSubpatchDefinition(id: "noforwards_copy", title: "Copy/save protect content"),
        BinaryCompositeSubpatchDefinition(id: "disable_ttl", title: "Disable TTL")
    ]
    private static let appConfigSubpatchDefinitions: [BinaryCompositeSubpatchDefinition] = [
        BinaryCompositeSubpatchDefinition(id: "app_config", title: "App config"),
        BinaryCompositeSubpatchDefinition(id: "premium_ui", title: "Premium UI"),
        BinaryCompositeSubpatchDefinition(id: "gifts", title: "Gifts"),
        BinaryCompositeSubpatchDefinition(id: "paid_reactions", title: "Paid reactions"),
        BinaryCompositeSubpatchDefinition(id: "emoji_statuses", title: "Emoji statuses and effects"),
        BinaryCompositeSubpatchDefinition(id: "stars_ton_collectibles", title: "Stars, TON and collectibles"),
        BinaryCompositeSubpatchDefinition(id: "boosts", title: "Boosts"),
        BinaryCompositeSubpatchDefinition(id: "read_receipts", title: "Read receipts fix")
    ]
    private static let adsSubpatchDefinitions: [BinaryCompositeSubpatchDefinition] = [
        BinaryCompositeSubpatchDefinition(id: "telegram_ads", title: "Telegram Ads"),
        BinaryCompositeSubpatchDefinition(id: "proxy_sponsor", title: "Proxy sponsor")
    ]
    private static let customAccountSubpatchDefinitions: [BinaryCompositeSubpatchDefinition] = [
        BinaryCompositeSubpatchDefinition(id: "custom_stars", title: "Custom Stars", internalRuleId: "binary.display.custom_stars", showsChangeButton: true),
        BinaryCompositeSubpatchDefinition(id: "custom_ton", title: "Custom TON", internalRuleId: "binary.display.custom_ton", showsChangeButton: true),
        BinaryCompositeSubpatchDefinition(id: "custom_level_rating", title: "Custom level rating", internalRuleId: "binary.visual.custom_level_rating", showsChangeButton: true),
        BinaryCompositeSubpatchDefinition(id: "visual_peer_badge", title: "Visual peer badge", internalRuleId: "binary.visual.peer_badge", showsChangeButton: true),
        BinaryCompositeSubpatchDefinition(id: "bot_verification", title: "Bot verification", internalRuleId: "binary.visual.bot_verification", showsSettingsButton: true, showsChangeButton: true),
        BinaryCompositeSubpatchDefinition(id: "local_premium", title: "Local Telegram Premium", internalRuleId: "binary.premium.local"),
        BinaryCompositeSubpatchDefinition(id: customPhoneNumberSubpatchId, title: "Custom phone number", internalRuleId: selfIdentityOverrideRuleId, alternativeGroup: customPhoneNumberAlternativeGroup, showsChangeButton: true),
        BinaryCompositeSubpatchDefinition(id: customUserIdSubpatchId, title: "Custom userID", internalRuleId: selfIdentityOverrideRuleId, alternativeGroup: customUserIdAlternativeGroup, showsChangeButton: true),
        BinaryCompositeSubpatchDefinition(id: "local_personal_channel", title: "Local attached channel", internalRuleId: localPersonalChannelRuleId, showsChangeButton: true),
        BinaryCompositeSubpatchDefinition(id: "fragment_phone", title: "Fragment phone", internalRuleId: fragmentPhoneRuleId, showsChangeButton: true),
        BinaryCompositeSubpatchDefinition(id: "custom_list_usernames", title: "Custom list usernames", internalRuleId: customListUsernamesRuleId, showsSettingsButton: true)
    ]
    private var desiredAppConfigSubpatchIds: Set<String>
    private var appliedAppConfigSubpatchIds: Set<String>
    private var desiredCustomAccountSubpatchIds: Set<String>
    private var appliedCustomAccountSubpatchIds: Set<String>
    private var desiredMessageSettingsSubpatchIds: Set<String>
    private var appliedMessageSettingsSubpatchIds: Set<String>
    private var desiredAdsSubpatchIds: Set<String>
    private var appliedAdsSubpatchIds: Set<String>
    private var pendingConfigSubpatchIds: Set<String> = []
    private var latestStatusByRuleId: [String: BinaryRuleStatus] = [:]
    private var didCheckForUpdatesOnLaunch = false

    init() {
        updateChecksEnabled = UserDefaults.standard.object(forKey: Self.updateChecksEnabledKey) as? Bool ?? true
        binaryParameterValues = Self.loadBinaryParameterValues()
        botVerificationUserPresets = Self.loadBotVerificationUserPresets()
        botVerificationConfigs = Self.loadBotVerificationConfigs()
        customLevelRatingConfigs = Self.loadCustomLevelRatingConfigs()
        selfIdentityConfigs = Self.loadSelfIdentityConfigs()
        localPersonalChannelConfigs = Self.loadLocalPersonalChannelConfigs()
        fragmentPhoneConfigs = Self.loadFragmentPhoneConfigs()
        customListUsernamesConfigs = Self.loadCustomListUsernamesConfigs()
        messageFactCheckConfigs = Self.loadMessageFactCheckConfigs()
        desiredCustomAccountSubpatchIds = Self.loadCustomAccountSubpatchIds(
            key: Self.customAccountDesiredSubpatchIdsKey,
            defaultValue: []
        )
        appliedCustomAccountSubpatchIds = Self.loadCustomAccountSubpatchIds(
            key: Self.customAccountAppliedSubpatchIdsKey,
            defaultValue: []
        )
        desiredAppConfigSubpatchIds = Self.loadAppConfigSubpatchIds(
            key: Self.appConfigDesiredSubpatchIdsKey,
            defaultValue: Set(Self.appConfigSubpatchDefinitions.map(\.id))
        )
        appliedAppConfigSubpatchIds = Self.loadAppConfigSubpatchIds(
            key: Self.appConfigAppliedSubpatchIdsKey,
            defaultValue: []
        )
        desiredMessageSettingsSubpatchIds = Self.loadMessageSettingsSubpatchIds(
            key: Self.messageSettingsDesiredSubpatchIdsKey,
            defaultValue: Set(Self.messageSettingsSubpatchDefinitions.map(\.id))
        )
        appliedMessageSettingsSubpatchIds = Self.loadMessageSettingsSubpatchIds(
            key: Self.messageSettingsAppliedSubpatchIdsKey,
            defaultValue: []
        )
        desiredAdsSubpatchIds = Self.loadAdsSubpatchIds(
            key: Self.adsDesiredSubpatchIdsKey,
            defaultValue: Set(Self.adsSubpatchDefinitions.map(\.id))
        )
        appliedAdsSubpatchIds = Self.loadAdsSubpatchIds(
            key: Self.adsAppliedSubpatchIdsKey,
            defaultValue: []
        )
        migrateSavedBotVerificationConfigsIntoUserPresets()

        if let saved = UserDefaults.standard.string(forKey: "Patchgram.appURL") {
            appURL = URL(fileURLWithPath: saved)
            rescanApp(quick: true)
        } else {
            resetBinaryRows()
        }
    }

    var filteredBinaryRows: [BinaryRuleRowState] {
        let needle = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let filtered = binaryRows.filter { row in
            let matchesDelivery: Bool
            switch deliveryFilter {
            case .all:
                matchesDelivery = true
            case .dylib:
                matchesDelivery = row.usesDylibPatch
            case .binary:
                matchesDelivery = !row.usesDylibPatch
            }
            guard matchesDelivery else { return false }
            guard !needle.isEmpty else { return true }
            return row.status.rule.title.lowercased().contains(needle)
                || row.status.rule.methodName.lowercased().contains(needle)
                || row.status.rule.constructorId.lowercased().contains(needle)
        }
        switch sortOrder {
        case .original:
            return filtered
        case .az:
            return filtered.sorted {
                $0.status.rule.title.localizedStandardCompare($1.status.rule.title) == .orderedAscending
            }
        case .za:
            return filtered.sorted {
                $0.status.rule.title.localizedStandardCompare($1.status.rule.title) == .orderedDescending
            }
        }
    }

    /// The 4 patcher sections shown on the main menu. The MEMBERSHIP is data-driven: each rule's
    /// `category` (from patches.json) decides where it lands, so new fetched patches self-place.
    struct PatchSection: Identifiable {
        let category: BinaryPatchCategory
        let title: String
        let description: String
        let icon: String   // resource section-<icon>.svg
        var id: BinaryPatchCategory { category }
    }

    static let sections: [PatchSection] = [
        PatchSection(category: .accounts, title: "Accounts", description: "Offline status, account limit, identity & profile", icon: "accounts"),
        PatchSection(category: .messages, title: "Messages", description: "Read receipts, links, spoilers, bot data", icon: "messages"),
        PatchSection(category: .optimizations, title: "Optimizations", description: "Strip Premium, ads and stories", icon: "optimizations"),
        PatchSection(category: .misc, title: "Misc", description: "Dylib injection and the rain overlay", icon: "misc")
    ]

    func categoryOf(_ row: BinaryRuleRowState) -> BinaryPatchCategory {
        row.status.rule.category ?? .misc
    }

    func rowCount(in category: BinaryPatchCategory) -> Int {
        binaryRows.lazy.filter { self.categoryOf($0) == category }.count
    }

    /// Rows of one section with the current type/sort/search filters applied (the same filters as before).
    func filteredRows(in category: BinaryPatchCategory) -> [BinaryRuleRowState] {
        let needle = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let filtered = binaryRows.filter { row in
            guard self.categoryOf(row) == category else { return false }
            let matchesDelivery: Bool
            switch deliveryFilter {
            case .all: matchesDelivery = true
            case .dylib: matchesDelivery = row.usesDylibPatch
            case .binary: matchesDelivery = !row.usesDylibPatch
            }
            guard matchesDelivery else { return false }
            guard !needle.isEmpty else { return true }
            return row.status.rule.title.lowercased().contains(needle)
                || row.status.rule.methodName.lowercased().contains(needle)
                || row.status.rule.constructorId.lowercased().contains(needle)
        }
        switch sortOrder {
        case .original: return filtered
        case .az: return filtered.sorted { $0.status.rule.title.localizedStandardCompare($1.status.rule.title) == .orderedAscending }
        case .za: return filtered.sorted { $0.status.rule.title.localizedStandardCompare($1.status.rule.title) == .orderedDescending }
        }
    }

    var hasPendingChanges: Bool {
        binaryRows.contains { $0.needsApply }
    }

    var enabledCount: Int {
        binaryRows.filter { $0.desiredEnabled }.count
    }

    /// True when at least one patch is actually applied (on disk / recorded in the
    /// manifest), so "Disable All" has something to revert. Deliberately ignores
    /// `desiredEnabled`: merely *selecting* a patch (without Apply) must NOT activate
    /// the button — there is nothing applied to disable yet.
    var hasAnyAppliedBinary: Bool {
        binaryRows.contains { $0.status.state.isEnabled }
    }

    var patchStateSummary: String {
        hasPendingChanges ? "Patch changes pending." : "Patch ready."
    }

    func checkForUpdatesOnLaunch() async {
        guard updateChecksEnabled, !didCheckForUpdatesOnLaunch else {
            return
        }
        didCheckForUpdatesOnLaunch = true
        await checkForUpdates(isUserInitiated: false)
    }

    /// Fetch + verify + install the latest signed patch bundle from GitHub, then hot-reload the
    /// catalog so the new patches/engine take effect on the next apply (no app rebuild needed).
    func updatePatches() async {
        guard !isUpdatingPatches else {
            return
        }
        isUpdatingPatches = true
        statusMessage = "Checking GitHub for patch updates..."
        defer {
            isUpdatingPatches = false
        }
        do {
            let outcome = try await PatchBundleUpdater.checkAndApply(appVersion: PatchgramUpdater.currentVersion)
            switch outcome {
            case let .upToDate(version):
                statusMessage = "Patches are up to date (bundle v\(version))."
            case let .updated(from, to, notes):
                BinaryPatchRuleCatalog.reloadFromDisk()
                if appURL != nil {
                    rescanApp()
                }
                let note = (notes?.isEmpty == false) ? " \(notes!)" : ""
                statusMessage = "Updated patches v\(from) → v\(to).\(note) Re-apply enabled patches to recompile."
            }
        } catch {
            statusMessage = "Patch update failed: \(error.localizedDescription)"
        }
    }

    func checkForUpdates(isUserInitiated: Bool = true) async {
        guard !isCheckingForUpdates else {
            return
        }
        isCheckingForUpdates = true
        if isUserInitiated {
            statusMessage = "Checking GitHub Releases for updates..."
        }
        defer {
            isCheckingForUpdates = false
        }

        do {
            if let update = try await PatchgramUpdater.checkForUpdate() {
                availableUpdate = update
                statusMessage = "Patchgram \(update.latestVersion) is available."
            } else if isUserInitiated {
                statusMessage = "Patchgram is up to date."
            }
        } catch {
            if isUserInitiated {
                statusMessage = "Update check failed: \(error.localizedDescription)"
            }
        }
    }

    func openReleasePage(_ update: PatchgramAvailableUpdate) {
        NSWorkspace.shared.open(update.releaseURL)
    }

    func chooseApp() {
        let panel = NSOpenPanel()
        panel.title = "Choose Telegram.app"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.treatsFilePackagesAsDirectories = false
        panel.allowedContentTypes = [.applicationBundle]
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"

        if panel.runModal() == .OK, let url = panel.url {
            appURL = url
            UserDefaults.standard.set(url.path, forKey: "Patchgram.appURL")
            rescanApp(quick: true)
        }
    }

    /// Reveals the folder that holds Patchgram's logs (PatchgramPatch.log / PatchgramHook.log)
    /// and the runtime config/manifest — i.e. `<app>/Contents/Resources` of the selected app.
    func openLogsFolder() {
        guard let appURL else { return }
        let logsDirectory = appURL.appendingPathComponent("Contents/Resources", isDirectory: true)
        let hookLog = logsDirectory.appendingPathComponent("PatchgramHook.log")
        // Select the hook log inside Finder when it exists, otherwise just open the folder.
        if FileManager.default.fileExists(atPath: hookLog.path) {
            NSWorkspace.shared.activateFileViewerSelecting([hookLog])
        } else {
            NSWorkspace.shared.open(logsDirectory)
        }
    }

    func rescanApp(quick: Bool = false) {
        guard let appURL else {
            statusMessage = "Select Telegram.app or a copied app bundle to begin."
            isValidApp = false
            appInfo = "No app selected"
            selectedAppIcon = nil
            executableSize = "-"
            return
        }
        let rescanStart = Date()
        let mode = quick ? "quick" : "full"
        do {
            let inspection = try binaryEngine.inspect(appURL: appURL)
            binaryEngine.appendDiagnosticLog(
                "BEGIN App rescan\nMODE: \(mode)\nAPP: \(inspection.bundleIdentifier) \(inspection.bundleVersion)\nTARGET: \(inspection.executableURL.path)",
                appURL: appURL
            )
            let manifestValues = try binaryEngine.manifestParameterValues(appURL: appURL)
            if !manifestValues.isEmpty {
                binaryParameterValues.merge(manifestValues) { _, manifestValue in manifestValue }
            }
            let manifestBotVerificationConfigs = try binaryEngine.manifestBotVerificationConfigs(appURL: appURL)
            if !manifestBotVerificationConfigs.isEmpty {
                botVerificationConfigs.merge(manifestBotVerificationConfigs) { _, manifestValue in manifestValue }
            }
            let manifestCustomLevelRatingConfigs = try binaryEngine.manifestCustomLevelRatingConfigs(appURL: appURL)
            if !manifestCustomLevelRatingConfigs.isEmpty {
                customLevelRatingConfigs.merge(manifestCustomLevelRatingConfigs) { _, manifestValue in manifestValue }
            }
            let manifestSelfIdentityConfigs = try binaryEngine.manifestSelfIdentityConfigs(appURL: appURL)
            if !manifestSelfIdentityConfigs.isEmpty {
                selfIdentityConfigs.merge(manifestSelfIdentityConfigs) { _, manifestValue in manifestValue }
            }
            let manifestLocalPersonalChannelConfigs = try binaryEngine.manifestLocalPersonalChannelConfigs(appURL: appURL)
            if !manifestLocalPersonalChannelConfigs.isEmpty {
                localPersonalChannelConfigs.merge(manifestLocalPersonalChannelConfigs) { _, manifestValue in manifestValue }
            }
            let manifestFragmentPhoneConfigs = try binaryEngine.manifestFragmentPhoneConfigs(appURL: appURL)
            if !manifestFragmentPhoneConfigs.isEmpty {
                fragmentPhoneConfigs.merge(manifestFragmentPhoneConfigs) { _, manifestValue in manifestValue }
            }
            let manifestCustomListUsernamesConfigs = try binaryEngine.manifestCustomListUsernamesConfigs(appURL: appURL)
            if !manifestCustomListUsernamesConfigs.isEmpty {
                customListUsernamesConfigs.merge(manifestCustomListUsernamesConfigs) { _, manifestValue in manifestValue }
            }
            let manifestMessageFactCheckConfigs = try binaryEngine.manifestMessageFactCheckConfigs(appURL: appURL)
            if !manifestMessageFactCheckConfigs.isEmpty {
                messageFactCheckConfigs.merge(manifestMessageFactCheckConfigs) { _, manifestValue in manifestValue }
            }
            let statuses: [BinaryRuleStatus]
            let statusRules = rulesForStatus()
            let manifestStatuses = try binaryEngine.manifestStatuses(appURL: appURL, rules: statusRules)
            if quick {
                statuses = manifestStatuses ?? binaryEngine.assumedUnappliedStatuses(rules: statusRules)
            } else {
                statuses = try binaryEngine.statuses(
                    appURL: appURL,
                    rules: statusRules,
                    parameterValues: binaryParameterValuesForEngine(),
                    botVerificationConfigs: botVerificationConfigsForEngine(),
                    customLevelRatingConfigs: customLevelRatingConfigsForEngine(),
                    selfIdentityConfigs: selfIdentityConfigsForEngine(),
                    localPersonalChannelConfigs: localPersonalChannelConfigsForEngine(),
                    fragmentPhoneConfigs: fragmentPhoneConfigsForEngine(),
                    customListUsernamesConfigs: customListUsernamesConfigsForEngine(),
                    messageFactCheckConfigs: messageFactCheckConfigsForEngine()
                )
            }
            applyAppInspection(inspection, statuses: statuses, quick: quick)
            binaryEngine.appendDiagnosticLog(
                "END App rescan\nMODE: \(mode)\nRULES: \(statuses.count)\nDURATION: \(Self.durationString(since: rescanStart))",
                appURL: appURL
            )
        } catch {
            isValidApp = false
            appInfo = "Invalid app bundle"
            selectedAppIcon = nil
            executableSize = "-"
            resetBinaryRows()
            statusMessage = error.localizedDescription
        }
    }

    func showBotVerificationSettings() {
        guard !isWorking else { return }
        isShowingBotVerificationSettings = true
    }

    func showCustomListUsernamesSettings() {
        guard !isWorking else { return }
        isShowingCustomListUsernamesSettings = true
    }

    func showSubpatchSettings(ruleId: String, subpatchId: String) {
        guard !isWorking, ruleId == Self.customAccountFeatureRuleId else { return }
        switch subpatchId {
        case "bot_verification":
            isShowingBotVerificationSettings = true
        case "custom_list_usernames":
            isShowingCustomListUsernamesSettings = true
        default:
            break
        }
    }

    func addBotVerificationUserPreset(title: String, customEmojiIdText: String, description: String) -> Bool {
        let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let emojiText = customEmojiIdText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedTitle.isEmpty else {
            statusMessage = "Enter a verification preset name."
            return false
        }
        guard let customEmojiId = UInt64(emojiText), customEmojiId > 0 else {
            statusMessage = "Enter a valid custom_emoji_id."
            return false
        }
        guard !normalizedDescription.isEmpty else {
            statusMessage = "Enter a bot verification description."
            return false
        }
        guard customEmojiId != BotVerificationPatchConfig.scaredCatEmojiId
            || normalizedDescription != BotVerificationPatchConfig.scaredCatDescription else {
            statusMessage = "Scared Cat already exists as a built-in preset."
            return false
        }
        guard !botVerificationUserPresets.contains(where: {
            $0.customEmojiId == customEmojiId
                && $0.normalizedDescription == normalizedDescription
        }) else {
            statusMessage = "This verification preset already exists."
            return false
        }

        botVerificationUserPresets.append(
            BotVerificationUserPreset(
                id: UUID(),
                title: normalizedTitle,
                customEmojiId: customEmojiId,
                description: normalizedDescription
            )
        )
        storeBotVerificationUserPresets()
        statusMessage = "Bot verification preset saved."
        return true
    }

    func deleteBotVerificationUserPreset(_ preset: BotVerificationUserPreset) {
        guard !isWorking else { return }
        botVerificationUserPresets.removeAll { $0.id == preset.id }
        storeBotVerificationUserPresets()

        let matchingRuleIds = botVerificationConfigs.compactMap { ruleId, config in
            config.matchesPreset(preset) ? ruleId : nil
        }
        for ruleId in matchingRuleIds {
            let config = botVerificationConfigs[ruleId] ?? BotVerificationPatchConfig.defaultConfig
            let replacement = BotVerificationPatchConfig(
                targetMode: config.targetMode,
                preset: .scaredCat,
                customEmojiId: BotVerificationPatchConfig.scaredCatEmojiId,
                description: BotVerificationPatchConfig.scaredCatDescription
            )
            botVerificationConfigs[ruleId] = replacement.normalized
            storeBotVerificationConfig(replacement, for: ruleId)
            if let index = binaryRows.firstIndex(where: { $0.id == ruleId }) {
                binaryRows[index].botVerificationConfig = replacement.normalized
            }
        }

        statusMessage = "Bot verification preset deleted."
    }

    private func applyAppInspection(_ inspection: AppInspection, statuses: [BinaryRuleStatus], quick: Bool) {
        latestStatusByRuleId = Dictionary(uniqueKeysWithValues: statuses.map { ($0.id, $0) })
        reconcileCustomAccountSubpatchesFromStatuses()
        let displayStatuses = statuses.filter { !Self.hiddenCustomAccountRuleIds.contains($0.id) }
            + [customAccountStatus()]
        binaryRows = displayStatuses.map {
            let subpatches = subpatchRows(for: $0)
            let desiredEnabled = Self.compositeFeatureRuleIds.contains($0.id)
                ? !desiredSubpatchIds(for: $0.id).isEmpty
                : $0.state.isEnabled
            return BinaryRuleRowState(
                status: $0,
                desiredEnabled: desiredEnabled,
                parameterValue: parameterValue(for: $0.rule),
                botVerificationConfig: botVerificationConfig(for: $0.rule),
                customLevelRatingConfig: customLevelRatingConfig(for: $0.rule),
                selfIdentityConfig: selfIdentityConfig(for: $0.rule),
                localPersonalChannelConfig: localPersonalChannelConfig(for: $0.rule),
                fragmentPhoneConfig: fragmentPhoneConfig(for: $0.rule),
                customListUsernamesConfig: customListUsernamesConfig(for: $0.rule),
                messageFactCheckConfig: messageFactCheckConfig(for: $0.rule),
                subpatches: subpatches
            )
        }
        isValidApp = true
        appInfo = "\(inspection.bundleIdentifier) \(inspection.bundleVersion)"
        selectedAppIcon = NSWorkspace.shared.icon(forFile: inspection.appURL.path)
        executableSize = ByteCountFormatter.string(fromByteCount: Int64(inspection.executableSize), countStyle: .file)
        statusMessage = readyStatusMessage(quick: quick)
    }

    private func readyStatusMessage(quick: Bool) -> String {
        return quick ? "Patch ready. Byte windows will be verified on apply." : "Patch ready."
    }

    func setDesired(_ enabled: Bool, for row: BinaryRuleRowState) {
        guard !isWorking else { return }
        guard let index = binaryRows.firstIndex(where: { $0.id == row.id }) else { return }
        if enabled {
            if row.id == Self.customAccountFeatureRuleId {
                guard confirmFeaturePatchDisablesAppConfigIfNeeded(enabling: Self.customAccountRule) else { return }
                guard configureCustomAccountSubpatches(
                    Set(Self.customAccountSubpatchDefinitions.map(\.id)),
                    actionTitle: "Enable"
                ) else { return }
                desiredCustomAccountSubpatchIds = Set(Self.customAccountSubpatchDefinitions.map(\.id))
                storeCustomAccountSubpatchIds(desiredCustomAccountSubpatchIds, key: Self.customAccountDesiredSubpatchIdsKey)
            } else if row.id == Self.appConfigFeatureRuleId {
                guard confirmAppConfigConflictsIfNeeded() else { return }
                desiredAppConfigSubpatchIds = Set(Self.appConfigSubpatchDefinitions.map(\.id))
                storeAppConfigSubpatchIds(desiredAppConfigSubpatchIds, key: Self.appConfigDesiredSubpatchIdsKey)
            } else if row.id == Self.messageSettingsFeatureRuleId {
                guard configureMessageSettingsSubpatches(
                    Set(Self.messageSettingsSubpatchDefinitions.map(\.id)),
                    actionTitle: "Enable"
                ) else { return }
                desiredMessageSettingsSubpatchIds = Set(Self.messageSettingsSubpatchDefinitions.map(\.id))
                storeMessageSettingsSubpatchIds(
                    desiredMessageSettingsSubpatchIds,
                    key: Self.messageSettingsDesiredSubpatchIdsKey
                )
            } else if row.id == Self.adsFeatureRuleId {
                desiredAdsSubpatchIds = Set(Self.adsSubpatchDefinitions.map(\.id))
                storeAdsSubpatchIds(desiredAdsSubpatchIds, key: Self.adsDesiredSubpatchIdsKey)
            } else if Self.appConfigConflictingRuleIds.contains(row.id) {
                guard confirmFeaturePatchDisablesAppConfigIfNeeded(enabling: row.status.rule) else { return }
            }
        } else if row.id == Self.customAccountFeatureRuleId {
            desiredCustomAccountSubpatchIds = []
            storeCustomAccountSubpatchIds(desiredCustomAccountSubpatchIds, key: Self.customAccountDesiredSubpatchIdsKey)
        } else if row.id == Self.appConfigFeatureRuleId {
            desiredAppConfigSubpatchIds = []
            storeAppConfigSubpatchIds(desiredAppConfigSubpatchIds, key: Self.appConfigDesiredSubpatchIdsKey)
        } else if row.id == Self.messageSettingsFeatureRuleId {
            desiredMessageSettingsSubpatchIds = []
            storeMessageSettingsSubpatchIds(
                desiredMessageSettingsSubpatchIds,
                key: Self.messageSettingsDesiredSubpatchIdsKey
            )
        } else if row.id == Self.adsFeatureRuleId {
            desiredAdsSubpatchIds = []
            storeAdsSubpatchIds(desiredAdsSubpatchIds, key: Self.adsDesiredSubpatchIdsKey)
        }
        if enabled, row.status.rule.kind == .botVerification {
            guard let config = promptForBotVerificationConfig(for: row.status.rule, actionTitle: "Enable") else { return }
            botVerificationConfigs[row.id] = config
            binaryRows[index].botVerificationConfig = config
            storeBotVerificationConfig(config, for: row.id)
        } else if enabled, row.status.rule.kind == .customLevelRating {
            guard let config = promptForCustomLevelRatingConfig(for: row.status.rule, actionTitle: "Enable") else { return }
            customLevelRatingConfigs[row.id] = config
            binaryRows[index].customLevelRatingConfig = config
            storeCustomLevelRatingConfig(config, for: row.id)
        } else if enabled, row.status.rule.kind == .selfIdentityOverride {
            guard let config = promptForSelfIdentityConfig(for: row.status.rule, actionTitle: "Enable") else { return }
            selfIdentityConfigs[row.id] = config
            binaryRows[index].selfIdentityConfig = config
            storeSelfIdentityConfig(config, for: row.id)
        } else if enabled, let value = promptForParameterIfNeeded(for: row.status.rule, actionTitle: "Enable") {
            binaryParameterValues[row.id] = value
            binaryRows[index].parameterValue = value
            UserDefaults.standard.set(String(value), forKey: Self.binaryParameterDefaultsPrefix + row.id)
        } else if enabled, row.status.rule.parameter != nil {
            return
        }
        binaryRows[index].desiredEnabled = enabled
        if enabled {
            autoEnableDylibInjectionIfNeeded(for: row.id)
        }
        if Self.compositeFeatureRuleIds.contains(row.id) {
            binaryRows[index].subpatches = subpatchRows(for: binaryRows[index].status)
        }
    }

    /// When any dylib (runtime) patch is turned on, also turn on the "Dylib injection"
    /// patch so the runtime library stays injected. Only ever *enables* it — never auto-
    /// disables — so turning another dylib patch back off does not drop the injection.
    private func autoEnableDylibInjectionIfNeeded(for ruleId: String) {
        guard ruleId != Self.dylibInjectionRuleId,
              Self.runtimeRuleIds.contains(ruleId) || Self.compositeFeatureRuleIds.contains(ruleId),
              let index = binaryRows.firstIndex(where: { $0.id == Self.dylibInjectionRuleId }),
              !binaryRows[index].desiredEnabled else { return }
        binaryRows[index].desiredEnabled = true
    }

    func setSubpatch(ruleId: String, subpatchId: String, enabled: Bool) {
        guard !isWorking else { return }
        guard Self.compositeFeatureRuleIds.contains(ruleId),
              binaryRows.contains(where: { $0.id == ruleId }) else { return }
        if ruleId == Self.customAccountFeatureRuleId, enabled {
            if let definition = Self.customAccountSubpatchDefinitions.first(where: { $0.id == subpatchId }),
               let internalRuleId = definition.internalRuleId,
               Self.appConfigConflictingRuleIds.contains(internalRuleId),
               let internalRule = BinaryPatchRuleCatalog.rule(id: internalRuleId) {
                guard confirmFeaturePatchDisablesAppConfigIfNeeded(enabling: internalRule) else { return }
            }
            guard configureCustomAccountSubpatches([subpatchId], actionTitle: "Enable") else { return }
        }
        if ruleId == Self.appConfigFeatureRuleId,
           enabled,
           desiredAppConfigSubpatchIds.isEmpty {
            guard confirmAppConfigConflictsIfNeeded() else { return }
        }
        if ruleId == Self.messageSettingsFeatureRuleId, enabled {
            guard configureMessageSettingsSubpatches([subpatchId], actionTitle: "Enable") else { return }
        }
        var desired = desiredSubpatchIds(for: ruleId)
        if enabled {
            desired.insert(subpatchId)
        } else {
            desired.remove(subpatchId)
        }
        setDesiredSubpatchIds(desired, for: ruleId)
        guard let index = binaryRows.firstIndex(where: { $0.id == ruleId }) else { return }
        binaryRows[index].desiredEnabled = !desired.isEmpty
        if !desired.isEmpty {
            autoEnableDylibInjectionIfNeeded(for: ruleId)
        }
        binaryRows[index].subpatches = subpatchRows(for: binaryRows[index].status)
    }

    func changeSubpatch(ruleId: String, subpatchId: String) {
        guard !isWorking else { return }
        guard binaryRows.contains(where: { $0.id == ruleId }) else { return }
        if ruleId == Self.customAccountFeatureRuleId {
            guard Self.customAccountSubpatchDefinitions.contains(where: {
                $0.id == subpatchId && $0.showsChangeButton
            }) else {
                return
            }
            guard configureCustomAccountSubpatches([subpatchId], actionTitle: "Change") else { return }
        } else if ruleId == Self.messageSettingsFeatureRuleId {
            guard Self.messageSettingsSubpatchDefinitions.contains(where: {
                $0.id == subpatchId && $0.showsChangeButton
            }) else {
                return
            }
            guard configureMessageSettingsSubpatches([subpatchId], actionTitle: "Change") else { return }
        } else {
            return
        }
        if desiredSubpatchIds(for: ruleId).contains(subpatchId)
            || appliedSubpatchIds(for: ruleId).contains(subpatchId) {
            pendingConfigSubpatchIds.insert(subpatchId)
        }
        guard let index = binaryRows.firstIndex(where: { $0.id == ruleId }) else { return }
        binaryRows[index].desiredEnabled = !desiredSubpatchIds(for: ruleId).isEmpty
        if !desiredSubpatchIds(for: ruleId).isEmpty {
            autoEnableDylibInjectionIfNeeded(for: ruleId)
        }
        binaryRows[index].subpatches = subpatchRows(for: binaryRows[index].status)
    }

    func updateAppliedPatch(for row: BinaryRuleRowState) {
        guard !isWorking else { return }
        guard let appURL else { return }
        guard verifyPatchWriteAccess(
            appURL: appURL,
            retryAction: .updateAppliedPatch(ruleId: row.id)
        ) else { return }
        if row.id == Self.customAccountFeatureRuleId {
            let enabledSubpatches = desiredSubpatchIds(for: row.id)
            guard !enabledSubpatches.isEmpty,
                  configureCustomAccountSubpatches(enabledSubpatches, actionTitle: "Update") else {
                return
            }
            setAppliedSubpatchIds([], for: Self.customAccountFeatureRuleId)
            refreshCustomAccountRow()
            applyBinaryChanges()
            return
        }
        let nextParameterValue: UInt64?
        let nextBotVerificationConfig: BotVerificationPatchConfig?
        let nextCustomLevelRatingConfig: CustomLevelRatingPatchConfig?
        let nextSelfIdentityConfig: SelfIdentityPatchConfig?
        if row.status.rule.kind == .botVerification {
            guard let config = promptForBotVerificationConfig(for: row.status.rule, actionTitle: "Update") else { return }
            botVerificationConfigs[row.id] = config
            storeBotVerificationConfig(config, for: row.id)
            if let index = binaryRows.firstIndex(where: { $0.id == row.id }) {
                binaryRows[index].botVerificationConfig = config
            }
            nextParameterValue = nil
            nextBotVerificationConfig = config
            nextCustomLevelRatingConfig = nil
            nextSelfIdentityConfig = nil
        } else if row.status.rule.kind == .customLevelRating {
            guard let config = promptForCustomLevelRatingConfig(for: row.status.rule, actionTitle: "Update") else { return }
            customLevelRatingConfigs[row.id] = config
            storeCustomLevelRatingConfig(config, for: row.id)
            if let index = binaryRows.firstIndex(where: { $0.id == row.id }) {
                binaryRows[index].customLevelRatingConfig = config
            }
            nextParameterValue = nil
            nextBotVerificationConfig = nil
            nextCustomLevelRatingConfig = config
            nextSelfIdentityConfig = nil
        } else if row.status.rule.kind == .selfIdentityOverride {
            guard let config = promptForSelfIdentityConfig(for: row.status.rule, actionTitle: "Update") else { return }
            selfIdentityConfigs[row.id] = config
            storeSelfIdentityConfig(config, for: row.id)
            if let index = binaryRows.firstIndex(where: { $0.id == row.id }) {
                binaryRows[index].selfIdentityConfig = config
            }
            nextParameterValue = nil
            nextBotVerificationConfig = nil
            nextCustomLevelRatingConfig = nil
            nextSelfIdentityConfig = config
        } else if row.status.rule.parameter != nil {
            guard let value = promptForParameterIfNeeded(for: row.status.rule, actionTitle: "Update") else { return }
            binaryParameterValues[row.id] = value
            UserDefaults.standard.set(String(value), forKey: Self.binaryParameterDefaultsPrefix + row.id)
            if let index = binaryRows.firstIndex(where: { $0.id == row.id }) {
                binaryRows[index].parameterValue = value
            }
            nextParameterValue = value
            nextBotVerificationConfig = nil
            nextCustomLevelRatingConfig = nil
            nextSelfIdentityConfig = nil
        } else {
            nextParameterValue = parameterValue(for: row.status.rule)
            nextBotVerificationConfig = botVerificationConfig(for: row.status.rule)
            nextCustomLevelRatingConfig = customLevelRatingConfig(for: row.status.rule)
            nextSelfIdentityConfig = selfIdentityConfig(for: row.status.rule)
        }
        beginOperation("Updating \(row.status.rule.title)...")
        do {
            let liveRuntimeUpdate = try canLiveUpdateRuntimeRule(row.status.rule, appURL: appURL)
            let closeMessage: String?
            if liveRuntimeUpdate {
                closeMessage = nil
                setOperationProgress(0.22, message: "Writing runtime config...")
            } else {
                setOperationProgress(0.15, message: "Closing selected app if needed...")
                closeMessage = try closeSelectedAppIfRunning(appURL: appURL)
                setOperationProgress(0.38, message: "Writing binary patch...")
            }
            let report = try binaryEngine.setRule(
                row.status.rule,
                enabled: true,
                appURL: appURL,
                parameterValue: nextParameterValue,
                botVerificationConfig: nextBotVerificationConfig,
                customLevelRatingConfig: nextCustomLevelRatingConfig,
                selfIdentityConfig: nextSelfIdentityConfig,
                messageFactCheckConfig: nil,
                signAfterPatch: !liveRuntimeUpdate
            )
            lastChangedFiles = report.changedExecutable ? changedFiles(for: row.status.rule) : []
            setOperationProgress(0.76, message: "Refreshing patch row...")
            markBinaryRule(
                row.status.rule,
                enabled: true,
                patchedParameterValue: nextParameterValue,
                patchedBotVerificationConfig: nextBotVerificationConfig,
                patchedCustomLevelRatingConfig: nextCustomLevelRatingConfig,
                patchedSelfIdentityConfig: nextSelfIdentityConfig,
                patchedLocalPersonalChannelConfig: nil,
                patchedFragmentPhoneConfig: nil,
                patchedCustomListUsernamesConfig: nil,
                patchedMessageFactCheckConfig: nil
            )
            setOperationProgress(0.90, message: liveRuntimeUpdate ? "Runtime config updated." : "Opening selected app...")
            _ = closeMessage
            _ = report
            if !liveRuntimeUpdate {
                _ = openSelectedApp(appURL: appURL)
            }
            finishOperation(liveRuntimeUpdate ? "Runtime patch updated live." : "Patch ready.")
        } catch {
            failOperation(error.localizedDescription)
        }
    }

    func applyChanges() {
        applyBinaryChanges()
    }

    func disableAll() {
        disableAllBinary()
    }

    func applyBinaryChanges() {
        guard !isWorking else { return }
        guard let appURL else { return }
        let pendingRows = binaryRows.filter(\.needsApply)
        guard !pendingRows.isEmpty else { return }
        guard verifyPatchWriteAccess(appURL: appURL, retryAction: .applyBinaryChanges) else { return }
        let changes = pendingRows.flatMap { self.changes(for: $0, changedGroupsOnly: true) }
        beginOperation("Applying built app patches...")
        do {
            let liveRuntimeUpdate = try canLiveUpdateRuntimeChanges(changes, appURL: appURL)
            let closeMessage: String?
            if liveRuntimeUpdate {
                closeMessage = nil
                setOperationProgress(0.26, message: "Writing runtime config...")
            } else {
                setOperationProgress(0.15, message: "Closing selected app if needed...")
                closeMessage = try closeSelectedAppIfRunning(appURL: appURL)
                setOperationProgress(0.36, message: "Writing binary patches...")
            }
            let report = try binaryEngine.applyRuleChanges(
                changes,
                appURL: appURL,
                signAfterPatch: !liveRuntimeUpdate
            )
            lastChangedFiles = report.changedExecutable ? changedFiles(for: changes.map(\.rule)) : []
            setOperationProgress(0.76, message: "Refreshing changed rows...")
            for change in changes {
                markBinaryRule(
                    change.rule,
                    enabled: change.enabled,
                    patchedParameterValue: change.parameterValue,
                    patchedBotVerificationConfig: change.botVerificationConfig,
                    patchedCustomLevelRatingConfig: change.customLevelRatingConfig,
                    patchedSelfIdentityConfig: change.selfIdentityConfig,
                    patchedLocalPersonalChannelConfig: change.localPersonalChannelConfig,
                    patchedFragmentPhoneConfig: change.fragmentPhoneConfig,
                    patchedCustomListUsernamesConfig: change.customListUsernamesConfig,
                    patchedMessageFactCheckConfig: change.messageFactCheckConfig,
                    enabledAlternativeGroups: change.enabledAlternativeGroups
                )
            }
            setOperationProgress(0.90, message: liveRuntimeUpdate ? "Runtime config updated." : "Opening selected app...")
            _ = closeMessage
            _ = report
            if !liveRuntimeUpdate {
                _ = openSelectedApp(appURL: appURL)
            }
            finishOperation(liveRuntimeUpdate ? "Runtime patches updated live." : (report.messages.isEmpty ? "Patch ready." : report.messages.joined(separator: " ")))
        } catch {
            failOperation(error.localizedDescription)
        }
    }

    private func canLiveUpdateRuntimeRule(_ rule: BinaryPatchRule, appURL: URL) throws -> Bool {
        guard Self.runtimeRuleIds.contains(rule.id) else { return false }
        return try binaryEngine.runtimeHookSupportsLiveReload(appURL: appURL)
    }

    private func canLiveUpdateRuntimeChanges(_ changes: [BinaryPatchRuleChange], appURL: URL) throws -> Bool {
        guard !changes.isEmpty else {
            binaryEngine.appendDiagnosticLog(
                "LIVE RUNTIME decision result=false reason=empty-changes",
                appURL: appURL
            )
            return false
        }
        guard changes.allSatisfy({ Self.runtimeRuleIds.contains($0.rule.id) }) else {
            binaryEngine.appendDiagnosticLog(
                "LIVE RUNTIME decision result=false reason=non-runtime-change changes=\(changes.map { $0.rule.id }.joined(separator: ","))",
                appURL: appURL
            )
            return false
        }
        let supportsLiveReload = try binaryEngine.runtimeHookSupportsLiveReload(appURL: appURL)
        guard supportsLiveReload else {
            binaryEngine.appendDiagnosticLog(
                "LIVE RUNTIME decision result=false reason=hook-not-live-reloadable changes=\(changes.map { "\($0.rule.id)=\($0.enabled)" }.joined(separator: ","))",
                appURL: appURL
            )
            return false
        }
        let runtimeStillDesired = changes.contains {
            Self.runtimeRuleIds.contains($0.rule.id)
                && $0.enabled
        } || desiredCustomAccountSubpatchIds.contains { subpatchId in
            guard let ruleId = Self.customAccountSubpatchDefinitions.first(where: { $0.id == subpatchId })?.internalRuleId else {
                return false
            }
            return Self.runtimeRuleIds.contains(ruleId)
        } || binaryRows.contains {
            Self.runtimeRuleIds.contains($0.id)
                && $0.desiredEnabled
        }
        binaryEngine.appendDiagnosticLog(
            "LIVE RUNTIME decision result=\(runtimeStillDesired) reason=\(runtimeStillDesired ? "runtime-config" : "no-runtime-left") changes=\(changes.map { "\($0.rule.id)=\($0.enabled)" }.joined(separator: ","))",
            appURL: appURL
        )
        return runtimeStillDesired
    }

    func disableAllBinary() {
        guard !isWorking else { return }
        guard let appURL else { return }
        let rowsToDisable = binaryRows.filter { $0.desiredEnabled || $0.status.state.isEnabled }
        guard !rowsToDisable.isEmpty else { return }
        guard verifyPatchWriteAccess(appURL: appURL, retryAction: .disableAllBinary) else { return }
        let changes = rowsToDisable.flatMap {
            self.changes(for: $0, changedGroupsOnly: false, forcedEnabled: false)
        }
        beginOperation("Disabling built app patches...")
        do {
            setOperationProgress(0.15, message: "Closing selected app if needed...")
            let closeMessage = try closeSelectedAppIfRunning(appURL: appURL)
            setOperationProgress(0.36, message: "Restoring binary bytes...")
            let report = try binaryEngine.applyRuleChanges(changes, appURL: appURL)
            lastChangedFiles = report.changedExecutable ? changedFiles(for: changes.map(\.rule)) : []
            setOperationProgress(0.76, message: "Refreshing changed rows...")
            for change in changes {
                markBinaryRule(
                    change.rule,
                    enabled: false,
                    patchedParameterValue: nil,
                    patchedBotVerificationConfig: nil,
                    patchedCustomLevelRatingConfig: nil,
                    patchedSelfIdentityConfig: nil,
                    patchedLocalPersonalChannelConfig: nil,
                    patchedFragmentPhoneConfig: nil,
                    patchedCustomListUsernamesConfig: nil,
                    patchedMessageFactCheckConfig: nil,
                    enabledAlternativeGroups: change.enabledAlternativeGroups
                )
            }
            markAllBinaryRulesDisabled()
            setOperationProgress(0.90, message: "Opening selected app...")
            _ = closeMessage
            _ = report
            _ = openSelectedApp(appURL: appURL)
            finishOperation("All patches disabled.")
        } catch {
            failOperation(error.localizedDescription)
        }
    }

    func restoreOriginalBinary() {
        guard !isWorking else { return }
        guard let appURL else { return }
        guard verifyPatchWriteAccess(appURL: appURL, retryAction: .restoreOriginalBinary) else { return }
        beginOperation("Restoring backup...")
        do {
            setOperationProgress(0.15, message: "Closing selected app if needed...")
            let closeMessage = try closeSelectedAppIfRunning(appURL: appURL)
            setOperationProgress(0.42, message: "Restoring original executable...")
            let report = try binaryEngine.restoreOriginalExecutable(appURL: appURL)
            lastChangedFiles = report.changedExecutable ? ["Contents/MacOS executable", "ad-hoc codesign"] : []
            setOperationProgress(0.76, message: "Refreshing patch rows...")
            markAllBinaryRulesDisabled()
            setOperationProgress(0.90, message: "Opening selected app...")
            _ = closeMessage
            _ = report
            _ = openSelectedApp(appURL: appURL)
            finishOperation("Patch ready.")
        } catch {
            failOperation(error.localizedDescription)
        }
    }

    private func markBinaryRule(
        _ rule: BinaryPatchRule,
        enabled: Bool,
        patchedParameterValue: UInt64?,
        patchedBotVerificationConfig: BotVerificationPatchConfig?,
        patchedCustomLevelRatingConfig: CustomLevelRatingPatchConfig?,
        patchedSelfIdentityConfig: SelfIdentityPatchConfig?,
        patchedLocalPersonalChannelConfig: LocalPersonalChannelPatchConfig?,
        patchedFragmentPhoneConfig: FragmentPhonePatchConfig?,
        patchedCustomListUsernamesConfig: CustomListUsernamesPatchConfig?,
        patchedMessageFactCheckConfig: MessageFactCheckPatchConfig?,
        enabledAlternativeGroups: Set<String>? = nil
    ) {
        let displayRule = BinaryPatchRuleCatalog.rule(id: rule.id) ?? rule
        let state: RuleApplicationState = enabled ? .applied : .notApplied
        let nextStatus = BinaryRuleStatus(
            rule: displayRule,
            state: state,
            detail: enabled ? "Recorded in Patchgram manifest." : "Not recorded in Patchgram manifest."
        )
        latestStatusByRuleId[displayRule.id] = nextStatus
        if Self.hiddenCustomAccountRuleIds.contains(displayRule.id) {
            markCustomAccountSubpatches(for: displayRule.id, enabled: enabled, enabledAlternativeGroups: enabledAlternativeGroups)
            refreshCustomAccountRow()
            return
        }
        guard let index = binaryRows.firstIndex(where: { $0.id == rule.id }) else { return }
        binaryRows[index].status = BinaryRuleStatus(
            rule: displayRule,
            state: state,
            detail: enabled ? "Recorded in Patchgram manifest." : "Not recorded in Patchgram manifest."
        )
        binaryRows[index].desiredEnabled = enabled
        let storedParameterValue = parameterValue(for: displayRule)
        binaryRows[index].parameterValue = enabled ? storedParameterValue : patchedParameterValue
        let storedBotVerificationConfig = botVerificationConfig(for: displayRule)
        binaryRows[index].botVerificationConfig = enabled
            ? storedBotVerificationConfig
            : (patchedBotVerificationConfig ?? storedBotVerificationConfig)
        let storedCustomLevelRatingConfig = customLevelRatingConfig(for: displayRule)
        binaryRows[index].customLevelRatingConfig = enabled
            ? storedCustomLevelRatingConfig
            : (patchedCustomLevelRatingConfig ?? storedCustomLevelRatingConfig)
        let storedSelfIdentityConfig = selfIdentityConfig(for: displayRule)
        binaryRows[index].selfIdentityConfig = enabled
            ? storedSelfIdentityConfig
            : (patchedSelfIdentityConfig ?? storedSelfIdentityConfig)
        let storedLocalPersonalChannelConfig = localPersonalChannelConfig(for: displayRule)
        binaryRows[index].localPersonalChannelConfig = enabled
            ? storedLocalPersonalChannelConfig
            : (patchedLocalPersonalChannelConfig ?? storedLocalPersonalChannelConfig)
        let storedFragmentPhoneConfig = fragmentPhoneConfig(for: displayRule)
        binaryRows[index].fragmentPhoneConfig = enabled
            ? storedFragmentPhoneConfig
            : (patchedFragmentPhoneConfig ?? storedFragmentPhoneConfig)
        let storedCustomListUsernamesConfig = customListUsernamesConfig(for: displayRule)
        binaryRows[index].customListUsernamesConfig = enabled
            ? storedCustomListUsernamesConfig
            : (patchedCustomListUsernamesConfig ?? storedCustomListUsernamesConfig)
        let storedMessageFactCheckConfig = messageFactCheckConfig(for: displayRule)
        binaryRows[index].messageFactCheckConfig = enabled
            ? storedMessageFactCheckConfig
            : (patchedMessageFactCheckConfig ?? storedMessageFactCheckConfig)
        if Self.compositeFeatureRuleIds.contains(displayRule.id) {
            if enabled {
                let appliedIds = subpatchIds(forAlternativeGroups: enabledAlternativeGroups, ruleId: displayRule.id)
                    ?? desiredSubpatchIds(for: displayRule.id)
                setAppliedSubpatchIds(appliedIds, for: displayRule.id)
                pendingConfigSubpatchIds.subtract(appliedIds)
            } else {
                setAppliedSubpatchIds([], for: displayRule.id)
                setDesiredSubpatchIds([], for: displayRule.id)
                pendingConfigSubpatchIds.subtract(Self.subpatchDefinitions(for: displayRule.id).map(\.id))
            }
            binaryRows[index].desiredEnabled = !desiredSubpatchIds(for: displayRule.id).isEmpty
            binaryRows[index].subpatches = subpatchRows(for: binaryRows[index].status)
        }
    }

    private func markAllBinaryRulesDisabled() {
        setDesiredSubpatchIds([], for: Self.customAccountFeatureRuleId)
        setAppliedSubpatchIds([], for: Self.customAccountFeatureRuleId)
        setDesiredSubpatchIds([], for: Self.appConfigFeatureRuleId)
        setAppliedSubpatchIds([], for: Self.appConfigFeatureRuleId)
        setDesiredSubpatchIds([], for: Self.adsFeatureRuleId)
        setAppliedSubpatchIds([], for: Self.adsFeatureRuleId)
        pendingConfigSubpatchIds = []
        for index in binaryRows.indices {
            let rule = binaryRows[index].status.rule
            binaryRows[index].status = BinaryRuleStatus(
                rule: rule,
                state: .notApplied,
                detail: "Restored from Patchgram backup."
            )
            binaryRows[index].desiredEnabled = false
            binaryRows[index].botVerificationConfig = botVerificationConfig(for: rule)
            binaryRows[index].customLevelRatingConfig = customLevelRatingConfig(for: rule)
            binaryRows[index].selfIdentityConfig = selfIdentityConfig(for: rule)
            binaryRows[index].localPersonalChannelConfig = localPersonalChannelConfig(for: rule)
            binaryRows[index].fragmentPhoneConfig = fragmentPhoneConfig(for: rule)
            binaryRows[index].customListUsernamesConfig = customListUsernamesConfig(for: rule)
            binaryRows[index].messageFactCheckConfig = messageFactCheckConfig(for: rule)
            if Self.compositeFeatureRuleIds.contains(rule.id) {
                binaryRows[index].subpatches = subpatchRows(for: binaryRows[index].status)
            }
        }
    }

    private func beginOperation(_ message: String) {
        isWorking = true
        operationProgress = 0.06
        statusMessage = message
        flushOperationProgress()
    }

    private func setOperationProgress(_ value: Double, message: String? = nil) {
        operationProgress = min(max(value, 0), 1)
        if let message {
            statusMessage = message
        }
        flushOperationProgress()
    }

    private func finishOperation(_ message: String) {
        statusMessage = message
        operationProgress = 1
        flushOperationProgress()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            Task { @MainActor in
                guard let self, self.operationProgress == 1 else { return }
                self.operationProgress = nil
                self.isWorking = false
            }
        }
    }

    private func failOperation(_ message: String) {
        statusMessage = message
        operationProgress = nil
        isWorking = false
    }

    private func flushOperationProgress() {
        RunLoop.current.run(until: Date().addingTimeInterval(0.02))
    }

    private func openSelectedApp(appURL: URL) -> String {
        let openStart = Date()
        binaryEngine.appendDiagnosticLog(
            "BEGIN Open selected app\nTARGET: \(appURL.path)",
            appURL: appURL
        )
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.openApplication(at: appURL, configuration: configuration) { [weak self] _, error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    self.binaryEngine.appendDiagnosticLog(
                        "END Open selected app\nRESULT: failed\nDURATION: \(Self.durationString(since: openStart))\nERROR: \(error.localizedDescription)",
                        appURL: appURL
                    )
                    self.statusMessage += " Failed to reopen app: \(error.localizedDescription)"
                } else {
                    self.binaryEngine.appendDiagnosticLog(
                        "END Open selected app\nRESULT: opened\nDURATION: \(Self.durationString(since: openStart))",
                        appURL: appURL
                    )
                }
            }
        }
        return "Opening selected app."
    }

    private func closeSelectedAppIfRunning(appURL: URL) throws -> String? {
        let closeStart = Date()
        let inspection = try binaryEngine.inspect(appURL: appURL)
        binaryEngine.appendDiagnosticLog(
            "BEGIN Close selected app\nAPP: \(inspection.bundleIdentifier) \(inspection.bundleVersion)\nTARGET: \(appURL.path)",
            appURL: appURL
        )
        let selectedPath = appURL.standardizedFileURL.path
        var running = NSWorkspace.shared.runningApplications.filter { app in
            app.bundleURL?.standardizedFileURL.path == selectedPath
        }

        if running.isEmpty && appURL.path == "/Applications/Telegram.app" {
            running = NSWorkspace.shared.runningApplications.filter {
                $0.bundleIdentifier == inspection.bundleIdentifier
            }
        }

        guard !running.isEmpty else {
            binaryEngine.appendDiagnosticLog(
                "END Close selected app\nRESULT: not running\nDURATION: \(Self.durationString(since: closeStart))",
                appURL: appURL
            )
            return nil
        }

        statusMessage = "Closing \(inspection.bundleIdentifier) before patching..."
        for app in running where !app.isTerminated {
            app.terminate()
        }
        if waitForTermination(of: running, timeout: 6) {
            binaryEngine.appendDiagnosticLog(
                "END Close selected app\nRESULT: terminated\nDURATION: \(Self.durationString(since: closeStart))",
                appURL: appURL
            )
            return "Closed running app before patching."
        }

        for app in running where !app.isTerminated {
            app.forceTerminate()
        }
        if waitForTermination(of: running, timeout: 3) {
            binaryEngine.appendDiagnosticLog(
                "END Close selected app\nRESULT: force-terminated\nDURATION: \(Self.durationString(since: closeStart))",
                appURL: appURL
            )
            return "Force-closed running app before patching."
        }

        let message = "Telegram is still running. Close it manually and try again."
        binaryEngine.appendDiagnosticLog(
            "ERROR Close selected app\nDURATION: \(Self.durationString(since: closeStart))\nERROR: \(message)",
            appURL: appURL
        )
        throw PatchgramError.processFailed(message)
    }

    private func waitForTermination(of apps: [NSRunningApplication], timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if apps.allSatisfy(\.isTerminated) {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        return apps.allSatisfy(\.isTerminated)
    }

    private func verifyPatchWriteAccess(appURL: URL, retryAction: WriteAccessRetryAction) -> Bool {
        do {
            try binaryEngine.verifyPatchWriteAccess(appURL: appURL)
            return true
        } catch {
            statusMessage = error.localizedDescription
            operationProgress = nil
            writeAccessAlert = WriteAccessAlert(
                message: """
                Patchgram needs permission to edit the selected app bundle before it can patch or unpatch it.

                Grant access in System Settings, then try again.
                """,
                retryAction: retryAction
            )
            return false
        }
    }

    func retryWriteAccessAction(_ action: WriteAccessRetryAction) {
        writeAccessAlert = nil
        switch action {
        case let .updateAppliedPatch(ruleId):
            guard let row = binaryRows.first(where: { $0.id == ruleId }) else { return }
            updateAppliedPatch(for: row)
        case .applyBinaryChanges:
            applyBinaryChanges()
        case .disableAllBinary:
            disableAllBinary()
        case .restoreOriginalBinary:
            restoreOriginalBinary()
        }
    }

    func openFullDiskAccessSettings() {
        let urls = [
            "x-apple.systempreferences:com.apple.preference.security?Privacy_AppBundles",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles",
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension"
        ].compactMap(URL.init(string:))

        for url in urls where NSWorkspace.shared.open(url) {
            return
        }
    }

    private func resetBinaryRows() {
        let unavailableStatuses = BinaryPatchRuleCatalog.rules.map {
            BinaryRuleStatus(rule: $0, state: .unavailable, detail: "No app selected.")
        }
        latestStatusByRuleId = Dictionary(uniqueKeysWithValues: unavailableStatuses.map { ($0.id, $0) })
        let displayStatuses = unavailableStatuses.filter { !Self.hiddenCustomAccountRuleIds.contains($0.id) }
            + [customAccountStatus()]
        binaryRows = displayStatuses.map {
            BinaryRuleRowState(
                status: $0,
                desiredEnabled: false,
                parameterValue: parameterValue(for: $0.rule),
                botVerificationConfig: botVerificationConfig(for: $0.rule),
                customLevelRatingConfig: customLevelRatingConfig(for: $0.rule),
                selfIdentityConfig: selfIdentityConfig(for: $0.rule),
                localPersonalChannelConfig: localPersonalChannelConfig(for: $0.rule),
                fragmentPhoneConfig: fragmentPhoneConfig(for: $0.rule),
                customListUsernamesConfig: customListUsernamesConfig(for: $0.rule),
                messageFactCheckConfig: messageFactCheckConfig(for: $0.rule),
                subpatches: subpatchRows(for: $0)
            )
        }
    }

    private func rulesForStatus() -> [BinaryPatchRule] {
        BinaryPatchRuleCatalog.rules.map { rule in
            guard Self.compositeFeatureRuleIds.contains(rule.id),
                  !desiredSubpatchIds(for: rule.id).isEmpty else {
                return rule
            }
            return compositeRule(rule.id, filteredTo: alternativeGroups(
                forSubpatchIds: desiredSubpatchIds(for: rule.id),
                ruleId: rule.id
            ))
        }
    }

    private func ruleForChange(_ row: BinaryRuleRowState, changedGroupsOnly: Bool) -> BinaryPatchRule {
        if Self.compositeFeatureRuleIds.contains(row.id) {
            guard changedGroupsOnly else {
                return BinaryPatchRuleCatalog.rule(id: row.id) ?? row.status.rule
            }
            let changedSubpatchIds = changedSubpatchIds(for: row)
            guard !changedSubpatchIds.isEmpty else {
                return row.status.rule
            }
            return compositeRule(row.id, filteredTo: alternativeGroups(forSubpatchIds: changedSubpatchIds, ruleId: row.id))
        }
        return row.status.rule
    }

    private func changes(
        for row: BinaryRuleRowState,
        changedGroupsOnly: Bool,
        forcedEnabled: Bool? = nil
    ) -> [BinaryPatchRuleChange] {
        if row.id == Self.customAccountFeatureRuleId {
            return customAccountChanges(for: row, changedGroupsOnly: changedGroupsOnly, forcedEnabled: forcedEnabled)
        }
        let rule = ruleForChange(row, changedGroupsOnly: changedGroupsOnly)
        let enabled = forcedEnabled ?? row.desiredEnabled
        return [
            BinaryPatchRuleChange(
                rule: rule,
                enabled: enabled,
                parameterValue: enabled ? parameterValue(for: rule) : nil,
                botVerificationConfig: enabled ? botVerificationConfig(for: rule) : nil,
                customLevelRatingConfig: enabled ? customLevelRatingConfig(for: rule) : nil,
                selfIdentityConfig: enabled ? selfIdentityConfig(for: rule) : nil,
                localPersonalChannelConfig: enabled ? localPersonalChannelConfig(for: rule) : nil,
                fragmentPhoneConfig: enabled ? fragmentPhoneConfig(for: rule) : nil,
                customListUsernamesConfig: enabled ? customListUsernamesConfig(for: rule) : nil,
                messageFactCheckConfig: enabled ? messageFactCheckConfig(for: rule) : nil,
                enabledAlternativeGroups: enabled ? alternativeGroupsForChange(row) : nil
            )
        ]
    }

    private func customAccountChanges(
        for row: BinaryRuleRowState,
        changedGroupsOnly: Bool,
        forcedEnabled: Bool?
    ) -> [BinaryPatchRuleChange] {
        let desired = forcedEnabled == false ? [] : desiredSubpatchIds(for: row.id)
        let candidateDefinitions = changedGroupsOnly && forcedEnabled == nil
            ? Self.customAccountSubpatchDefinitions.filter {
                changedSubpatchIds(for: row).contains($0.id)
                    || pendingConfigSubpatchIds.contains($0.id)
            }
            : Self.customAccountSubpatchDefinitions
        var changedRuleIds = Set(candidateDefinitions.compactMap(\.internalRuleId))
        if candidateDefinitions.contains(where: { $0.internalRuleId == Self.selfIdentityOverrideRuleId }) {
            changedRuleIds.insert(Self.selfIdentityOverrideRuleId)
        }
        return changedRuleIds.compactMap { ruleId in
            guard let rule = BinaryPatchRuleCatalog.rule(id: ruleId) else { return nil }
            let enabled = desired.contains { subpatchId in
                Self.customAccountSubpatchDefinitions.contains {
                    $0.id == subpatchId && $0.internalRuleId == ruleId
                }
            }
            let groups: Set<String>?
            if ruleId == Self.selfIdentityOverrideRuleId, enabled {
                groups = Set(Self.customAccountSubpatchDefinitions.compactMap { definition in
                    desired.contains(definition.id) && definition.internalRuleId == ruleId
                        ? definition.alternativeGroup
                        : nil
                })
            } else {
                groups = nil
            }
            return BinaryPatchRuleChange(
                rule: rule,
                enabled: enabled,
                parameterValue: enabled ? parameterValue(for: rule) : nil,
                botVerificationConfig: enabled ? botVerificationConfig(for: rule) : nil,
                customLevelRatingConfig: enabled ? customLevelRatingConfig(for: rule) : nil,
                selfIdentityConfig: enabled ? selfIdentityConfig(for: rule) : nil,
                localPersonalChannelConfig: enabled ? localPersonalChannelConfig(for: rule) : nil,
                fragmentPhoneConfig: enabled ? fragmentPhoneConfig(for: rule) : nil,
                customListUsernamesConfig: enabled ? customListUsernamesConfig(for: rule) : nil,
                messageFactCheckConfig: enabled ? messageFactCheckConfig(for: rule) : nil,
                enabledAlternativeGroups: groups
            )
        }
    }

    private func alternativeGroupsForChange(_ row: BinaryRuleRowState) -> Set<String>? {
        guard Self.compositeFeatureRuleIds.contains(row.id) else { return nil }
        return alternativeGroups(forSubpatchIds: desiredSubpatchIds(for: row.id), ruleId: row.id)
    }

    private func compositeRule(_ ruleId: String, filteredTo groups: Set<String>) -> BinaryPatchRule {
        guard let rule = BinaryPatchRuleCatalog.rule(id: ruleId),
              !groups.isEmpty else {
            return BinaryPatchRuleCatalog.rule(id: ruleId)
                ?? BinaryPatchRuleDefinitions.rules(withIds: [ruleId])[0]
        }
        let replacements = rule.replacements.filter { groups.contains($0.alternativeGroup) }
        return BinaryPatchRule(
            id: rule.id,
            title: rule.title,
            methodName: rule.methodName,
            constructorId: rule.constructorId,
            kind: rule.kind,
            summary: rule.summary,
            disabledBehavior: rule.disabledBehavior,
            riskNote: rule.riskNote,
            supportedBuildNote: rule.supportedBuildNote,
            parameter: rule.parameter,
            replacements: replacements
        )
    }

    private func subpatchRows(for status: BinaryRuleStatus) -> [BinarySubpatchRowState] {
        guard Self.compositeFeatureRuleIds.contains(status.id) else { return [] }
        let appliedIds = appliedSubpatchIds(for: status)
        let desiredIds = desiredSubpatchIds(for: status.id)
        return Self.subpatchDefinitions(for: status.id).map { subpatch in
            BinarySubpatchRowState(
                id: subpatch.id,
                title: subpatch.title,
                showsSettingsButton: subpatch.showsSettingsButton,
                showsChangeButton: subpatch.showsChangeButton,
                desiredEnabled: desiredIds.contains(subpatch.id),
                appliedEnabled: appliedIds.contains(subpatch.id),
                parametersChanged: pendingConfigSubpatchIds.contains(subpatch.id)
            )
        }
    }

    private func appliedSubpatchIds(for status: BinaryRuleStatus) -> Set<String> {
        let stored = appliedSubpatchIds(for: status.id)
        if !stored.isEmpty {
            return stored
        }
        return status.state.isEnabled
            ? Set(Self.subpatchDefinitions(for: status.id).map(\.id))
            : []
    }

    private func changedSubpatchIds(for row: BinaryRuleRowState) -> Set<String> {
        guard Self.compositeFeatureRuleIds.contains(row.id) else { return [] }
        return Set(row.subpatches.compactMap { subpatch in
            subpatch.desiredEnabled == subpatch.appliedEnabled ? nil : subpatch.id
        })
    }

    private func alternativeGroups(forSubpatchIds ids: Set<String>, ruleId: String) -> Set<String> {
        guard let rule = BinaryPatchRuleCatalog.rule(id: ruleId) else { return [] }
        return Set(rule.replacements.compactMap { replacement in
            let subpatchId = Self.subpatchId(forAlternativeGroup: replacement.alternativeGroup, ruleId: ruleId)
            return ids.contains(subpatchId) ? replacement.alternativeGroup : nil
        })
    }

    private func subpatchIds(forAlternativeGroups groups: Set<String>?, ruleId: String) -> Set<String>? {
        guard let groups else { return nil }
        return Set(groups.map { Self.subpatchId(forAlternativeGroup: $0, ruleId: ruleId) })
    }

    private static var customAccountRule: BinaryPatchRule {
        BinaryPatchRule(
            id: customAccountFeatureRuleId,
            title: "Custom account settings",
            methodName: "Patchgram runtime account customizations",
            constructorId: "custom-account-settings",
            kind: .runtimeMemory,
            summary: "Groups local account customization patches into one Patchgram runtime feature.",
            disabledBehavior: "Disables the selected local account customization subpatches.",
            riskNote: "These are local client-side display patches. Server-side Telegram account data is unchanged.",
            supportedBuildNote: "Telegram Desktop 6.8.x arm64.",
            replacements: [],
            category: .accounts
        )
    }

    private func customAccountStatus() -> BinaryRuleStatus {
        let applied = appliedCustomAccountSubpatchIds
        let desired = desiredCustomAccountSubpatchIds
        let state: RuleApplicationState
        let detail: String
        let internalStatuses = Self.customAccountSubpatchDefinitions.compactMap { definition in
            definition.internalRuleId.flatMap { latestStatusByRuleId[$0] }
        }
        if !internalStatuses.isEmpty,
           internalStatuses.allSatisfy({ $0.state == .unavailable }) {
            state = .unavailable
            detail = "No app selected."
        } else if applied.isEmpty {
            state = .notApplied
            detail = "No custom account subpatches are recorded as applied."
        } else if !desired.isEmpty, applied != desired {
            state = .partial
            detail = "Some custom account subpatches differ from the selected state."
        } else {
            state = .applied
            detail = "\(applied.count) custom account subpatches are recorded as applied."
        }
        return BinaryRuleStatus(rule: Self.customAccountRule, state: state, detail: detail)
    }

    private func reconcileCustomAccountSubpatchesFromStatuses() {
        var reconciled = appliedCustomAccountSubpatchIds
        for definition in Self.customAccountSubpatchDefinitions {
            guard let ruleId = definition.internalRuleId,
                  let status = latestStatusByRuleId[ruleId] else {
                continue
            }
            if ruleId == Self.selfIdentityOverrideRuleId {
                if !status.state.isEnabled {
                    reconciled.remove(definition.id)
                }
                continue
            }
            if status.state.isEnabled {
                reconciled.insert(definition.id)
            } else {
                reconciled.remove(definition.id)
            }
        }
        let selfIdentityDefinitions = Set(Self.customAccountSubpatchDefinitions.compactMap { definition -> String? in
            definition.internalRuleId == Self.selfIdentityOverrideRuleId ? definition.id : nil
        })
        if latestStatusByRuleId[Self.selfIdentityOverrideRuleId]?.state.isEnabled == true,
           reconciled.intersection(selfIdentityDefinitions).isEmpty,
           appliedCustomAccountSubpatchIds.intersection(selfIdentityDefinitions).isEmpty {
            reconciled.formUnion(selfIdentityDefinitions)
        }
        if reconciled != appliedCustomAccountSubpatchIds {
            appliedCustomAccountSubpatchIds = reconciled
            storeCustomAccountSubpatchIds(reconciled, key: Self.customAccountAppliedSubpatchIdsKey)
        }
        pendingConfigSubpatchIds = pendingConfigSubpatchIds.filter {
            desiredCustomAccountSubpatchIds.contains($0) || appliedCustomAccountSubpatchIds.contains($0)
        }
        if desiredCustomAccountSubpatchIds.isEmpty, !appliedCustomAccountSubpatchIds.isEmpty {
            desiredCustomAccountSubpatchIds = appliedCustomAccountSubpatchIds
            storeCustomAccountSubpatchIds(desiredCustomAccountSubpatchIds, key: Self.customAccountDesiredSubpatchIdsKey)
        }
    }

    private func markCustomAccountSubpatches(
        for ruleId: String,
        enabled: Bool,
        enabledAlternativeGroups: Set<String>?
    ) {
        var applied = appliedCustomAccountSubpatchIds
        let definitions = Self.customAccountSubpatchDefinitions.filter { $0.internalRuleId == ruleId }
        if enabled {
            if ruleId == Self.selfIdentityOverrideRuleId {
                let groups = enabledAlternativeGroups ?? [
                    Self.customPhoneNumberAlternativeGroup,
                    Self.customUserIdAlternativeGroup
                ]
                for definition in definitions {
                    guard let group = definition.alternativeGroup else { continue }
                    if groups.contains(group) {
                        applied.insert(definition.id)
                        pendingConfigSubpatchIds.remove(definition.id)
                    } else {
                        applied.remove(definition.id)
                    }
                }
            } else {
                for definition in definitions {
                    applied.insert(definition.id)
                    pendingConfigSubpatchIds.remove(definition.id)
                }
            }
        } else {
            for definition in definitions {
                applied.remove(definition.id)
                pendingConfigSubpatchIds.remove(definition.id)
            }
        }
        setAppliedSubpatchIds(applied, for: Self.customAccountFeatureRuleId)
    }

    private func refreshCustomAccountRow() {
        guard let index = binaryRows.firstIndex(where: { $0.id == Self.customAccountFeatureRuleId }) else { return }
        binaryRows[index].status = customAccountStatus()
        binaryRows[index].desiredEnabled = !desiredSubpatchIds(for: Self.customAccountFeatureRuleId).isEmpty
        binaryRows[index].subpatches = subpatchRows(for: binaryRows[index].status)
    }

    private static func subpatchDefinitions(for ruleId: String) -> [BinaryCompositeSubpatchDefinition] {
        switch ruleId {
        case customAccountFeatureRuleId:
            return customAccountSubpatchDefinitions
        case appConfigFeatureRuleId:
            return appConfigSubpatchDefinitions
        case messageSettingsFeatureRuleId:
            return messageSettingsSubpatchDefinitions
        case adsFeatureRuleId:
            return adsSubpatchDefinitions
        default:
            return []
        }
    }

    private func desiredSubpatchIds(for ruleId: String) -> Set<String> {
        switch ruleId {
        case Self.customAccountFeatureRuleId:
            return desiredCustomAccountSubpatchIds
        case Self.appConfigFeatureRuleId:
            return desiredAppConfigSubpatchIds
        case Self.messageSettingsFeatureRuleId:
            return desiredMessageSettingsSubpatchIds
        case Self.adsFeatureRuleId:
            return desiredAdsSubpatchIds
        default:
            return []
        }
    }

    private func appliedSubpatchIds(for ruleId: String) -> Set<String> {
        switch ruleId {
        case Self.customAccountFeatureRuleId:
            return appliedCustomAccountSubpatchIds
        case Self.appConfigFeatureRuleId:
            return appliedAppConfigSubpatchIds
        case Self.messageSettingsFeatureRuleId:
            return appliedMessageSettingsSubpatchIds
        case Self.adsFeatureRuleId:
            return appliedAdsSubpatchIds
        default:
            return []
        }
    }

    private func setDesiredSubpatchIds(_ ids: Set<String>, for ruleId: String) {
        switch ruleId {
        case Self.customAccountFeatureRuleId:
            desiredCustomAccountSubpatchIds = ids
            storeCustomAccountSubpatchIds(ids, key: Self.customAccountDesiredSubpatchIdsKey)
        case Self.appConfigFeatureRuleId:
            desiredAppConfigSubpatchIds = ids
            storeAppConfigSubpatchIds(ids, key: Self.appConfigDesiredSubpatchIdsKey)
        case Self.messageSettingsFeatureRuleId:
            desiredMessageSettingsSubpatchIds = ids
            storeMessageSettingsSubpatchIds(ids, key: Self.messageSettingsDesiredSubpatchIdsKey)
        case Self.adsFeatureRuleId:
            desiredAdsSubpatchIds = ids
            storeAdsSubpatchIds(ids, key: Self.adsDesiredSubpatchIdsKey)
        default:
            break
        }
    }

    private func setAppliedSubpatchIds(_ ids: Set<String>, for ruleId: String) {
        switch ruleId {
        case Self.customAccountFeatureRuleId:
            appliedCustomAccountSubpatchIds = ids
            storeCustomAccountSubpatchIds(ids, key: Self.customAccountAppliedSubpatchIdsKey)
        case Self.appConfigFeatureRuleId:
            appliedAppConfigSubpatchIds = ids
            storeAppConfigSubpatchIds(ids, key: Self.appConfigAppliedSubpatchIdsKey)
        case Self.messageSettingsFeatureRuleId:
            appliedMessageSettingsSubpatchIds = ids
            storeMessageSettingsSubpatchIds(ids, key: Self.messageSettingsAppliedSubpatchIdsKey)
        case Self.adsFeatureRuleId:
            appliedAdsSubpatchIds = ids
            storeAdsSubpatchIds(ids, key: Self.adsAppliedSubpatchIdsKey)
        default:
            break
        }
    }

    private static func subpatchId(forAlternativeGroup group: String, ruleId: String) -> String {
        if ruleId == messageSettingsFeatureRuleId {
            if group == "messages.typing.disable" {
                return "typing"
            }
            if group.hasPrefix("messages.read_receipts.") {
                return "read_receipts"
            }
            if group == "messages.drafts.local_only" {
                return "local_drafts"
            }
            if group == "messages.scheduled_send.local" {
                return "scheduled_send"
            }
            if group == Self.messageFactCheckAlternativeGroup {
                return Self.messageFactCheckSubpatchId
            }
            if group == "messages.noforwards.allow_copy" {
                return "noforwards_copy"
            }
            if group == "messages.ttl.disable" {
                return "disable_ttl"
            }
        }
        if ruleId == adsFeatureRuleId {
            return group.hasPrefix("ads.proxy_sponsor.") || group == "ads.proxy_sponsor.disable"
                ? "proxy_sponsor"
                : "telegram_ads"
        }
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

    private static func loadBinaryParameterValues() -> [String: UInt64] {
        Dictionary(uniqueKeysWithValues: BinaryPatchRuleCatalog.rules.compactMap { rule in
            guard let parameter = rule.parameter else { return nil }
            let key = binaryParameterDefaultsPrefix + rule.id
            let saved = UserDefaults.standard.string(forKey: key).flatMap(UInt64.init)
            return (rule.id, saved ?? parameter.defaultValue)
        })
    }

    private static func loadBotVerificationConfigs() -> [String: BotVerificationPatchConfig] {
        let decoder = JSONDecoder()
        return Dictionary(uniqueKeysWithValues: BinaryPatchRuleCatalog.rules.compactMap { rule in
            guard rule.kind == .botVerification else { return nil }
            let key = botVerificationDefaultsPrefix + rule.id
            let saved = UserDefaults.standard
                .data(forKey: key)
                .flatMap { try? decoder.decode(BotVerificationPatchConfig.self, from: $0) }
            return (rule.id, (saved ?? BotVerificationPatchConfig.defaultConfig).normalized)
        })
    }

    private static func loadBotVerificationUserPresets() -> [BotVerificationUserPreset] {
        let decoder = JSONDecoder()
        guard let data = try? Data(contentsOf: botVerificationUserPresetsURL),
              let presets = try? decoder.decode([BotVerificationUserPreset].self, from: data) else {
            return []
        }
        var seen = Set<String>()
        return presets.compactMap { preset in
            let title = preset.normalizedTitle
            let description = preset.normalizedDescription
            guard !title.isEmpty, preset.customEmojiId > 0, !description.isEmpty else { return nil }
            let signature = "\(preset.customEmojiId)\n\(description)"
            guard seen.insert(signature).inserted else { return nil }
            return BotVerificationUserPreset(
                id: preset.id,
                title: title,
                customEmojiId: preset.customEmojiId,
                description: description
            )
        }
    }

    private static func loadCustomLevelRatingConfigs() -> [String: CustomLevelRatingPatchConfig] {
        let decoder = JSONDecoder()
        return Dictionary(uniqueKeysWithValues: BinaryPatchRuleCatalog.rules.compactMap { rule in
            guard rule.kind == .customLevelRating else { return nil }
            let key = customLevelRatingDefaultsPrefix + rule.id
            let saved = UserDefaults.standard
                .data(forKey: key)
                .flatMap { try? decoder.decode(CustomLevelRatingPatchConfig.self, from: $0) }
            return (rule.id, (saved ?? CustomLevelRatingPatchConfig.defaultConfig).normalized)
        })
    }

    private static func loadSelfIdentityConfigs() -> [String: SelfIdentityPatchConfig] {
        let decoder = JSONDecoder()
        return Dictionary(uniqueKeysWithValues: BinaryPatchRuleCatalog.rules.compactMap { rule in
            guard rule.kind == .selfIdentityOverride else { return nil }
            let key = selfIdentityDefaultsPrefix + rule.id
            let saved = UserDefaults.standard
                .data(forKey: key)
                .flatMap { try? decoder.decode(SelfIdentityPatchConfig.self, from: $0) }
            return (rule.id, (saved ?? SelfIdentityPatchConfig.defaultConfig).normalized)
        })
    }

    private static func loadLocalPersonalChannelConfigs() -> [String: LocalPersonalChannelPatchConfig] {
        let decoder = JSONDecoder()
        return Dictionary(uniqueKeysWithValues: BinaryPatchRuleCatalog.rules.compactMap { rule in
            guard rule.kind == .localPersonalChannel else { return nil }
            let key = localPersonalChannelDefaultsPrefix + rule.id
            let saved = UserDefaults.standard
                .data(forKey: key)
                .flatMap { try? decoder.decode(LocalPersonalChannelPatchConfig.self, from: $0) }
            return (rule.id, (saved ?? LocalPersonalChannelPatchConfig.defaultConfig).normalized)
        })
    }

    private static func loadFragmentPhoneConfigs() -> [String: FragmentPhonePatchConfig] {
        let decoder = JSONDecoder()
        return Dictionary(uniqueKeysWithValues: BinaryPatchRuleCatalog.rules.compactMap { rule in
            guard rule.kind == .fragmentPhone else { return nil }
            let key = fragmentPhoneDefaultsPrefix + rule.id
            let saved = UserDefaults.standard
                .data(forKey: key)
                .flatMap { try? decoder.decode(FragmentPhonePatchConfig.self, from: $0) }
            return (rule.id, (saved ?? FragmentPhonePatchConfig.defaultConfig).normalized)
        })
    }

    private static func loadCustomListUsernamesConfigs() -> [String: CustomListUsernamesPatchConfig] {
        let decoder = JSONDecoder()
        return Dictionary(uniqueKeysWithValues: BinaryPatchRuleCatalog.rules.compactMap { rule in
            guard rule.kind == .customListUsernames else { return nil }
            let key = customListUsernamesDefaultsPrefix + rule.id
            let saved = UserDefaults.standard
                .data(forKey: key)
                .flatMap { try? decoder.decode(CustomListUsernamesPatchConfig.self, from: $0) }
            return (rule.id, (saved ?? CustomListUsernamesPatchConfig.defaultConfig).normalized)
        })
    }

    private static func loadMessageFactCheckConfigs() -> [String: MessageFactCheckPatchConfig] {
        let decoder = JSONDecoder()
        guard let rule = BinaryPatchRuleCatalog.rule(id: messageSettingsFeatureRuleId) else { return [:] }
        let key = messageFactCheckDefaultsPrefix + rule.id
        let saved = UserDefaults.standard
            .data(forKey: key)
            .flatMap { try? decoder.decode(MessageFactCheckPatchConfig.self, from: $0) }
        return [rule.id: (saved ?? MessageFactCheckPatchConfig.defaultConfig).normalized]
    }

    private static func loadCustomAccountSubpatchIds(key: String, defaultValue: Set<String>) -> Set<String> {
        loadSubpatchIds(key: key, knownIds: Set(customAccountSubpatchDefinitions.map(\.id)), defaultValue: defaultValue)
    }

    private static func loadAppConfigSubpatchIds(key: String, defaultValue: Set<String>) -> Set<String> {
        loadSubpatchIds(key: key, knownIds: Set(appConfigSubpatchDefinitions.map(\.id)), defaultValue: defaultValue)
    }

    private static func loadMessageSettingsSubpatchIds(key: String, defaultValue: Set<String>) -> Set<String> {
        loadSubpatchIds(key: key, knownIds: Set(messageSettingsSubpatchDefinitions.map(\.id)), defaultValue: defaultValue)
    }

    private static func loadAdsSubpatchIds(key: String, defaultValue: Set<String>) -> Set<String> {
        loadSubpatchIds(key: key, knownIds: Set(adsSubpatchDefinitions.map(\.id)), defaultValue: defaultValue)
    }

    private static func loadSubpatchIds(key: String, knownIds: Set<String>, defaultValue: Set<String>) -> Set<String> {
        guard let saved = UserDefaults.standard.array(forKey: key) as? [String] else {
            return defaultValue
        }
        return Set(saved).intersection(knownIds)
    }

    private func storeAppConfigSubpatchIds(_ ids: Set<String>, key: String) {
        UserDefaults.standard.set(ids.sorted(), forKey: key)
    }

    private func storeCustomAccountSubpatchIds(_ ids: Set<String>, key: String) {
        UserDefaults.standard.set(ids.sorted(), forKey: key)
    }

    private func storeMessageSettingsSubpatchIds(_ ids: Set<String>, key: String) {
        UserDefaults.standard.set(ids.sorted(), forKey: key)
    }

    private func storeAdsSubpatchIds(_ ids: Set<String>, key: String) {
        UserDefaults.standard.set(ids.sorted(), forKey: key)
    }

    private func binaryParameterValuesForEngine() -> [String: UInt64] {
        Dictionary(uniqueKeysWithValues: BinaryPatchRuleCatalog.rules.compactMap { rule in
            guard rule.parameter != nil, let value = parameterValue(for: rule) else { return nil }
            return (rule.id, value)
        })
    }

    private func botVerificationConfigsForEngine() -> [String: BotVerificationPatchConfig] {
        Dictionary(uniqueKeysWithValues: BinaryPatchRuleCatalog.rules.compactMap { rule in
            guard rule.kind == .botVerification, let config = botVerificationConfig(for: rule) else { return nil }
            return (rule.id, config)
        })
    }

    private func customLevelRatingConfigsForEngine() -> [String: CustomLevelRatingPatchConfig] {
        Dictionary(uniqueKeysWithValues: BinaryPatchRuleCatalog.rules.compactMap { rule in
            guard rule.kind == .customLevelRating, let config = customLevelRatingConfig(for: rule) else { return nil }
            return (rule.id, config)
        })
    }

    private func selfIdentityConfigsForEngine() -> [String: SelfIdentityPatchConfig] {
        Dictionary(uniqueKeysWithValues: BinaryPatchRuleCatalog.rules.compactMap { rule in
            guard rule.kind == .selfIdentityOverride, let config = selfIdentityConfig(for: rule) else { return nil }
            return (rule.id, config)
        })
    }

    private func localPersonalChannelConfigsForEngine() -> [String: LocalPersonalChannelPatchConfig] {
        Dictionary(uniqueKeysWithValues: BinaryPatchRuleCatalog.rules.compactMap { rule in
            guard rule.kind == .localPersonalChannel, let config = localPersonalChannelConfig(for: rule) else { return nil }
            return (rule.id, config)
        })
    }

    private func fragmentPhoneConfigsForEngine() -> [String: FragmentPhonePatchConfig] {
        Dictionary(uniqueKeysWithValues: BinaryPatchRuleCatalog.rules.compactMap { rule in
            guard rule.kind == .fragmentPhone, let config = fragmentPhoneConfig(for: rule) else { return nil }
            return (rule.id, config)
        })
    }

    private func customListUsernamesConfigsForEngine() -> [String: CustomListUsernamesPatchConfig] {
        Dictionary(uniqueKeysWithValues: BinaryPatchRuleCatalog.rules.compactMap { rule in
            guard rule.kind == .customListUsernames, let config = customListUsernamesConfig(for: rule) else {
                return nil
            }
            return (rule.id, config)
        })
    }

    private func messageFactCheckConfigsForEngine() -> [String: MessageFactCheckPatchConfig] {
        guard let rule = BinaryPatchRuleCatalog.rule(id: Self.messageSettingsFeatureRuleId),
              let config = messageFactCheckConfig(for: rule) else {
            return [:]
        }
        return [rule.id: config]
    }

    private func parameterValue(for rule: BinaryPatchRule) -> UInt64? {
        guard let parameter = rule.parameter else { return nil }
        return binaryParameterValues[rule.id] ?? parameter.defaultValue
    }

    private func botVerificationConfig(for rule: BinaryPatchRule) -> BotVerificationPatchConfig? {
        guard rule.kind == .botVerification else { return nil }
        return (botVerificationConfigs[rule.id] ?? BotVerificationPatchConfig.defaultConfig).normalized
    }

    private func botVerificationPresetOptions(including config: BotVerificationPatchConfig? = nil) -> [BotVerificationPresetOption] {
        var options = [
            BotVerificationPresetOption(
                title: BotVerificationPreset.scaredCat.label,
                customEmojiId: BotVerificationPatchConfig.scaredCatEmojiId,
                description: BotVerificationPatchConfig.scaredCatDescription,
                isScaredCat: true
            )
        ]

        for preset in botVerificationUserPresets {
            options.append(
                BotVerificationPresetOption(
                    title: preset.normalizedTitle,
                    customEmojiId: preset.customEmojiId,
                    description: preset.normalizedDescription,
                    isScaredCat: false
                )
            )
        }

        if let config = config?.normalized,
           config.preset == .custom,
           !options.contains(where: {
               $0.customEmojiId == config.customEmojiId
                   && $0.description == config.description
           }) {
            options.append(
                BotVerificationPresetOption(
                    title: config.displayPresetLabel,
                    customEmojiId: config.customEmojiId,
                    description: config.description,
                    isScaredCat: false
                )
            )
        }

        return options
    }

    private func customLevelRatingConfig(for rule: BinaryPatchRule) -> CustomLevelRatingPatchConfig? {
        guard rule.kind == .customLevelRating else { return nil }
        return (customLevelRatingConfigs[rule.id] ?? CustomLevelRatingPatchConfig.defaultConfig).normalized
    }

    private func selfIdentityConfig(for rule: BinaryPatchRule) -> SelfIdentityPatchConfig? {
        guard rule.kind == .selfIdentityOverride else { return nil }
        return (selfIdentityConfigs[rule.id] ?? SelfIdentityPatchConfig.defaultConfig).normalized
    }

    private func localPersonalChannelConfig(for rule: BinaryPatchRule) -> LocalPersonalChannelPatchConfig? {
        guard rule.kind == .localPersonalChannel else { return nil }
        return (localPersonalChannelConfigs[rule.id] ?? LocalPersonalChannelPatchConfig.defaultConfig).normalized
    }

    private func fragmentPhoneConfig(for rule: BinaryPatchRule) -> FragmentPhonePatchConfig? {
        guard rule.kind == .fragmentPhone else { return nil }
        return (fragmentPhoneConfigs[rule.id] ?? FragmentPhonePatchConfig.defaultConfig).normalized
    }

    func customListUsernamesConfigForSettings() -> CustomListUsernamesPatchConfig {
        guard let rule = BinaryPatchRuleCatalog.rule(id: Self.customListUsernamesRuleId) else {
            return .defaultConfig
        }
        return customListUsernamesConfig(for: rule) ?? .defaultConfig
    }

    func updateCustomListUsernamesConfig(_ config: CustomListUsernamesPatchConfig) {
        guard let rule = BinaryPatchRuleCatalog.rule(id: Self.customListUsernamesRuleId) else { return }
        let normalized = config.normalized
        customListUsernamesConfigs[rule.id] = normalized
        storeCustomListUsernamesConfig(normalized, for: rule.id)
        if desiredCustomAccountSubpatchIds.contains("custom_list_usernames")
            || appliedCustomAccountSubpatchIds.contains("custom_list_usernames") {
            pendingConfigSubpatchIds.insert("custom_list_usernames")
        }
        refreshCustomAccountRow()
        statusMessage = "Custom list usernames settings saved."
    }

    private func customListUsernamesConfig(for rule: BinaryPatchRule) -> CustomListUsernamesPatchConfig? {
        guard rule.kind == .customListUsernames else { return nil }
        return (customListUsernamesConfigs[rule.id] ?? CustomListUsernamesPatchConfig.defaultConfig).normalized
    }

    private func messageFactCheckConfig(for rule: BinaryPatchRule) -> MessageFactCheckPatchConfig? {
        guard rule.id == Self.messageSettingsFeatureRuleId else { return nil }
        return (messageFactCheckConfigs[rule.id] ?? MessageFactCheckPatchConfig.defaultConfig).normalized
    }

    private func storeBotVerificationConfig(_ config: BotVerificationPatchConfig, for ruleId: String) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(config.normalized) {
            UserDefaults.standard.set(data, forKey: Self.botVerificationDefaultsPrefix + ruleId)
        }
    }

    private func storeSelfIdentityConfig(_ config: SelfIdentityPatchConfig, for ruleId: String) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(config.normalized) {
            UserDefaults.standard.set(data, forKey: Self.selfIdentityDefaultsPrefix + ruleId)
        }
    }

    private func storeLocalPersonalChannelConfig(_ config: LocalPersonalChannelPatchConfig, for ruleId: String) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(config.normalized) {
            UserDefaults.standard.set(data, forKey: Self.localPersonalChannelDefaultsPrefix + ruleId)
        }
    }

    private func storeFragmentPhoneConfig(_ config: FragmentPhonePatchConfig, for ruleId: String) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(config.normalized) {
            UserDefaults.standard.set(data, forKey: Self.fragmentPhoneDefaultsPrefix + ruleId)
        }
    }

    private func storeCustomListUsernamesConfig(_ config: CustomListUsernamesPatchConfig, for ruleId: String) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(config.normalized) {
            UserDefaults.standard.set(data, forKey: Self.customListUsernamesDefaultsPrefix + ruleId)
            UserDefaults.standard.synchronize()
        }
    }

    private func storeMessageFactCheckConfig(_ config: MessageFactCheckPatchConfig, for ruleId: String) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(config.normalized) {
            UserDefaults.standard.set(data, forKey: Self.messageFactCheckDefaultsPrefix + ruleId)
        }
    }

    private static var botVerificationUserPresetsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return baseURL
            .appendingPathComponent("Patchgram", isDirectory: true)
            .appendingPathComponent(botVerificationPresetsFileName)
    }

    private func storeBotVerificationUserPresets() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        do {
            let url = Self.botVerificationUserPresetsURL
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let normalized = botVerificationUserPresets.map {
                BotVerificationUserPreset(
                    id: $0.id,
                    title: $0.normalizedTitle,
                    customEmojiId: $0.customEmojiId,
                    description: $0.normalizedDescription
                )
            }
            let data = try encoder.encode(normalized)
            try data.write(to: url, options: .atomic)
        } catch {
            statusMessage = "Could not save bot verification presets: \(error.localizedDescription)"
        }
    }

    private func migrateSavedBotVerificationConfigsIntoUserPresets() {
        var changed = false
        for config in botVerificationConfigs.values {
            let normalized = config.normalized
            guard normalized.preset == .custom,
                  normalized.customEmojiId > 0,
                  !normalized.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  normalized.customEmojiId != BotVerificationPatchConfig.scaredCatEmojiId
                    || normalized.description != BotVerificationPatchConfig.scaredCatDescription,
                  !botVerificationUserPresets.contains(where: { $0.matchesConfig(normalized) }) else {
                continue
            }
            botVerificationUserPresets.append(
                BotVerificationUserPreset(
                    id: UUID(),
                    title: normalized.displayPresetLabel == BotVerificationPreset.custom.label
                        ? "Imported verification"
                        : normalized.displayPresetLabel,
                    customEmojiId: normalized.customEmojiId,
                    description: normalized.description
                )
            )
            changed = true
        }
        if changed {
            storeBotVerificationUserPresets()
        }
    }

    private func storeCustomLevelRatingConfig(_ config: CustomLevelRatingPatchConfig, for ruleId: String) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(config.normalized) {
            UserDefaults.standard.set(data, forKey: Self.customLevelRatingDefaultsPrefix + ruleId)
        }
    }

    private func changedFiles(for rule: BinaryPatchRule) -> [String] {
        changedFiles(for: [rule])
    }

    private func changedFiles(for rules: [BinaryPatchRule]) -> [String] {
        var files = ["Contents/MacOS executable", "ad-hoc codesign"]
        if rules.contains(where: { Self.runtimeRuleIds.contains($0.id) }) {
            files.insert("Contents/Frameworks/Patchgram.dylib", at: 1)
            files.insert("Contents/Resources/PatchgramRuntime.json", at: 2)
        }
        return files
    }

    private func confirmAppConfigConflictsIfNeeded() -> Bool {
        let conflicts = binaryRows.filter {
            Self.appConfigConflictingRuleIds.contains($0.id)
                && $0.desiredEnabled
        }
        guard !conflicts.isEmpty else { return true }

        let titles = conflicts.map(\.status.rule.title).joined(separator: ", ")
        let alert = NSAlert()
        alert.messageText = "Disable conflicting feature patches?"
        alert.informativeText = "Enabling Disable Premium, Stars, TON & Gifts will turn off \(titles), because those patches need the Premium/Stars/TON surfaces that this patch removes."
        alert.addButton(withTitle: "Enable")
        alert.addButton(withTitle: "Cancel")

        guard alert.runModal() == .alertFirstButtonReturn else { return false }
        for row in conflicts {
            guard let index = binaryRows.firstIndex(where: { $0.id == row.id }) else { continue }
            binaryRows[index].desiredEnabled = false
        }
        return true
    }

    private func confirmFeaturePatchDisablesAppConfigIfNeeded(enabling rule: BinaryPatchRule) -> Bool {
        guard let appConfigRow = binaryRows.first(where: { $0.id == Self.appConfigFeatureRuleId }),
              appConfigRow.desiredEnabled else {
            return true
        }

        let alert = NSAlert()
        alert.messageText = "Disable Premium disabler?"
        alert.informativeText = "If you enable \(rule.title), Patchgram will turn off Disable Premium, Stars, TON & Gifts, because these patches conflict."
        alert.addButton(withTitle: "Enable")
        alert.addButton(withTitle: "Cancel")

        guard alert.runModal() == .alertFirstButtonReturn else { return false }
        if let index = binaryRows.firstIndex(where: { $0.id == Self.appConfigFeatureRuleId }) {
            binaryRows[index].desiredEnabled = false
            desiredAppConfigSubpatchIds = []
            storeAppConfigSubpatchIds(desiredAppConfigSubpatchIds, key: Self.appConfigDesiredSubpatchIdsKey)
            binaryRows[index].subpatches = subpatchRows(for: binaryRows[index].status)
        }
        statusMessage = "\(rule.title) will disable Disable Premium, Stars, TON & Gifts on apply."
        return true
    }

    private func promptForParameterIfNeeded(for rule: BinaryPatchRule, actionTitle: String) -> UInt64? {
        guard let parameter = rule.parameter else { return nil }
        let current = parameterValue(for: rule) ?? parameter.defaultValue
        let alert = NSAlert()
        alert.messageText = rule.title
        alert.informativeText = parameter.prompt
        alert.addButton(withTitle: actionTitle)
        alert.addButton(withTitle: "Cancel")

        if !parameter.choiceGroups.isEmpty {
            let selectedChoices = parameter.groupedChoices(for: current)
                ?? parameter.groupedChoices(for: parameter.defaultValue)
                ?? []
            let labelWidth: CGFloat = 76
            let popupWidth: CGFloat = 224
            let rowHeight: CGFloat = 28
            let rowSpacing: CGFloat = 8
            let width = labelWidth + 12 + popupWidth
            let height = CGFloat(parameter.choiceGroups.count) * rowHeight
                + CGFloat(max(parameter.choiceGroups.count - 1, 0)) * rowSpacing
            let container = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))

            var popups: [NSPopUpButton] = []
            for (groupIndex, group) in parameter.choiceGroups.enumerated() {
                let y = height - CGFloat(groupIndex + 1) * rowHeight - CGFloat(groupIndex) * rowSpacing

                let label = NSTextField(labelWithString: group.title + ":")
                label.alignment = .right
                label.frame = NSRect(x: 0, y: y + 3, width: labelWidth, height: 20)

                let popup = NSPopUpButton(
                    frame: NSRect(x: labelWidth + 12, y: y, width: popupWidth, height: rowHeight),
                    pullsDown: false
                )
                for choice in group.choices {
                    popup.addItem(withTitle: choice.label)
                    popup.lastItem?.representedObject = NSNumber(value: choice.value)
                }
                if selectedChoices.indices.contains(groupIndex),
                   let index = group.choices.firstIndex(of: selectedChoices[groupIndex]) {
                    popup.selectItem(at: index)
                }

                container.addSubview(label)
                container.addSubview(popup)
                popups.append(popup)
            }

            alert.accessoryView = container
            guard alert.runModal() == .alertFirstButtonReturn else { return nil }
            return popups.reduce(UInt64(0)) { result, popup in
                result + ((popup.selectedItem?.representedObject as? NSNumber)?.uint64Value ?? 0)
            }
        }

        if !parameter.choices.isEmpty {
            let popup = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 260, height: 26), pullsDown: false)
            for choice in parameter.choices {
                popup.addItem(withTitle: choice.label)
                popup.lastItem?.representedObject = NSNumber(value: choice.value)
            }
            if let index = parameter.choices.firstIndex(where: { $0.value == current }) {
                popup.selectItem(at: index)
            }
            alert.accessoryView = popup
            guard alert.runModal() == .alertFirstButtonReturn else { return nil }
            return (popup.selectedItem?.representedObject as? NSNumber)?.uint64Value ?? parameter.defaultValue
        }

        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
        field.stringValue = String(current)
        field.placeholderString = parameter.unit
        alert.accessoryView = field

        guard alert.runModal() == .alertFirstButtonReturn else { return nil }
        let text = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = UInt64(text), value >= parameter.minimumValue, value <= parameter.maximumValue else {
            statusMessage = "Enter a value from \(parameter.minimumValue) to \(parameter.maximumValue) \(parameter.unit)."
            return nil
        }
        return value
    }

    private func promptForBotVerificationConfig(
        for rule: BinaryPatchRule,
        actionTitle: String
    ) -> BotVerificationPatchConfig? {
        guard rule.kind == .botVerification else { return nil }
        let current = botVerificationConfig(for: rule) ?? BotVerificationPatchConfig.defaultConfig
        let presetOptions = botVerificationPresetOptions(including: current)
        let alert = NSAlert()
        alert.messageText = rule.title
        alert.informativeText = "Choose who receives the local bot verification and which verification preset to use."
        alert.addButton(withTitle: actionTitle)
        alert.addButton(withTitle: "Cancel")

        let labelWidth: CGFloat = 116
        let controlX = labelWidth + 12
        let controlWidth: CGFloat = 260
        let rowHeight: CGFloat = 26
        let rowGap: CGFloat = 10
        let width = controlX + controlWidth
        let height: CGFloat = rowHeight * 2 + rowGap
        let container = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))

        func addLabel(_ title: String, row: Int) -> NSTextField {
            let y = height - CGFloat(row + 1) * rowHeight - CGFloat(row) * rowGap + 3
            let label = NSTextField(labelWithString: title + ":")
            label.alignment = .right
            label.frame = NSRect(x: 0, y: y, width: labelWidth, height: 20)
            container.addSubview(label)
            return label
        }

        func rowFrame(_ row: Int) -> NSRect {
            let y = height - CGFloat(row + 1) * rowHeight - CGFloat(row) * rowGap
            return NSRect(x: controlX, y: y, width: controlWidth, height: rowHeight)
        }

        _ = addLabel("Mode", row: 0)
        let targetPopup = NSPopUpButton(frame: rowFrame(0), pullsDown: false)
        for mode in BotVerificationTargetMode.allCases {
            targetPopup.addItem(withTitle: mode.label)
            targetPopup.lastItem?.representedObject = mode.rawValue
        }
        if let index = BotVerificationTargetMode.allCases.firstIndex(of: current.targetMode) {
            targetPopup.selectItem(at: index)
        }
        container.addSubview(targetPopup)

        _ = addLabel("Verification", row: 1)
        let presetPopup = NSPopUpButton(frame: rowFrame(1), pullsDown: false)
        for (index, option) in presetOptions.enumerated() {
            presetPopup.addItem(withTitle: option.title)
            presetPopup.lastItem?.representedObject = NSNumber(value: index)
        }
        if let index = presetOptions.firstIndex(where: { option in
            option.customEmojiId == current.customEmojiId
                && option.description == current.description
        }) {
            presetPopup.selectItem(at: index)
        }
        container.addSubview(presetPopup)

        alert.accessoryView = container
        guard alert.runModal() == .alertFirstButtonReturn else { return nil }

        let targetRaw = targetPopup.selectedItem?.representedObject as? String
        let targetMode = targetRaw.flatMap(BotVerificationTargetMode.init(rawValue:)) ?? .all
        let presetIndex = (presetPopup.selectedItem?.representedObject as? NSNumber)?.intValue ?? 0
        let selectedOption = presetOptions.indices.contains(presetIndex)
            ? presetOptions[presetIndex]
            : presetOptions[0]

        return BotVerificationPatchConfig(
            targetMode: targetMode,
            preset: selectedOption.configPreset,
            customEmojiId: selectedOption.customEmojiId,
            description: selectedOption.description,
            presetTitle: selectedOption.isScaredCat ? nil : selectedOption.title
        ).normalized
    }

    private func promptForCustomLevelRatingConfig(
        for rule: BinaryPatchRule,
        actionTitle: String
    ) -> CustomLevelRatingPatchConfig? {
        guard rule.kind == .customLevelRating else { return nil }
        let current = customLevelRatingConfig(for: rule) ?? CustomLevelRatingPatchConfig.defaultConfig
        let alert = NSAlert()
        alert.messageText = rule.title
        alert.informativeText = "Choose who receives the local rating and enter level/rating values."
        alert.addButton(withTitle: actionTitle)
        alert.addButton(withTitle: "Cancel")

        let labelWidth: CGFloat = 152
        let controlX = labelWidth + 12
        let controlWidth: CGFloat = 220
        let rowHeight: CGFloat = 26
        let rowGap: CGFloat = 9
        let width = controlX + controlWidth
        let height: CGFloat = rowHeight * 5 + rowGap * 4
        let container = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))

        func addLabel(_ title: String, row: Int) {
            let y = height - CGFloat(row + 1) * rowHeight - CGFloat(row) * rowGap + 3
            let label = NSTextField(labelWithString: title + ":")
            label.alignment = .right
            label.frame = NSRect(x: 0, y: y, width: labelWidth, height: 20)
            container.addSubview(label)
        }

        func rowFrame(_ row: Int) -> NSRect {
            let y = height - CGFloat(row + 1) * rowHeight - CGFloat(row) * rowGap
            return NSRect(x: controlX, y: y, width: controlWidth, height: rowHeight)
        }

        addLabel("Mode", row: 0)
        let targetPopup = NSPopUpButton(frame: rowFrame(0), pullsDown: false)
        for mode in BotVerificationTargetMode.allCases {
            targetPopup.addItem(withTitle: mode.label)
            targetPopup.lastItem?.representedObject = mode.rawValue
        }
        if let index = BotVerificationTargetMode.allCases.firstIndex(of: current.targetMode) {
            targetPopup.selectItem(at: index)
        }
        container.addSubview(targetPopup)

        let fields: [(title: String, value: Int32)] = [
            ("level", current.level),
            ("rating", current.rating),
            ("current_level_rating", current.currentLevelRating),
            ("next_level_rating", current.nextLevelRating)
        ]
        var textFields: [NSTextField] = []
        for (index, field) in fields.enumerated() {
            let row = index + 1
            addLabel(field.title, row: row)
            let textField = NSTextField(frame: rowFrame(row))
            textField.stringValue = String(field.value)
            textField.placeholderString = "0"
            container.addSubview(textField)
            textFields.append(textField)
        }

        alert.accessoryView = container
        guard alert.runModal() == .alertFirstButtonReturn else { return nil }

        func int32Value(_ field: NSTextField, name: String, minimum: Int32) -> Int32? {
            let text = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let value = Int32(text), value >= minimum else {
                statusMessage = "Enter a valid \(name)."
                return nil
            }
            return value
        }

        let targetRaw = targetPopup.selectedItem?.representedObject as? String
        let targetMode = targetRaw.flatMap(BotVerificationTargetMode.init(rawValue:)) ?? .all
        guard let level = int32Value(textFields[0], name: "level", minimum: Int32.min),
              let rating = int32Value(textFields[1], name: "rating", minimum: 0),
              let currentLevelRating = int32Value(textFields[2], name: "current_level_rating", minimum: 0),
              let nextLevelRating = int32Value(textFields[3], name: "next_level_rating", minimum: 0) else {
            return nil
        }

        return CustomLevelRatingPatchConfig(
            targetMode: targetMode,
            level: level,
            rating: rating,
            currentLevelRating: currentLevelRating,
            nextLevelRating: nextLevelRating
        ).normalized
    }

    private func promptForSelfIdentityConfig(
        for rule: BinaryPatchRule,
        actionTitle: String
    ) -> SelfIdentityPatchConfig? {
        guard rule.kind == .selfIdentityOverride else { return nil }
        let current = selfIdentityConfig(for: rule) ?? SelfIdentityPatchConfig.defaultConfig
        let alert = NSAlert()
        alert.messageText = rule.title
        alert.informativeText = "Enter local phone and user id values. Leave a field empty to keep Telegram's original value."
        alert.addButton(withTitle: actionTitle)
        alert.addButton(withTitle: "Cancel")

        let labelWidth: CGFloat = 92
        let controlX = labelWidth + 12
        let controlWidth: CGFloat = 260
        let rowHeight: CGFloat = 26
        let rowGap: CGFloat = 10
        let width = controlX + controlWidth
        let height: CGFloat = rowHeight * 2 + rowGap
        let container = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))

        func addLabel(_ title: String, row: Int) {
            let y = height - CGFloat(row + 1) * rowHeight - CGFloat(row) * rowGap + 3
            let label = NSTextField(labelWithString: title + ":")
            label.alignment = .right
            label.frame = NSRect(x: 0, y: y, width: labelWidth, height: 20)
            container.addSubview(label)
        }

        func rowFrame(_ row: Int) -> NSRect {
            let y = height - CGFloat(row + 1) * rowHeight - CGFloat(row) * rowGap
            return NSRect(x: controlX, y: y, width: controlWidth, height: rowHeight)
        }

        addLabel("Phone", row: 0)
        let phoneField = NSTextField(frame: rowFrame(0))
        phoneField.stringValue = current.phone
        phoneField.placeholderString = "+10000000000"
        container.addSubview(phoneField)

        addLabel("User id", row: 1)
        let userIdField = NSTextField(frame: rowFrame(1))
        userIdField.stringValue = current.userId
        userIdField.placeholderString = "Original"
        container.addSubview(userIdField)

        alert.accessoryView = container
        guard alert.runModal() == .alertFirstButtonReturn else { return nil }

        let phone = phoneField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let userIdText = userIdField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard phone.count <= 64 else {
            statusMessage = "Enter a phone value up to 64 characters."
            return nil
        }
        if !userIdText.isEmpty,
           (UInt64(userIdText) == nil || UInt64(userIdText)! > 0x0000ffffffffffff) {
            statusMessage = "Enter a valid user id from 0 to 281474976710655."
            return nil
        }

        return SelfIdentityPatchConfig(
            phone: phone,
            userId: userIdText,
            phoneTargetMode: current.phoneTargetMode,
            userIdTargetMode: current.userIdTargetMode
        ).normalized
    }

    private func configureCustomAccountSubpatches(_ subpatchIds: Set<String>, actionTitle: String) -> Bool {
        for definition in Self.customAccountSubpatchDefinitions where subpatchIds.contains(definition.id) {
            guard let ruleId = definition.internalRuleId,
                  let rule = BinaryPatchRuleCatalog.rule(id: ruleId) else {
                continue
            }
            switch definition.id {
            case Self.customPhoneNumberSubpatchId:
                guard promptForCustomPhoneNumber(for: rule, actionTitle: actionTitle) != nil else { return false }
            case Self.customUserIdSubpatchId:
                guard promptForCustomUserId(for: rule, actionTitle: actionTitle) != nil else { return false }
            default:
                if rule.kind == .botVerification {
                    guard let config = promptForBotVerificationConfig(for: rule, actionTitle: actionTitle) else { return false }
                    botVerificationConfigs[rule.id] = config
                    storeBotVerificationConfig(config, for: rule.id)
                } else if rule.kind == .customLevelRating {
                    guard let config = promptForCustomLevelRatingConfig(for: rule, actionTitle: actionTitle) else { return false }
                    customLevelRatingConfigs[rule.id] = config
                    storeCustomLevelRatingConfig(config, for: rule.id)
                } else if rule.kind == .localPersonalChannel {
                    guard let config = promptForLocalPersonalChannelConfig(for: rule, actionTitle: actionTitle) else { return false }
                    localPersonalChannelConfigs[rule.id] = config
                    storeLocalPersonalChannelConfig(config, for: rule.id)
                } else if rule.kind == .fragmentPhone {
                    guard let config = promptForFragmentPhoneConfig(for: rule, actionTitle: actionTitle) else { return false }
                    fragmentPhoneConfigs[rule.id] = config
                    storeFragmentPhoneConfig(config, for: rule.id)
                } else if rule.kind == .customListUsernames {
                    guard customListUsernamesConfig(for: rule)?.entries.isEmpty == false else {
                        statusMessage = "Add at least one username in Custom list usernames settings."
                        isShowingCustomListUsernamesSettings = true
                        return false
                    }
                } else if rule.parameter != nil {
                    guard let value = promptForParameterIfNeeded(for: rule, actionTitle: actionTitle) else { return false }
                    binaryParameterValues[rule.id] = value
                    UserDefaults.standard.set(String(value), forKey: Self.binaryParameterDefaultsPrefix + rule.id)
                }
            }
        }
        return true
    }

    private func configureMessageSettingsSubpatches(_ subpatchIds: Set<String>, actionTitle: String) -> Bool {
        guard subpatchIds.contains(Self.messageFactCheckSubpatchId),
              let rule = BinaryPatchRuleCatalog.rule(id: Self.messageSettingsFeatureRuleId) else {
            return true
        }
        guard let config = promptForMessageFactCheckConfig(for: rule, actionTitle: actionTitle) else { return false }
        messageFactCheckConfigs[rule.id] = config
        storeMessageFactCheckConfig(config, for: rule.id)
        return true
    }

    @discardableResult
    private func promptForCustomPhoneNumber(for rule: BinaryPatchRule, actionTitle: String) -> SelfIdentityPatchConfig? {
        guard rule.kind == .selfIdentityOverride else { return nil }
        let current = selfIdentityConfig(for: rule) ?? SelfIdentityPatchConfig.defaultConfig
        let alert = NSAlert()
        alert.messageText = "Custom phone number"
        alert.informativeText = "Enter a local phone value. Leave empty to keep Telegram's original value."
        alert.addButton(withTitle: actionTitle)
        alert.addButton(withTitle: "Cancel")

        let labelWidth: CGFloat = 72
        let controlX = labelWidth + 12
        let controlWidth: CGFloat = 260
        let rowHeight: CGFloat = 26
        let rowGap: CGFloat = 10
        let width = controlX + controlWidth
        let height: CGFloat = rowHeight * 2 + rowGap
        let container = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))

        func addLabel(_ title: String, row: Int) {
            let y = height - CGFloat(row + 1) * rowHeight - CGFloat(row) * rowGap + 3
            let label = NSTextField(labelWithString: title + ":")
            label.alignment = .right
            label.frame = NSRect(x: 0, y: y, width: labelWidth, height: 20)
            container.addSubview(label)
        }

        func rowFrame(_ row: Int) -> NSRect {
            let y = height - CGFloat(row + 1) * rowHeight - CGFloat(row) * rowGap
            return NSRect(x: controlX, y: y, width: controlWidth, height: rowHeight)
        }

        addLabel("Mode", row: 0)
        let targetPopup = NSPopUpButton(frame: rowFrame(0), pullsDown: false)
        for mode in BotVerificationTargetMode.allCases {
            targetPopup.addItem(withTitle: mode.label)
            targetPopup.lastItem?.representedObject = mode.rawValue
        }
        if let index = BotVerificationTargetMode.allCases.firstIndex(of: current.phoneTargetMode) {
            targetPopup.selectItem(at: index)
        }
        container.addSubview(targetPopup)

        addLabel("Phone", row: 1)
        let field = NSTextField(frame: rowFrame(1))
        field.stringValue = current.phone
        field.placeholderString = "+10000000000"
        container.addSubview(field)
        alert.accessoryView = container
        guard alert.runModal() == .alertFirstButtonReturn else { return nil }
        let phone = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard phone.count <= 64 else {
            statusMessage = "Enter a phone value up to 64 characters."
            return nil
        }
        let targetRaw = targetPopup.selectedItem?.representedObject as? String
        let targetMode = targetRaw.flatMap(BotVerificationTargetMode.init(rawValue:)) ?? .onlySelf
        let next = SelfIdentityPatchConfig(
            phone: phone,
            userId: current.userId,
            phoneTargetMode: targetMode,
            userIdTargetMode: current.userIdTargetMode
        ).normalized
        selfIdentityConfigs[rule.id] = next
        storeSelfIdentityConfig(next, for: rule.id)
        return next
    }

    @discardableResult
    private func promptForCustomUserId(for rule: BinaryPatchRule, actionTitle: String) -> SelfIdentityPatchConfig? {
        guard rule.kind == .selfIdentityOverride else { return nil }
        let current = selfIdentityConfig(for: rule) ?? SelfIdentityPatchConfig.defaultConfig
        let alert = NSAlert()
        alert.messageText = "Custom userID"
        alert.informativeText = "Enter a local display user id. Leave empty to keep Telegram's original value."
        alert.addButton(withTitle: actionTitle)
        alert.addButton(withTitle: "Cancel")

        let labelWidth: CGFloat = 72
        let controlX = labelWidth + 12
        let controlWidth: CGFloat = 260
        let rowHeight: CGFloat = 26
        let rowGap: CGFloat = 10
        let width = controlX + controlWidth
        let height: CGFloat = rowHeight * 2 + rowGap
        let container = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))

        func addLabel(_ title: String, row: Int) {
            let y = height - CGFloat(row + 1) * rowHeight - CGFloat(row) * rowGap + 3
            let label = NSTextField(labelWithString: title + ":")
            label.alignment = .right
            label.frame = NSRect(x: 0, y: y, width: labelWidth, height: 20)
            container.addSubview(label)
        }

        func rowFrame(_ row: Int) -> NSRect {
            let y = height - CGFloat(row + 1) * rowHeight - CGFloat(row) * rowGap
            return NSRect(x: controlX, y: y, width: controlWidth, height: rowHeight)
        }

        addLabel("Mode", row: 0)
        let targetPopup = NSPopUpButton(frame: rowFrame(0), pullsDown: false)
        for mode in BotVerificationTargetMode.allCases {
            targetPopup.addItem(withTitle: mode.label)
            targetPopup.lastItem?.representedObject = mode.rawValue
        }
        if let index = BotVerificationTargetMode.allCases.firstIndex(of: current.userIdTargetMode) {
            targetPopup.selectItem(at: index)
        }
        container.addSubview(targetPopup)

        addLabel("User id", row: 1)
        let field = NSTextField(frame: rowFrame(1))
        field.stringValue = current.userId
        field.placeholderString = "Original"
        container.addSubview(field)
        alert.accessoryView = container
        guard alert.runModal() == .alertFirstButtonReturn else { return nil }
        let userIdText = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if !userIdText.isEmpty,
           (UInt64(userIdText) == nil || UInt64(userIdText)! > 0x0000ffffffffffff) {
            statusMessage = "Enter a valid user id from 1 to 281474976710655, or leave it empty for original."
            return nil
        }
        let targetRaw = targetPopup.selectedItem?.representedObject as? String
        let targetMode = targetRaw.flatMap(BotVerificationTargetMode.init(rawValue:)) ?? .onlySelf
        let next = SelfIdentityPatchConfig(
            phone: current.phone,
            userId: userIdText,
            phoneTargetMode: current.phoneTargetMode,
            userIdTargetMode: targetMode
        ).normalized
        selfIdentityConfigs[rule.id] = next
        storeSelfIdentityConfig(next, for: rule.id)
        return next
    }

    private func promptForLocalPersonalChannelConfig(
        for rule: BinaryPatchRule,
        actionTitle: String
    ) -> LocalPersonalChannelPatchConfig? {
        guard rule.kind == .localPersonalChannel else { return nil }
        let current = localPersonalChannelConfig(for: rule) ?? LocalPersonalChannelPatchConfig.defaultConfig
        let alert = NSAlert()
        alert.messageText = rule.title
        alert.informativeText = "Enter a numeric channel id. Telegram Desktop stores the attached channel as ChannelId, so username is not accepted here."
        alert.addButton(withTitle: actionTitle)
        alert.addButton(withTitle: "Cancel")

        let labelWidth: CGFloat = 80
        let controlX = labelWidth + 12
        let controlWidth: CGFloat = 280
        let rowHeight: CGFloat = 26
        let rowGap: CGFloat = 10
        let width = controlX + controlWidth
        let height: CGFloat = rowHeight * 3 + rowGap * 2
        let container = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))

        func addLabel(_ title: String, row: Int) {
            let y = height - CGFloat(row + 1) * rowHeight - CGFloat(row) * rowGap + 3
            let label = NSTextField(labelWithString: title + ":")
            label.alignment = .right
            label.frame = NSRect(x: 0, y: y, width: labelWidth, height: 20)
            container.addSubview(label)
        }

        func rowFrame(_ row: Int) -> NSRect {
            let y = height - CGFloat(row + 1) * rowHeight - CGFloat(row) * rowGap
            return NSRect(x: controlX, y: y, width: controlWidth, height: rowHeight)
        }

        addLabel("Mode", row: 0)
        let targetPopup = NSPopUpButton(frame: rowFrame(0), pullsDown: false)
        for mode in BotVerificationTargetMode.allCases {
            targetPopup.addItem(withTitle: mode.label)
            targetPopup.lastItem?.representedObject = mode.rawValue
        }
        if let index = BotVerificationTargetMode.allCases.firstIndex(of: current.targetMode) {
            targetPopup.selectItem(at: index)
        }
        container.addSubview(targetPopup)

        addLabel("Channel", row: 1)
        let referenceField = NSTextField(frame: rowFrame(1))
        referenceField.stringValue = current.channelReference
        referenceField.placeholderString = "123456789 or -100123456789"
        container.addSubview(referenceField)

        addLabel("Post id", row: 2)
        let messageField = NSTextField(frame: rowFrame(2))
        messageField.stringValue = current.messageId == 0 ? "" : String(current.messageId)
        messageField.placeholderString = "Optional"
        container.addSubview(messageField)

        alert.accessoryView = container
        guard alert.runModal() == .alertFirstButtonReturn else { return nil }

        let reference = referenceField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !reference.isEmpty else {
            statusMessage = "Enter a channel id."
            return nil
        }
        let messageText = messageField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let messageId: Int32
        if messageText.isEmpty {
            messageId = 0
        } else if let value = Int32(messageText), value >= 0 {
            messageId = value
        } else {
            statusMessage = "Enter a valid post id, or leave it empty."
            return nil
        }
        let targetRaw = targetPopup.selectedItem?.representedObject as? String
        let targetMode = targetRaw.flatMap(BotVerificationTargetMode.init(rawValue:)) ?? .onlySelf
        let config = LocalPersonalChannelPatchConfig(
            channelReference: reference,
            messageId: messageId,
            targetMode: targetMode
        ).normalized
        guard config.channelId != nil else {
            statusMessage = "Enter a numeric channel id. Usernames are not supported for this patch."
            return nil
        }
        return config
    }

    private func promptForFragmentPhoneConfig(
        for rule: BinaryPatchRule,
        actionTitle: String
    ) -> FragmentPhonePatchConfig? {
        guard rule.kind == .fragmentPhone else { return nil }
        let current = fragmentPhoneConfig(for: rule) ?? FragmentPhonePatchConfig.defaultConfig
        let alert = NSAlert()
        alert.messageText = rule.title
        alert.informativeText = "Enter local fragment.collectibleInfo values. Purchase date accepts unix-time or HH:MM:SS dd.mm.yyyy."
        alert.addButton(withTitle: actionTitle)
        alert.addButton(withTitle: "Cancel")

        let labelWidth: CGFloat = 108
        let controlX = labelWidth + 12
        let controlWidth: CGFloat = 300
        let rowHeight: CGFloat = 26
        let rowGap: CGFloat = 8
        let width = controlX + controlWidth
        let rows = 7
        let height = CGFloat(rows) * rowHeight + CGFloat(rows - 1) * rowGap
        let container = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))

        func addLabel(_ title: String, row: Int) {
            let y = height - CGFloat(row + 1) * rowHeight - CGFloat(row) * rowGap + 3
            let label = NSTextField(labelWithString: title + ":")
            label.alignment = .right
            label.frame = NSRect(x: 0, y: y, width: labelWidth, height: 20)
            container.addSubview(label)
        }

        func rowFrame(_ row: Int) -> NSRect {
            let y = height - CGFloat(row + 1) * rowHeight - CGFloat(row) * rowGap
            return NSRect(x: controlX, y: y, width: controlWidth, height: rowHeight)
        }

        addLabel("Mode", row: 0)
        let targetPopup = NSPopUpButton(frame: rowFrame(0), pullsDown: false)
        for mode in BotVerificationTargetMode.allCases {
            targetPopup.addItem(withTitle: mode.label)
            targetPopup.lastItem?.representedObject = mode.rawValue
        }
        if let index = BotVerificationTargetMode.allCases.firstIndex(of: current.targetMode) {
            targetPopup.selectItem(at: index)
        }
        container.addSubview(targetPopup)

        addLabel("Purchase date", row: 1)
        let dateField = NSTextField(frame: rowFrame(1))
        dateField.stringValue = current.purchaseDateText
        dateField.placeholderString = "0 or 12:34:56 07.06.2026"
        container.addSubview(dateField)

        addLabel("Currency", row: 2)
        let currencyField = NSTextField(frame: rowFrame(2))
        currencyField.stringValue = current.currency
        currencyField.placeholderString = "USD"
        container.addSubview(currencyField)

        addLabel("Amount", row: 3)
        let amountField = NSTextField(frame: rowFrame(3))
        amountField.stringValue = String(current.amount)
        amountField.placeholderString = "0"
        container.addSubview(amountField)

        addLabel("Crypto currency", row: 4)
        let cryptoCurrencyField = NSTextField(frame: rowFrame(4))
        cryptoCurrencyField.stringValue = current.cryptoCurrency
        cryptoCurrencyField.placeholderString = "TON"
        container.addSubview(cryptoCurrencyField)

        addLabel("Crypto amount", row: 5)
        let cryptoAmountField = NSTextField(frame: rowFrame(5))
        cryptoAmountField.stringValue = String(current.cryptoAmount)
        cryptoAmountField.placeholderString = "0"
        container.addSubview(cryptoAmountField)

        addLabel("URL", row: 6)
        let urlField = NSTextField(frame: rowFrame(6))
        urlField.stringValue = current.url
        urlField.placeholderString = "https://fragment.com/number/..."
        container.addSubview(urlField)

        alert.accessoryView = container
        guard alert.runModal() == .alertFirstButtonReturn else { return nil }

        func int64Value(_ field: NSTextField, label: String) -> Int64? {
            let text = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return 0 }
            guard let value = Int64(text), value >= 0 else {
                statusMessage = "Enter a valid non-negative \(label)."
                return nil
            }
            return value
        }

        guard let amount = int64Value(amountField, label: "amount"),
              let cryptoAmount = int64Value(cryptoAmountField, label: "crypto amount") else {
            return nil
        }
        let targetRaw = targetPopup.selectedItem?.representedObject as? String
        let targetMode = targetRaw.flatMap(BotVerificationTargetMode.init(rawValue:)) ?? .onlySelf
        let config = FragmentPhonePatchConfig(
            targetMode: targetMode,
            purchaseDateText: dateField.stringValue,
            currency: currencyField.stringValue,
            amount: amount,
            cryptoCurrency: cryptoCurrencyField.stringValue,
            cryptoAmount: cryptoAmount,
            url: urlField.stringValue
        ).normalized
        guard config.purchaseDateUnix != nil else {
            statusMessage = "Enter purchase date as unix-time or HH:MM:SS dd.mm.yyyy."
            return nil
        }
        guard config.currency.count <= 32, config.cryptoCurrency.count <= 32 else {
            statusMessage = "Enter currency values up to 32 characters."
            return nil
        }
        guard config.url.count <= 256 else {
            statusMessage = "Enter a URL up to 256 characters."
            return nil
        }
        return config
    }

    private func promptForMessageFactCheckConfig(
        for rule: BinaryPatchRule,
        actionTitle: String
    ) -> MessageFactCheckPatchConfig? {
        guard rule.id == Self.messageSettingsFeatureRuleId else { return nil }
        let current = messageFactCheckConfig(for: rule) ?? MessageFactCheckPatchConfig.defaultConfig
        let alert = NSAlert()
        alert.messageText = "Custom Fact Check"
        alert.informativeText = "Enter the local Fact Check fields that Telegram Desktop should show under requested channel posts."
        alert.addButton(withTitle: actionTitle)
        alert.addButton(withTitle: "Cancel")

        let labelWidth: CGFloat = 82
        let controlX = labelWidth + 12
        let controlWidth: CGFloat = 300
        let rowHeight: CGFloat = 26
        let rowGap: CGFloat = 8
        let rows = 4
        let width = controlX + controlWidth
        let height = CGFloat(rows) * rowHeight + CGFloat(rows - 1) * rowGap
        let container = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))

        func addLabel(_ title: String, row: Int) {
            let y = height - CGFloat(row + 1) * rowHeight - CGFloat(row) * rowGap + 3
            let label = NSTextField(labelWithString: title + ":")
            label.alignment = .right
            label.frame = NSRect(x: 0, y: y, width: labelWidth, height: 20)
            container.addSubview(label)
        }

        func rowFrame(_ row: Int) -> NSRect {
            let y = height - CGFloat(row + 1) * rowHeight - CGFloat(row) * rowGap
            return NSRect(x: controlX, y: y, width: controlWidth, height: rowHeight)
        }

        addLabel("Text", row: 0)
        let textField = NSTextField(frame: rowFrame(0))
        textField.stringValue = current.text
        textField.placeholderString = "Fact check text"
        container.addSubview(textField)

        addLabel("Country", row: 1)
        let countryField = NSTextField(frame: rowFrame(1))
        countryField.stringValue = current.country
        countryField.placeholderString = "Optional, for example US"
        container.addSubview(countryField)

        addLabel("Hash", row: 2)
        let hashField = NSTextField(frame: rowFrame(2))
        hashField.stringValue = String(current.hash)
        hashField.placeholderString = "0"
        container.addSubview(hashField)

        let needCheckButton = NSButton(checkboxWithTitle: "Need check", target: nil, action: nil)
        needCheckButton.frame = rowFrame(3)
        needCheckButton.state = current.needCheck ? .on : .off
        container.addSubview(needCheckButton)

        alert.accessoryView = container
        guard alert.runModal() == .alertFirstButtonReturn else { return nil }

        let hashText = hashField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let hash = hashText.isEmpty ? 0 : Int64(hashText) else {
            statusMessage = "Enter a valid Fact Check hash."
            return nil
        }

        let config = MessageFactCheckPatchConfig(
            text: textField.stringValue,
            country: countryField.stringValue,
            hash: hash,
            needCheck: needCheckButton.state == .on
        ).normalized
        guard !config.text.isEmpty else {
            statusMessage = "Enter a Fact Check text."
            return nil
        }
        guard config.text.utf8.count <= 1024 else {
            statusMessage = "Enter a Fact Check text up to 1024 bytes."
            return nil
        }
        guard config.country.utf8.count <= 256 else {
            statusMessage = "Enter a Fact Check country up to 256 bytes."
            return nil
        }
        return config
    }

    private static func durationString(since start: Date) -> String {
        String(format: "%.3fs", Date().timeIntervalSince(start))
    }
}
