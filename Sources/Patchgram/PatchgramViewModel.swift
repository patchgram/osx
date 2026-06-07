import AppKit
import Foundation
import PatchgramCore
import SwiftUI
import UniformTypeIdentifiers

struct BinaryRuleRowState: Identifiable, Hashable {
    private static let dylibRuleIds: Set<String> = [
        "binary.visual.bot_verification",
        "binary.visual.custom_level_rating",
        "binary.visual.hide_self_phone",
        "binary.visual.peer_badge",
        "binary.visual.no_premium_anim",
        "binary.visual.disable_spoilers",
        "binary.presence.force_offline",
        "binary.privacy.no_phone_on_add",
        "binary.links.open_without_warning",
        "binary.inline.callback_hover",
        "binary.display.custom_ton",
        "binary.display.custom_stars",
        "binary.activity.block_typing",
        "binary.read_receipts.block_history_read",
        "binary.messages.settings",
        "binary.premium.local",
        "binary.visual.sensitive_blur",
        "binary.stories.hide",
        "binary.ads.disable_sponsored"
    ]

    var id: String { status.id }
    var status: BinaryRuleStatus
    var desiredEnabled: Bool
    var parameterValue: UInt64?
    var botVerificationConfig: BotVerificationPatchConfig?
    var customLevelRatingConfig: CustomLevelRatingPatchConfig?
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
        guard let parameter = status.rule.parameter, let parameterValue else { return nil }
        return parameter.displayValue(parameterValue)
    }

    var canUpdateAppliedPatch: Bool {
        (desiredEnabled && status.state == .partial)
            || (status.state == .applied && (status.rule.parameter != nil
                || status.rule.kind == .botVerification
                || status.rule.kind == .customLevelRating))
    }

    var updateButtonTitle: String? {
        guard canUpdateAppliedPatch else { return nil }
        return (status.rule.parameter == nil
            && status.rule.kind != .botVerification
            && status.rule.kind != .customLevelRating) ? "Update" : "Change"
    }

    var needsApply: Bool {
        if subpatches.contains(where: { $0.desiredEnabled != $0.appliedEnabled }) {
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
        var parts = ["\(selected)/\(total) subpatches"]
        if turningOn > 0 {
            parts.append("+\(turningOn)")
        }
        if turningOff > 0 {
            parts.append("-\(turningOff)")
        }
        return parts.joined(separator: " ")
    }
}

struct BinarySubpatchRowState: Identifiable, Hashable {
    let id: String
    let title: String
    var desiredEnabled: Bool
    var appliedEnabled: Bool
}

private struct BinaryCompositeSubpatchDefinition: Identifiable, Hashable {
    let id: String
    let title: String
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

struct WriteAccessAlert: Identifiable, Equatable {
    let id = UUID()
    let message: String
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
    @Published var binaryParameterValues: [String: UInt64] = [:]
    @Published var botVerificationConfigs: [String: BotVerificationPatchConfig] = [:]
    @Published var botVerificationUserPresets: [BotVerificationUserPreset] = []
    @Published var isShowingBotVerificationSettings = false
    @Published var customLevelRatingConfigs: [String: CustomLevelRatingPatchConfig] = [:]
    @Published var writeAccessAlert: WriteAccessAlert?

    private let binaryEngine = BinaryPatchEngine()
    private static let binaryParameterDefaultsPrefix = "Patchgram.binaryParameter."
    private static let botVerificationDefaultsPrefix = "Patchgram.botVerificationConfig."
    private static let customLevelRatingDefaultsPrefix = "Patchgram.customLevelRatingConfig."
    private static let botVerificationPresetsFileName = "BotVerificationPresets.json"
    private static let appConfigDesiredSubpatchIdsKey = "Patchgram.appConfigSubpatches.desired"
    private static let appConfigAppliedSubpatchIdsKey = "Patchgram.appConfigSubpatches.applied"
    private static let appConfigFeatureRuleId = "binary.config.disable_monetization"
    private static let messageSettingsDesiredSubpatchIdsKey = "Patchgram.messageSettingsSubpatches.desired"
    private static let messageSettingsAppliedSubpatchIdsKey = "Patchgram.messageSettingsSubpatches.applied"
    private static let messageSettingsFeatureRuleId = "binary.messages.settings"
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
        "binary.visual.bot_verification",
        "binary.visual.custom_level_rating",
        "binary.visual.hide_self_phone",
        "binary.visual.peer_badge",
        "binary.visual.no_premium_anim",
        "binary.visual.disable_spoilers",
        "binary.presence.force_offline",
        "binary.privacy.no_phone_on_add",
        "binary.links.open_without_warning",
        "binary.inline.callback_hover",
        "binary.display.custom_ton",
        "binary.display.custom_stars",
        "binary.activity.block_typing",
        "binary.read_receipts.block_history_read",
        messageSettingsFeatureRuleId,
        "binary.premium.local",
        "binary.visual.sensitive_blur",
        "binary.stories.hide",
        adsFeatureRuleId
    ]
    private static let compositeFeatureRuleIds: Set<String> = [
        appConfigFeatureRuleId,
        messageSettingsFeatureRuleId,
        adsFeatureRuleId
    ]
    private static let messageSettingsSubpatchDefinitions: [BinaryCompositeSubpatchDefinition] = [
        BinaryCompositeSubpatchDefinition(id: "typing", title: "Typing activity"),
        BinaryCompositeSubpatchDefinition(id: "read_receipts", title: "Read receipts"),
        BinaryCompositeSubpatchDefinition(id: "local_drafts", title: "Local drafts"),
        BinaryCompositeSubpatchDefinition(id: "scheduled_send", title: "Scheduled send")
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
    private var desiredAppConfigSubpatchIds: Set<String>
    private var appliedAppConfigSubpatchIds: Set<String>
    private var desiredMessageSettingsSubpatchIds: Set<String>
    private var appliedMessageSettingsSubpatchIds: Set<String>
    private var desiredAdsSubpatchIds: Set<String>
    private var appliedAdsSubpatchIds: Set<String>

    init() {
        binaryParameterValues = Self.loadBinaryParameterValues()
        botVerificationUserPresets = Self.loadBotVerificationUserPresets()
        botVerificationConfigs = Self.loadBotVerificationConfigs()
        customLevelRatingConfigs = Self.loadCustomLevelRatingConfigs()
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
        return binaryRows.filter { row in
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
    }

    var hasPendingChanges: Bool {
        binaryRows.contains { $0.needsApply }
    }

    var enabledCount: Int {
        binaryRows.filter { $0.desiredEnabled }.count
    }

    var patchStateSummary: String {
        hasPendingChanges ? "Patch changes pending." : "Patch ready."
    }

    func chooseApp() {
        let panel = NSOpenPanel()
        panel.title = "Choose Telegram.app or a patched copy"
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

    func copySelectedApp() {
        guard let appURL else { return }
        let panel = NSSavePanel()
        panel.title = "Create patched Telegram copy"
        panel.nameFieldStringValue = "Telegram Patchgram.app"
        panel.canCreateDirectories = true
        panel.prompt = "Copy"

        if panel.runModal() == .OK, let destination = panel.url {
            do {
                let inspection = try binaryEngine.copyApp(source: appURL, destination: destination)
                self.appURL = inspection.appURL
                UserDefaults.standard.set(inspection.appURL.path, forKey: "Patchgram.appURL")
                rescanApp()
                statusMessage = "Copied app to \(inspection.appURL.path)."
            } catch {
                statusMessage = error.localizedDescription
            }
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
                    customLevelRatingConfigs: customLevelRatingConfigsForEngine()
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
        binaryRows = statuses.map {
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
                subpatches: subpatches
            )
        }
        isValidApp = true
        appInfo = "\(inspection.bundleIdentifier) \(inspection.bundleVersion)"
        selectedAppIcon = NSWorkspace.shared.icon(forFile: inspection.appURL.path)
        executableSize = ByteCountFormatter.string(fromByteCount: Int64(inspection.executableSize), countStyle: .file)
        statusMessage = quick ? "Patch ready. Byte windows will be verified on apply." : "Patch ready."
    }

    func setDesired(_ enabled: Bool, for row: BinaryRuleRowState) {
        guard !isWorking else { return }
        guard let index = binaryRows.firstIndex(where: { $0.id == row.id }) else { return }
        if enabled {
            if row.id == Self.appConfigFeatureRuleId {
                guard confirmAppConfigConflictsIfNeeded() else { return }
                desiredAppConfigSubpatchIds = Set(Self.appConfigSubpatchDefinitions.map(\.id))
                storeAppConfigSubpatchIds(desiredAppConfigSubpatchIds, key: Self.appConfigDesiredSubpatchIdsKey)
            } else if row.id == Self.messageSettingsFeatureRuleId {
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
        } else if enabled, let value = promptForParameterIfNeeded(for: row.status.rule, actionTitle: "Enable") {
            binaryParameterValues[row.id] = value
            binaryRows[index].parameterValue = value
            UserDefaults.standard.set(String(value), forKey: Self.binaryParameterDefaultsPrefix + row.id)
        } else if enabled, row.status.rule.parameter != nil {
            return
        }
        binaryRows[index].desiredEnabled = enabled
        if Self.compositeFeatureRuleIds.contains(row.id) {
            binaryRows[index].subpatches = subpatchRows(for: binaryRows[index].status)
        }
    }

    func setSubpatch(ruleId: String, subpatchId: String, enabled: Bool) {
        guard !isWorking else { return }
        guard Self.compositeFeatureRuleIds.contains(ruleId),
              binaryRows.contains(where: { $0.id == ruleId }) else { return }
        if ruleId == Self.appConfigFeatureRuleId,
           enabled,
           desiredAppConfigSubpatchIds.isEmpty {
            guard confirmAppConfigConflictsIfNeeded() else { return }
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
        binaryRows[index].subpatches = subpatchRows(for: binaryRows[index].status)
    }

    func updateAppliedPatch(for row: BinaryRuleRowState) {
        guard !isWorking else { return }
        guard let appURL else { return }
        guard verifyPatchWriteAccess(appURL: appURL) else { return }
        let nextParameterValue: UInt64?
        let nextBotVerificationConfig: BotVerificationPatchConfig?
        let nextCustomLevelRatingConfig: CustomLevelRatingPatchConfig?
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
        } else {
            nextParameterValue = parameterValue(for: row.status.rule)
            nextBotVerificationConfig = botVerificationConfig(for: row.status.rule)
            nextCustomLevelRatingConfig = customLevelRatingConfig(for: row.status.rule)
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
                signAfterPatch: !liveRuntimeUpdate
            )
            lastChangedFiles = report.changedExecutable ? changedFiles(for: row.status.rule) : []
            setOperationProgress(0.76, message: "Refreshing patch row...")
            markBinaryRule(
                row.status.rule,
                enabled: true,
                patchedParameterValue: nextParameterValue,
                patchedBotVerificationConfig: nextBotVerificationConfig,
                patchedCustomLevelRatingConfig: nextCustomLevelRatingConfig
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
        guard verifyPatchWriteAccess(appURL: appURL) else { return }
        let changes = pendingRows.map {
            let rule = ruleForChange($0, changedGroupsOnly: true)
            return BinaryPatchRuleChange(
                rule: rule,
                enabled: $0.desiredEnabled,
                parameterValue: parameterValue(for: rule),
                botVerificationConfig: botVerificationConfig(for: rule),
                customLevelRatingConfig: customLevelRatingConfig(for: rule),
                enabledAlternativeGroups: alternativeGroupsForChange($0)
            )
        }
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
        guard !changes.isEmpty,
              changes.allSatisfy({ Self.runtimeRuleIds.contains($0.rule.id) }),
              try binaryEngine.runtimeHookSupportsLiveReload(appURL: appURL) else {
            return false
        }
        let runtimeStillDesired = binaryRows.contains {
            Self.runtimeRuleIds.contains($0.id)
                && $0.desiredEnabled
        }
        return runtimeStillDesired
    }

    func disableAllBinary() {
        guard !isWorking else { return }
        guard let appURL else { return }
        let rowsToDisable = binaryRows.filter { $0.desiredEnabled || $0.status.state.isEnabled }
        guard !rowsToDisable.isEmpty else { return }
        guard verifyPatchWriteAccess(appURL: appURL) else { return }
        let changes = rowsToDisable.map {
            BinaryPatchRuleChange(rule: ruleForChange($0, changedGroupsOnly: false), enabled: false)
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
                    enabledAlternativeGroups: change.enabledAlternativeGroups
                )
            }
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
        guard verifyPatchWriteAccess(appURL: appURL) else { return }
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
        enabledAlternativeGroups: Set<String>? = nil
    ) {
        guard let index = binaryRows.firstIndex(where: { $0.id == rule.id }) else { return }
        let displayRule = BinaryPatchRuleCatalog.rule(id: rule.id) ?? rule
        let state: RuleApplicationState = enabled ? .applied : .notApplied
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
        if Self.compositeFeatureRuleIds.contains(displayRule.id) {
            if enabled {
                let appliedIds = subpatchIds(forAlternativeGroups: enabledAlternativeGroups, ruleId: displayRule.id)
                    ?? desiredSubpatchIds(for: displayRule.id)
                setAppliedSubpatchIds(appliedIds, for: displayRule.id)
            } else {
                setAppliedSubpatchIds([], for: displayRule.id)
                setDesiredSubpatchIds([], for: displayRule.id)
            }
            binaryRows[index].desiredEnabled = !desiredSubpatchIds(for: displayRule.id).isEmpty
            binaryRows[index].subpatches = subpatchRows(for: binaryRows[index].status)
        }
    }

    private func markAllBinaryRulesDisabled() {
        setDesiredSubpatchIds([], for: Self.appConfigFeatureRuleId)
        setAppliedSubpatchIds([], for: Self.appConfigFeatureRuleId)
        setDesiredSubpatchIds([], for: Self.adsFeatureRuleId)
        setAppliedSubpatchIds([], for: Self.adsFeatureRuleId)
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

    private func verifyPatchWriteAccess(appURL: URL) -> Bool {
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
                """
            )
            return false
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
        binaryRows = BinaryPatchRuleCatalog.rules.map {
            BinaryRuleRowState(
                status: BinaryRuleStatus(rule: $0, state: .unavailable, detail: "No app selected."),
                desiredEnabled: false,
                parameterValue: parameterValue(for: $0),
                botVerificationConfig: botVerificationConfig(for: $0),
                customLevelRatingConfig: customLevelRatingConfig(for: $0),
                subpatches: subpatchRows(for: BinaryRuleStatus(rule: $0, state: .unavailable, detail: "No app selected."))
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
                desiredEnabled: desiredIds.contains(subpatch.id),
                appliedEnabled: appliedIds.contains(subpatch.id)
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

    private static func subpatchDefinitions(for ruleId: String) -> [BinaryCompositeSubpatchDefinition] {
        switch ruleId {
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

    private func storeBotVerificationConfig(_ config: BotVerificationPatchConfig, for ruleId: String) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(config.normalized) {
            UserDefaults.standard.set(data, forKey: Self.botVerificationDefaultsPrefix + ruleId)
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

    private static func durationString(since start: Date) -> String {
        String(format: "%.3fs", Date().timeIntervalSince(start))
    }
}
