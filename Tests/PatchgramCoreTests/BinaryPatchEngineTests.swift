import Foundation
import XCTest
@testable import PatchgramCore

final class BinaryPatchEngineTests: XCTestCase {
    private var appURL: URL!

    override func setUpWithError() throws {
        appURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("patchgram-app-tests-")
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("Telegram.app", isDirectory: true)
        try makeAppFixture(at: appURL)
    }

    override func tearDownWithError() throws {
        if let appURL {
            try? FileManager.default.removeItem(at: appURL.deletingLastPathComponent())
        }
    }

    func testInspectsAppBundle() throws {
        let engine = BinaryPatchEngine(processRunner: StubProcessRunner())
        let inspection = try engine.inspect(appURL: appURL)

        XCTAssertEqual(inspection.bundleIdentifier, "com.tdesktop.Telegram")
        XCTAssertEqual(inspection.bundleVersion, "6.8.4")
        XCTAssertEqual(inspection.executableURL.lastPathComponent, "Telegram")
    }

    func testAppliesAndRemovesBinaryRules() throws {
        let engine = BinaryPatchEngine(processRunner: StubProcessRunner())
        let initial = try engine.statuses(appURL: appURL)
        XCTAssertTrue(initial.allSatisfy { $0.state == .notApplied })

        let desired = compatibleEnabledStates()
        let applyReport = try engine.applyDesiredStates(desired, appURL: appURL, signAfterPatch: false)
        XCTAssertTrue(applyReport.changedExecutable)
        XCTAssertTrue(FileManager.default.fileExists(atPath: executableURL.appendingPathExtension("patchgram-original").path))

        let applied = try engine.statuses(appURL: appURL)
        let mismatchedApplied = applied.filter { status in
            status.state != (desired[status.id] == true ? .applied : .notApplied)
        }
        XCTAssertTrue(
            mismatchedApplied.isEmpty,
            mismatchedApplied.map { "\($0.id)=\($0.state.rawValue): \($0.detail)" }.joined(separator: "\n")
        )
        let disabled = Dictionary(uniqueKeysWithValues: BinaryPatchRuleCatalog.rules.map { ($0.id, false) })
        let disableReport = try engine.applyDesiredStates(disabled, appURL: appURL, signAfterPatch: false)
        XCTAssertTrue(disableReport.changedExecutable)

        let restoredStatuses = try engine.statuses(appURL: appURL)
        XCTAssertTrue(restoredStatuses.allSatisfy { $0.state == .notApplied })
        XCTAssertFalse(FileManager.default.fileExists(atPath: wrappedExecutableURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: runtimeHookDylibURL.path))
    }

    func testBinaryRulesAreCollectedFromModules() throws {
        let moduleIds = BinaryPatchRuleCatalog.modules.map(\.moduleId)
        XCTAssertEqual(
            moduleIds,
            [
                "BinaryCorePatchModule",
                "BinaryInlinePatchModule",
                "BinaryMonetizationPatchModule",
                "BinaryRuntimePatchModule",
                "BinaryVisualPatchModule",
                "BinaryStoriesPatchModule",
                "BinaryAdsPatchModule"
            ]
        )
        XCTAssertNotNil(BinaryPatchRuleCatalog.rule(id: "binary.messages.settings"))
        XCTAssertNotNil(BinaryPatchRuleCatalog.rule(id: "binary.links.open_without_warning"))
        XCTAssertNotNil(BinaryPatchRuleCatalog.rule(id: "binary.privacy.no_phone_on_add"))
        XCTAssertNotNil(BinaryPatchRuleCatalog.rule(id: "binary.inline.callback_hover"))
        XCTAssertNotNil(BinaryPatchRuleCatalog.rule(id: "binary.visual.peer_badge"))
        XCTAssertNotNil(BinaryPatchRuleCatalog.rule(id: "binary.visual.bot_verification"))
        XCTAssertNotNil(BinaryPatchRuleCatalog.rule(id: "binary.visual.custom_level_rating"))
        XCTAssertNotNil(BinaryPatchRuleCatalog.rule(id: "binary.visual.hide_self_phone"))
        XCTAssertNotNil(BinaryPatchRuleCatalog.rule(id: "binary.visual.self_identity_override"))
        XCTAssertNotNil(BinaryPatchRuleCatalog.rule(id: "binary.visual.no_premium_anim"))
        XCTAssertNotNil(BinaryPatchRuleCatalog.rule(id: "binary.visual.disable_spoilers"))
        XCTAssertNotNil(BinaryPatchRuleCatalog.rule(id: "binary.visual.sensitive_blur"))
        XCTAssertNotNil(BinaryPatchRuleCatalog.rule(id: "binary.stories.hide"))
    }

    func testApplyRuleChangesOnlyTouchesRequestedRules() throws {
        let engine = BinaryPatchEngine(processRunner: StubProcessRunner())
        let presence = try XCTUnwrap(BinaryPatchRuleCatalog.rule(id: "binary.presence.force_offline"))
        let messageSettings = try XCTUnwrap(BinaryPatchRuleCatalog.rule(id: "binary.messages.settings"))
        let typing = try XCTUnwrap(messageSettings.replacements.first { $0.id == "messages.setTyping.constructor" })

        _ = try engine.applyRuleChanges(
            [BinaryPatchRuleChange(rule: presence, enabled: true)],
            appURL: appURL,
            signAfterPatch: false
        )

        var executable = try Data(contentsOf: wrappedExecutableURL)
        XCTAssertNotNil(executable.range(of: presence.replacements[0].original))
        XCTAssertNil(executable.range(of: presence.replacements[0].patched))
        XCTAssertNotNil(executable.range(of: typing.original))
        XCTAssertNil(executable.range(of: typing.patched))
        var configJSON = try String(contentsOf: runtimeConfigURL, encoding: .utf8)
        XCTAssertTrue(configJSON.contains("\"forceOfflineEnabled\" : true"))

        _ = try engine.applyRuleChanges(
            [
                BinaryPatchRuleChange(
                    rule: messageSettings,
                    enabled: true,
                    enabledAlternativeGroups: [typing.alternativeGroup]
                )
            ],
            appURL: appURL,
            signAfterPatch: false
        )

        executable = try Data(contentsOf: wrappedExecutableURL)
        XCTAssertNotNil(executable.range(of: presence.replacements[0].original))
        XCTAssertNil(executable.range(of: presence.replacements[0].patched))
        XCTAssertNotNil(executable.range(of: typing.original))
        XCTAssertNil(executable.range(of: typing.patched))
        XCTAssertTrue(FileManager.default.fileExists(atPath: botVerificationRuntimeHookDylibURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: runtimeConfigURL.path))
        configJSON = try String(contentsOf: runtimeConfigURL, encoding: .utf8)
        XCTAssertTrue(configJSON.contains("\"forceOfflineEnabled\" : true"))
        XCTAssertTrue(configJSON.contains("\"messageSettingsEnabled\" : true"))
        XCTAssertTrue(configJSON.contains("\"messageTypingEnabled\" : true"))
        XCTAssertTrue(configJSON.contains("\"messageReadReceiptsEnabled\" : false"))
        XCTAssertTrue(configJSON.contains("\"messageLocalDraftsEnabled\" : false"))
    }

    func testMessageSettingsReadReceiptsRuntimeConfigSelectsAllRequiredWindows() throws {
        let engine = BinaryPatchEngine(processRunner: StubProcessRunner())
        let rule = try XCTUnwrap(BinaryPatchRuleCatalog.rule(id: "binary.messages.settings"))
        let readReceiptReplacements = rule.replacements.filter {
            $0.alternativeGroup.hasPrefix("messages.read_receipts.")
        }
        XCTAssertEqual(readReceiptReplacements.count, 3)

        _ = try engine.applyRuleChanges(
            [
                BinaryPatchRuleChange(
                    rule: rule,
                    enabled: true,
                    enabledAlternativeGroups: Set(readReceiptReplacements.map(\.alternativeGroup))
                )
            ],
            appURL: appURL,
            signAfterPatch: false
        )

        let executable = try Data(contentsOf: wrappedExecutableURL)
        for replacement in readReceiptReplacements {
            XCTAssertNotNil(executable.range(of: replacement.original), replacement.id)
            XCTAssertNil(executable.range(of: replacement.patched), replacement.id)
        }
        let configJSON = try String(contentsOf: runtimeConfigURL, encoding: .utf8)
        XCTAssertTrue(configJSON.contains("\"messageSettingsEnabled\" : true"))
        XCTAssertTrue(configJSON.contains("\"messageTypingEnabled\" : false"))
        XCTAssertTrue(configJSON.contains("\"messageReadReceiptsEnabled\" : true"))
        XCTAssertTrue(configJSON.contains("\"messageLocalDraftsEnabled\" : false"))

        let statuses = try engine.statuses(appURL: appURL, rules: [rule])
        XCTAssertEqual(statuses.first?.state, .applied)
        XCTAssertFalse(statuses.first?.detail.contains("Multiple alternative windows matched") ?? true)
    }

    func testOpenLinksWithoutWarningUsesRuntimeMemoryPatch() throws {
        let engine = BinaryPatchEngine(processRunner: StubProcessRunner())
        let rule = try XCTUnwrap(BinaryPatchRuleCatalog.rule(id: "binary.links.open_without_warning"))
        let replacement = try XCTUnwrap(rule.replacements.first)

        _ = try engine.applyRuleChanges(
            [BinaryPatchRuleChange(rule: rule, enabled: true)],
            appURL: appURL,
            signAfterPatch: false
        )

        var executable = try Data(contentsOf: wrappedExecutableURL)
        XCTAssertNotNil(executable.range(of: replacement.original))
        XCTAssertNil(executable.range(of: replacement.patched))
        let configJSON = try String(contentsOf: runtimeConfigURL, encoding: .utf8)
        XCTAssertTrue(configJSON.contains("\"openLinksWithoutWarningEnabled\" : true"))
        XCTAssertEqual(try engine.statuses(appURL: appURL, rules: [rule]).first?.state, .applied)

        _ = try engine.applyRuleChanges(
            [BinaryPatchRuleChange(rule: rule, enabled: false)],
            appURL: appURL,
            signAfterPatch: false
        )

        executable = try Data(contentsOf: executableURL)
        XCTAssertNotNil(executable.range(of: replacement.original))
        XCTAssertNil(executable.range(of: replacement.patched))
        XCTAssertFalse(FileManager.default.fileExists(atPath: runtimeConfigURL.path))
        XCTAssertEqual(try engine.statuses(appURL: appURL, rules: [rule]).first?.state, .notApplied)
    }

    func testPartialAlternativeGroupsCanEnableAndDisableCompositeRule() throws {
        let engine = BinaryPatchEngine(processRunner: StubProcessRunner())
        let rule = try XCTUnwrap(BinaryPatchRuleCatalog.rule(id: "binary.config.disable_monetization"))
        let appConfig = try XCTUnwrap(rule.replacements.first { $0.id == "help.getAppConfig.constructor" })
        let premium = try XCTUnwrap(rule.replacements.first { $0.id == "data.peer_premium_value.force_false" })
        let selectedGroups: Set<String> = [appConfig.alternativeGroup]

        _ = try engine.applyRuleChanges(
            [
                BinaryPatchRuleChange(
                    rule: rule,
                    enabled: true,
                    enabledAlternativeGroups: selectedGroups
                )
            ],
            appURL: appURL,
            signAfterPatch: false
        )

        var executable = try Data(contentsOf: executableURL)
        XCTAssertNil(executable.range(of: appConfig.original))
        XCTAssertNotNil(executable.range(of: appConfig.patched))
        XCTAssertNotNil(executable.range(of: premium.original))
        XCTAssertNil(executable.range(of: premium.patched))

        _ = try engine.applyRuleChanges(
            [BinaryPatchRuleChange(rule: rule, enabled: true)],
            appURL: appURL,
            signAfterPatch: false
        )
        executable = try Data(contentsOf: executableURL)
        XCTAssertNotNil(executable.range(of: premium.patched))

        _ = try engine.applyRuleChanges(
            [
                BinaryPatchRuleChange(
                    rule: rule,
                    enabled: true,
                    enabledAlternativeGroups: selectedGroups
                )
            ],
            appURL: appURL,
            signAfterPatch: false
        )
        executable = try Data(contentsOf: executableURL)
        XCTAssertNotNil(executable.range(of: appConfig.patched))
        XCTAssertNotNil(executable.range(of: premium.original))
        XCTAssertNil(executable.range(of: premium.patched))
    }

    func testApplyChecksWriteAccessBeforeChangingApp() throws {
        let engine = BinaryPatchEngine(processRunner: StubProcessRunner())
        let rule = try XCTUnwrap(BinaryPatchRuleCatalog.rule(id: "binary.inline.callback_hover"))
        let original = try Data(contentsOf: executableURL)
        let macOSURL = executableURL.deletingLastPathComponent()

        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: macOSURL.path)
        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: macOSURL.path)
        }

        XCTAssertThrowsError(
            try engine.applyRuleChanges(
                [BinaryPatchRuleChange(rule: rule, enabled: true)],
                appURL: appURL,
                signAfterPatch: false
            )
        ) { error in
            XCTAssertEqual(error as? PatchgramError, .missingWriteAccess(macOSURL.path))
        }
        XCTAssertEqual(try Data(contentsOf: executableURL), original)
        XCTAssertFalse(FileManager.default.fileExists(atPath: executableURL.appendingPathExtension("patchgram-original").path))
    }

    func testRuntimeConfigIncludesLiveMemoryRules() throws {
        let engine = BinaryPatchEngine(processRunner: StubProcessRunner())
        let rules = try [
            "binary.presence.force_offline",
            "binary.links.open_without_warning",
            "binary.privacy.no_phone_on_add",
            "binary.inline.callback_hover",
            "binary.messages.settings",
            "binary.premium.local",
            "binary.visual.peer_badge",
            "binary.visual.no_premium_anim",
            "binary.visual.disable_spoilers",
            "binary.visual.sensitive_blur",
            "binary.stories.hide",
            "binary.ads.disable_sponsored"
        ].map { try XCTUnwrap(BinaryPatchRuleCatalog.rule(id: $0)) }

        _ = try engine.applyRuleChanges(
            rules.map { BinaryPatchRuleChange(rule: $0, enabled: true) },
            appURL: appURL,
            signAfterPatch: false
        )

        let configJSON = try String(contentsOf: runtimeConfigURL, encoding: .utf8)
        XCTAssertTrue(configJSON.contains("\"forceOfflineEnabled\" : true"))
        XCTAssertTrue(configJSON.contains("\"openLinksWithoutWarningEnabled\" : true"))
        XCTAssertTrue(configJSON.contains("\"noPhoneOnAddEnabled\" : true"))
        XCTAssertTrue(configJSON.contains("\"callbackHoverEnabled\" : true"))
        XCTAssertTrue(configJSON.contains("\"messageSettingsEnabled\" : true"))
        XCTAssertTrue(configJSON.contains("\"messageTypingEnabled\" : true"))
        XCTAssertTrue(configJSON.contains("\"messageReadReceiptsEnabled\" : true"))
        XCTAssertTrue(configJSON.contains("\"messageLocalDraftsEnabled\" : true"))
        XCTAssertTrue(configJSON.contains("\"visualPeerBadgeEnabled\" : true"))
        XCTAssertTrue(configJSON.contains("\"visualPeerBadgeValue\" : 1"))
        XCTAssertTrue(configJSON.contains("\"localPremiumEnabled\" : true"))
        XCTAssertTrue(configJSON.contains("\"noPremiumAnimEnabled\" : true"))
        XCTAssertTrue(configJSON.contains("\"disableSpoilersEnabled\" : true"))
        XCTAssertTrue(configJSON.contains("\"scheduledSendEnabled\" : true"))
        XCTAssertTrue(configJSON.contains("\"sensitiveBlurEnabled\" : true"))
        XCTAssertTrue(configJSON.contains("\"hideStoriesEnabled\" : true"))
        XCTAssertTrue(configJSON.contains("\"disableAdsEnabled\" : true"))

        let statuses = try engine.statuses(appURL: appURL, rules: rules)
        XCTAssertTrue(statuses.allSatisfy { $0.state == .applied })
    }

    func testDisableAdsRuntimeConfigTracksSelectedSubpatches() throws {
        let engine = BinaryPatchEngine(processRunner: StubProcessRunner())
        let rule = try XCTUnwrap(BinaryPatchRuleCatalog.rule(id: "binary.ads.disable_sponsored"))
        let telegramAds = try XCTUnwrap(rule.replacements.first {
            $0.alternativeGroup == "ads.telegram_ads.disable"
        })
        let proxySponsorGroups = Set(rule.replacements
            .map(\.alternativeGroup)
            .filter { $0.hasPrefix("ads.proxy_sponsor.") })
        XCTAssertEqual(proxySponsorGroups.count, 2)

        _ = try engine.applyRuleChanges(
            [
                BinaryPatchRuleChange(
                    rule: rule,
                    enabled: true,
                    enabledAlternativeGroups: proxySponsorGroups
                )
            ],
            appURL: appURL,
            signAfterPatch: false
        )

        var configJSON = try String(contentsOf: runtimeConfigURL, encoding: .utf8)
        XCTAssertTrue(configJSON.contains("\"disableAdsEnabled\" : true"))
        XCTAssertTrue(configJSON.contains("\"disableTelegramAdsEnabled\" : false"))
        XCTAssertTrue(configJSON.contains("\"disableProxySponsorEnabled\" : true"))

        _ = try engine.applyRuleChanges(
            [
                BinaryPatchRuleChange(
                    rule: rule,
                    enabled: true,
                    enabledAlternativeGroups: [telegramAds.alternativeGroup]
                )
            ],
            appURL: appURL,
            signAfterPatch: false
        )

        configJSON = try String(contentsOf: runtimeConfigURL, encoding: .utf8)
        XCTAssertTrue(configJSON.contains("\"disableTelegramAdsEnabled\" : true"))
        XCTAssertTrue(configJSON.contains("\"disableProxySponsorEnabled\" : false"))
    }

    func testRestoreOriginalExecutable() throws {
        let engine = BinaryPatchEngine(processRunner: StubProcessRunner())
        let desired = compatibleEnabledStates()
        _ = try engine.applyDesiredStates(desired, appURL: appURL, signAfterPatch: false)

        let report = try engine.restoreOriginalExecutable(appURL: appURL, signAfterRestore: false)
        XCTAssertTrue(report.changedExecutable)
        XCTAssertEqual(try Data(contentsOf: executableURL), fixtureExecutableData())
        XCTAssertFalse(FileManager.default.fileExists(atPath: wrappedExecutableURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: runtimeHookDylibURL.path))
    }

    func testParameterizedBinaryRulesUseProvidedValues() throws {
        let engine = BinaryPatchEngine(processRunner: StubProcessRunner())
        let tonRule = try XCTUnwrap(BinaryPatchRuleCatalog.rule(id: "binary.display.custom_ton"))
        let starsRule = try XCTUnwrap(BinaryPatchRuleCatalog.rule(id: "binary.display.custom_stars"))
        let desired = [tonRule.id: true, starsRule.id: true]
        let parameters = [tonRule.id: UInt64(321), starsRule.id: UInt64(654)]

        _ = try engine.applyDesiredStates(
            desired,
            appURL: appURL,
            parameterValues: parameters,
            signAfterPatch: false
        )

        let executable = try Data(contentsOf: wrappedExecutableURL)
        XCTAssertNotNil(executable.range(of: tonRule.replacements[0].original))
        XCTAssertNotNil(executable.range(of: starsRule.replacements[0].original))
        XCTAssertNil(executable.range(of: tonRule.replacements[0].patchedData(parameterValue: parameters[tonRule.id])))
        XCTAssertNil(executable.range(of: starsRule.replacements[0].patchedData(parameterValue: parameters[starsRule.id])))
        XCTAssertTrue(FileManager.default.fileExists(atPath: botVerificationRuntimeHookDylibURL.path))
        let configJSON = try String(contentsOf: runtimeConfigURL, encoding: .utf8)
        XCTAssertTrue(configJSON.contains("\"customTonEnabled\" : true"))
        XCTAssertTrue(configJSON.contains("\"customTonValue\" : 321"))
        XCTAssertTrue(configJSON.contains("\"customStarsEnabled\" : true"))
        XCTAssertTrue(configJSON.contains("\"customStarsValue\" : 654"))

        let statuses = try engine.statuses(appURL: appURL, parameterValues: parameters)
        XCTAssertEqual(statuses.first { $0.id == tonRule.id }?.state, .applied)
        XCTAssertEqual(statuses.first { $0.id == starsRule.id }?.state, .applied)
    }

    func testParameterizedBinaryRuleCanUpdateAndDisableStaleValues() throws {
        let engine = BinaryPatchEngine(processRunner: StubProcessRunner())
        let tonRule = try XCTUnwrap(BinaryPatchRuleCatalog.rule(id: "binary.display.custom_ton"))
        let oldParameters = [tonRule.id: UInt64(321)]
        let newParameters = [tonRule.id: UInt64(654)]

        _ = try engine.applyDesiredStates(
            [tonRule.id: true],
            appURL: appURL,
            parameterValues: oldParameters,
            signAfterPatch: false
        )

        let staleStatus = try engine.statuses(appURL: appURL, parameterValues: newParameters)
        XCTAssertEqual(staleStatus.first { $0.id == tonRule.id }?.state, .partial)

        _ = try engine.applyDesiredStates(
            [tonRule.id: true],
            appURL: appURL,
            parameterValues: newParameters,
            signAfterPatch: false
        )

        var executable = try Data(contentsOf: wrappedExecutableURL)
        XCTAssertNil(executable.range(of: tonRule.replacements[0].patchedData(parameterValue: oldParameters[tonRule.id])))
        XCTAssertNil(executable.range(of: tonRule.replacements[0].patchedData(parameterValue: newParameters[tonRule.id])))
        XCTAssertNotNil(executable.range(of: tonRule.replacements[0].original))
        let configJSON = try String(contentsOf: runtimeConfigURL, encoding: .utf8)
        XCTAssertTrue(configJSON.contains("\"customTonValue\" : 654"))

        _ = try engine.applyDesiredStates(
            [tonRule.id: false],
            appURL: appURL,
            parameterValues: oldParameters,
            signAfterPatch: false
        )

        executable = try Data(contentsOf: executableURL)
        XCTAssertNotNil(executable.range(of: tonRule.replacements[0].original))
        XCTAssertNil(executable.range(of: tonRule.replacements[0].patchedData(parameterValue: newParameters[tonRule.id])))
        XCTAssertFalse(FileManager.default.fileExists(atPath: botVerificationRuntimeHookDylibURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: runtimeConfigURL.path))
    }

    func testVisualPeerBadgeTargetModesSelectExpectedWindows() throws {
        let engine = BinaryPatchEngine(processRunner: StubProcessRunner())
        let rule = try XCTUnwrap(BinaryPatchRuleCatalog.rule(id: "binary.visual.peer_badge"))
        let parameter = try XCTUnwrap(rule.parameter)
        XCTAssertEqual(parameter.choiceGroups.map(\.title), ["Mode", "Badge"])
        XCTAssertEqual(parameter.displayValue(23), "Only me - Fake")

        let onlySelfFake = try XCTUnwrap(rule.replacements.first { $0.id == "data.user.verification_status.force_fake.only_self" })
        let exceptSelfScam = try XCTUnwrap(rule.replacements.first { $0.id == "data.user.verification_status.force_scam.except_self" })
        let channelScam = try XCTUnwrap(rule.replacements.first { $0.id == "data.channel.verification_status.force_scam" })

        _ = try engine.applyDesiredStates(
            [rule.id: true],
            appURL: appURL,
            parameterValues: [rule.id: 23],
            signAfterPatch: false
        )

        var executable = try Data(contentsOf: wrappedExecutableURL)
        XCTAssertNotNil(executable.range(of: onlySelfFake.original))
        XCTAssertNil(executable.range(of: onlySelfFake.patched))
        XCTAssertNotNil(executable.range(of: channelScam.original))
        XCTAssertNil(executable.range(of: channelScam.patched))
        var configJSON = try String(contentsOf: runtimeConfigURL, encoding: .utf8)
        XCTAssertTrue(configJSON.contains("\"visualPeerBadgeEnabled\" : true"))
        XCTAssertTrue(configJSON.contains("\"visualPeerBadgeValue\" : 23"))

        var statuses = try engine.statuses(appURL: appURL, rules: [rule], parameterValues: [rule.id: 23])
        XCTAssertEqual(statuses.first?.state, .applied)

        _ = try engine.applyDesiredStates(
            [rule.id: true],
            appURL: appURL,
            parameterValues: [rule.id: 12],
            signAfterPatch: false
        )

        executable = try Data(contentsOf: wrappedExecutableURL)
        XCTAssertNil(executable.range(of: onlySelfFake.patched))
        XCTAssertNotNil(executable.range(of: exceptSelfScam.original))
        XCTAssertNil(executable.range(of: exceptSelfScam.patched))
        XCTAssertNotNil(executable.range(of: channelScam.original))
        XCTAssertNil(executable.range(of: channelScam.patched))
        configJSON = try String(contentsOf: runtimeConfigURL, encoding: .utf8)
        XCTAssertTrue(configJSON.contains("\"visualPeerBadgeEnabled\" : true"))
        XCTAssertTrue(configJSON.contains("\"visualPeerBadgeValue\" : 12"))

        statuses = try engine.statuses(appURL: appURL, rules: [rule], parameterValues: [rule.id: 12])
        XCTAssertEqual(statuses.first?.state, .applied)
    }

    func testDisableSpoilersUsesRuntimeMemoryPatch() throws {
        let engine = BinaryPatchEngine(processRunner: StubProcessRunner())
        let rule = try XCTUnwrap(BinaryPatchRuleCatalog.rule(id: "binary.visual.disable_spoilers"))
        XCTAssertEqual(rule.replacements.count, 8)
        XCTAssertEqual(Set(rule.replacements.map(\.alternativeGroup)).count, rule.replacements.count)

        _ = try engine.applyRuleChanges(
            [BinaryPatchRuleChange(rule: rule, enabled: true)],
            appURL: appURL,
            signAfterPatch: false
        )

        let executable = try Data(contentsOf: wrappedExecutableURL)
        for replacement in rule.replacements {
            XCTAssertNotNil(executable.range(of: replacement.original), replacement.id)
            XCTAssertNil(executable.range(of: replacement.patched), replacement.id)
        }
        let configJSON = try String(contentsOf: runtimeConfigURL, encoding: .utf8)
        XCTAssertTrue(configJSON.contains("\"disableSpoilersEnabled\" : true"))
        XCTAssertEqual(try engine.statuses(appURL: appURL, rules: [rule]).first?.state, .applied)

        _ = try engine.applyRuleChanges(
            [BinaryPatchRuleChange(rule: rule, enabled: false)],
            appURL: appURL,
            signAfterPatch: false
        )

        XCTAssertFalse(FileManager.default.fileExists(atPath: wrappedExecutableURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: runtimeHookDylibURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: runtimeConfigURL.path))
        XCTAssertEqual(try engine.statuses(appURL: appURL, rules: [rule]).first?.state, .notApplied)
    }

    func testPrivacyAndPremiumAnimationUseRuntimeMemoryPatches() throws {
        let engine = BinaryPatchEngine(processRunner: StubProcessRunner())
        let noPhoneRule = try XCTUnwrap(BinaryPatchRuleCatalog.rule(id: "binary.privacy.no_phone_on_add"))
        let noPremiumAnimRule = try XCTUnwrap(BinaryPatchRuleCatalog.rule(id: "binary.visual.no_premium_anim"))

        _ = try engine.applyRuleChanges(
            [
                BinaryPatchRuleChange(rule: noPhoneRule, enabled: true),
                BinaryPatchRuleChange(rule: noPremiumAnimRule, enabled: true)
            ],
            appURL: appURL,
            signAfterPatch: false
        )

        let executable = try Data(contentsOf: wrappedExecutableURL)
        for rule in [noPhoneRule, noPremiumAnimRule] {
            for replacement in rule.replacements {
                XCTAssertNotNil(executable.range(of: replacement.original), replacement.id)
                XCTAssertNil(executable.range(of: replacement.patched), replacement.id)
            }
        }

        let configJSON = try String(contentsOf: runtimeConfigURL, encoding: .utf8)
        XCTAssertTrue(configJSON.contains("\"noPhoneOnAddEnabled\" : true"))
        XCTAssertTrue(configJSON.contains("\"noPremiumAnimEnabled\" : true"))

        let statuses = try engine.statuses(appURL: appURL, rules: [noPhoneRule, noPremiumAnimRule])
        XCTAssertTrue(statuses.allSatisfy { $0.state == .applied })

        _ = try engine.applyRuleChanges(
            [
                BinaryPatchRuleChange(rule: noPhoneRule, enabled: false),
                BinaryPatchRuleChange(rule: noPremiumAnimRule, enabled: false)
            ],
            appURL: appURL,
            signAfterPatch: false
        )

        XCTAssertFalse(FileManager.default.fileExists(atPath: wrappedExecutableURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: runtimeHookDylibURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: runtimeConfigURL.path))
    }

    func testBotVerificationRuntimeHookPersistsConfig() throws {
        let engine = BinaryPatchEngine(processRunner: StubProcessRunner())
        let rule = try XCTUnwrap(BinaryPatchRuleCatalog.rule(id: "binary.visual.bot_verification"))
        let config = BotVerificationPatchConfig(
            targetMode: .onlySelf,
            preset: .custom,
            customEmojiId: 123_456_789,
            description: "Local check"
        )

        let applyReport = try engine.applyRuleChanges(
            [
                BinaryPatchRuleChange(
                    rule: rule,
                    enabled: true,
                    botVerificationConfig: config
                )
            ],
            appURL: appURL,
            signAfterPatch: false
        )

        XCTAssertTrue(applyReport.changedExecutable)
        XCTAssertTrue(FileManager.default.fileExists(atPath: wrappedExecutableURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: botVerificationRuntimeHookDylibURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: botVerificationRuntimeHookSourceURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: deprecatedBotVerificationRuntimeHookDylibURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: deprecatedBotVerificationRuntimeHookSourceURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: runtimeConfigURL.path))
        let wrapper = try String(contentsOf: executableURL, encoding: .utf8)
        XCTAssertTrue(wrapper.contains("Patchgram.dylib"))
        let configJSON = try String(contentsOf: runtimeConfigURL, encoding: .utf8)
        XCTAssertTrue(configJSON.contains("\"botVerificationCustomEmojiId\" : 123456789"))
        XCTAssertTrue(configJSON.contains("\"botVerificationDescription\" : \"Local check\""))
        XCTAssertTrue(configJSON.contains("\"botVerificationTargetMode\" : \"onlySelf\""))

        let statuses = try engine.statuses(
            appURL: appURL,
            rules: [rule],
            botVerificationConfigs: [rule.id: config]
        )
        XCTAssertEqual(statuses.first?.state, .applied)

        let disableReport = try engine.applyRuleChanges(
            [BinaryPatchRuleChange(rule: rule, enabled: false)],
            appURL: appURL,
            signAfterPatch: false
        )
        XCTAssertTrue(disableReport.changedExecutable)
        XCTAssertFalse(FileManager.default.fileExists(atPath: wrappedExecutableURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: botVerificationRuntimeHookDylibURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: botVerificationRuntimeHookSourceURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: runtimeConfigURL.path))
    }

    func testCustomLevelRatingRuntimeHookPersistsConfig() throws {
        let engine = BinaryPatchEngine(processRunner: StubProcessRunner())
        let rule = try XCTUnwrap(BinaryPatchRuleCatalog.rule(id: "binary.visual.custom_level_rating"))
        let config = CustomLevelRatingPatchConfig(
            targetMode: .allExceptSelf,
            level: 7,
            rating: 123_456,
            currentLevelRating: 100_000,
            nextLevelRating: 200_000
        )

        let applyReport = try engine.applyRuleChanges(
            [
                BinaryPatchRuleChange(
                    rule: rule,
                    enabled: true,
                    customLevelRatingConfig: config
                )
            ],
            appURL: appURL,
            signAfterPatch: false
        )

        XCTAssertTrue(applyReport.changedExecutable)
        XCTAssertTrue(FileManager.default.fileExists(atPath: wrappedExecutableURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: runtimeHookDylibURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: runtimeConfigURL.path))
        let configJSON = try String(contentsOf: runtimeConfigURL, encoding: .utf8)
        XCTAssertTrue(configJSON.contains("\"customLevelRatingEnabled\" : true"))
        XCTAssertTrue(configJSON.contains("\"customLevelRatingTargetMode\" : \"allExceptSelf\""))
        XCTAssertTrue(configJSON.contains("\"customLevelRatingLevel\" : 7"))
        XCTAssertTrue(configJSON.contains("\"customLevelRatingRating\" : 123456"))
        XCTAssertTrue(configJSON.contains("\"customLevelRatingCurrentLevelRating\" : 100000"))
        XCTAssertTrue(configJSON.contains("\"customLevelRatingNextLevelRating\" : 200000"))

        let statuses = try engine.statuses(
            appURL: appURL,
            rules: [rule],
            customLevelRatingConfigs: [rule.id: config]
        )
        XCTAssertEqual(statuses.first?.state, .applied)

        let changedConfig = CustomLevelRatingPatchConfig(
            targetMode: .onlySelf,
            level: 8,
            rating: 222_222,
            currentLevelRating: 200_000,
            nextLevelRating: 300_000
        )
        let staleStatuses = try engine.statuses(
            appURL: appURL,
            rules: [rule],
            customLevelRatingConfigs: [rule.id: changedConfig]
        )
        XCTAssertEqual(staleStatuses.first?.state, .partial)
    }

    func testHideSelfPhoneRuntimeHookPersistsConfig() throws {
        let engine = BinaryPatchEngine(processRunner: StubProcessRunner())
        let rule = try XCTUnwrap(BinaryPatchRuleCatalog.rule(id: "binary.visual.hide_self_phone"))

        let applyReport = try engine.applyRuleChanges(
            [BinaryPatchRuleChange(rule: rule, enabled: true)],
            appURL: appURL,
            signAfterPatch: false
        )

        XCTAssertTrue(applyReport.changedExecutable)
        XCTAssertTrue(FileManager.default.fileExists(atPath: wrappedExecutableURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: runtimeHookDylibURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: runtimeConfigURL.path))
        let configJSON = try String(contentsOf: runtimeConfigURL, encoding: .utf8)
        XCTAssertTrue(configJSON.contains("\"hideSelfPhoneEnabled\" : true"))

        let statuses = try engine.statuses(appURL: appURL, rules: [rule])
        XCTAssertEqual(statuses.first?.state, .applied)
    }

    func testSelfIdentityRuntimeHookPersistsConfig() throws {
        let engine = BinaryPatchEngine(processRunner: StubProcessRunner())
        let rule = try XCTUnwrap(BinaryPatchRuleCatalog.rule(id: "binary.visual.self_identity_override"))
        let config = SelfIdentityPatchConfig(phone: "+15551234567", userId: "987654321")

        let applyReport = try engine.applyRuleChanges(
            [
                BinaryPatchRuleChange(
                    rule: rule,
                    enabled: true,
                    selfIdentityConfig: config
                )
            ],
            appURL: appURL,
            signAfterPatch: false
        )

        XCTAssertTrue(applyReport.changedExecutable)
        XCTAssertTrue(FileManager.default.fileExists(atPath: wrappedExecutableURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: runtimeHookDylibURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: runtimeConfigURL.path))
        let configJSON = try String(contentsOf: runtimeConfigURL, encoding: .utf8)
        XCTAssertTrue(configJSON.contains("\"selfIdentityOverrideEnabled\" : true"))
        XCTAssertTrue(configJSON.contains("\"selfIdentityOverridePhone\" : \"+15551234567\""))
        XCTAssertTrue(configJSON.contains("\"selfIdentityOverrideUserId\" : \"987654321\""))

        let statuses = try engine.statuses(
            appURL: appURL,
            rules: [rule],
            selfIdentityConfigs: [rule.id: config]
        )
        XCTAssertEqual(statuses.first?.state, .applied)

        let staleStatuses = try engine.statuses(
            appURL: appURL,
            rules: [rule],
            selfIdentityConfigs: [rule.id: SelfIdentityPatchConfig(phone: "+15550000000", userId: "111")]
        )
        XCTAssertEqual(staleStatuses.first?.state, .partial)
    }

    func testSelfIdentityRuntimeConfigUsesEmptyStringsForOriginalValues() throws {
        let engine = BinaryPatchEngine(processRunner: StubProcessRunner())
        let rule = try XCTUnwrap(BinaryPatchRuleCatalog.rule(id: "binary.visual.self_identity_override"))

        _ = try engine.applyRuleChanges(
            [
                BinaryPatchRuleChange(
                    rule: rule,
                    enabled: true,
                    selfIdentityConfig: SelfIdentityPatchConfig(phone: "", userId: "")
                )
            ],
            appURL: appURL,
            signAfterPatch: false
        )

        let configJSON = try String(contentsOf: runtimeConfigURL, encoding: .utf8)
        XCTAssertTrue(configJSON.contains("\"selfIdentityOverridePhone\" : \"\""))
        XCTAssertTrue(configJSON.contains("\"selfIdentityOverrideUserId\" : \"\""))
    }

    func testSelfIdentityConfigDecodesLegacyNumericUserId() throws {
        let numeric = Data(#"{"phone":"+15551234567","userId":987654321}"#.utf8)
        let zero = Data(#"{"phone":"","userId":0}"#.utf8)
        let decoder = JSONDecoder()

        let numericConfig = try decoder.decode(SelfIdentityPatchConfig.self, from: numeric)
        let zeroConfig = try decoder.decode(SelfIdentityPatchConfig.self, from: zero)

        XCTAssertEqual(numericConfig.normalized.userId, "987654321")
        XCTAssertEqual(zeroConfig.normalized.userId, "")
    }

    func testRuntimeHookSourceCompilesWithSelfIdentityOverride() throws {
        let engine = BinaryPatchEngine()
        let rule = try XCTUnwrap(BinaryPatchRuleCatalog.rule(id: "binary.visual.self_identity_override"))

        let report = try engine.applyRuleChanges(
            [
                BinaryPatchRuleChange(
                    rule: rule,
                    enabled: true,
                    selfIdentityConfig: SelfIdentityPatchConfig(phone: "+15551234567", userId: "987654321")
                )
            ],
            appURL: appURL,
            signAfterPatch: false
        )

        XCTAssertTrue(report.changedExecutable)
        XCTAssertTrue(FileManager.default.fileExists(atPath: runtimeHookDylibURL.path))
        let dylib = try Data(contentsOf: runtimeHookDylibURL)
        XCTAssertNotNil(dylib.range(of: Data("PATCHGRAM_RUNTIME_BUILD_20260607_SELF_IDENTITY_SELF_PROFILE_ID".utf8)))
    }

    private var executableURL: URL {
        appURL.appendingPathComponent("Contents/MacOS/Telegram")
    }

    private var wrappedExecutableURL: URL {
        appURL.appendingPathComponent("Contents/MacOS/Telegram.patchgram-bin")
    }

    private var runtimeHookDylibURL: URL {
        appURL.appendingPathComponent("Contents/Frameworks/Patchgram.dylib")
    }

    private var botVerificationRuntimeHookDylibURL: URL {
        appURL.appendingPathComponent("Contents/Frameworks/Patchgram.dylib")
    }

    private var botVerificationRuntimeHookSourceURL: URL {
        appURL.appendingPathComponent("Contents/Frameworks/PatchgramBotVerificationHook.c")
    }

    private var deprecatedBotVerificationRuntimeHookDylibURL: URL {
        appURL.appendingPathComponent("Contents/Frameworks/PatchgramBotVerificationHook.dylib")
    }

    private var deprecatedBotVerificationRuntimeHookSourceURL: URL {
        appURL.appendingPathComponent("Contents/Frameworks/PatchgramBotVerificationHook.c")
    }

    private var runtimeConfigURL: URL {
        appURL.appendingPathComponent("Contents/Resources/PatchgramRuntime.json")
    }

    private func compatibleEnabledStates() -> [String: Bool] {
        Dictionary(uniqueKeysWithValues: BinaryPatchRuleCatalog.rules.map { rule in
            (rule.id, rule.id != "binary.premium.local")
        })
    }
}

private struct StubProcessRunner: ProcessRunning {
    func run(executableURL: URL, arguments: [String]) throws -> ProcessResult {
        if executableURL.path == "/usr/bin/clang",
           let outputFlag = arguments.firstIndex(of: "-o"),
           arguments.indices.contains(arguments.index(after: outputFlag)) {
            let output = URL(fileURLWithPath: arguments[arguments.index(after: outputFlag)])
            try FileManager.default.createDirectory(
                at: output.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try Data("stub dylib".utf8).write(to: output, options: .atomic)
        }
        return ProcessResult(exitCode: 0, output: "stub")
    }
}

private func makeAppFixture(at appURL: URL) throws {
    let contents = appURL.appendingPathComponent("Contents", isDirectory: true)
    let macOS = contents.appendingPathComponent("MacOS", isDirectory: true)
    let resources = contents.appendingPathComponent("Resources", isDirectory: true)
    try FileManager.default.createDirectory(at: macOS, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: resources, withIntermediateDirectories: true)

    let info = """
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>CFBundleExecutable</key>
      <string>Telegram</string>
      <key>CFBundleIdentifier</key>
      <string>com.tdesktop.Telegram</string>
      <key>CFBundleShortVersionString</key>
      <string>6.8.4</string>
    </dict>
    </plist>
    """
    try info.write(to: contents.appendingPathComponent("Info.plist"), atomically: true, encoding: .utf8)
    try fixtureExecutableData().write(to: macOS.appendingPathComponent("Telegram"), options: .atomic)
}

private func fixtureExecutableData(preferredToggleReplacementIds: Set<String> = []) -> Data {
    var data = Data("prefix".utf8)
    var emittedToggleOriginals = Set<Data>()
    for rule in BinaryPatchRuleCatalog.rules {
        let toggleOriginals = Set(
            rule.replacements
                .filter { $0.mode == .toggle }
                .map(\.original)
        )
        let togglePatched = Set(
            rule.replacements
                .filter { $0.mode == .toggle }
                .map(\.patched)
        )
        var emittedToggleGroups = Set<String>()
        for replacement in rule.replacements {
            if replacement.mode == .toggle {
                guard !emittedToggleGroups.contains(replacement.alternativeGroup) else {
                    continue
                }
                emittedToggleGroups.insert(replacement.alternativeGroup)
            }
            let selected = rule.replacements.first {
                $0.mode == .toggle
                    && $0.alternativeGroup == replacement.alternativeGroup
                    && preferredToggleReplacementIds.contains($0.id)
            } ?? replacement
            if selected.mode == .toggle {
                guard !emittedToggleOriginals.contains(selected.original) else {
                    continue
                }
                emittedToggleOriginals.insert(selected.original)
            }
            if replacement.mode == .normalize,
               toggleOriginals.contains(replacement.patched) || togglePatched.contains(replacement.patched) {
                continue
            }
            data.append(Data("-\(selected.id)-".utf8))
            let fixtureBytes = selected.mode == .normalize ? selected.patched : selected.original
            for _ in 0..<selected.expectedOccurrences {
                data.append(fixtureBytes)
            }
        }
    }
    data.append(Data("suffix".utf8))
    return data
}
