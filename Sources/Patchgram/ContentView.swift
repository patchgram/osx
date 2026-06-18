import AppKit
import PatchgramCore
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = PatchgramViewModel()

    var body: some View {
        VStack(spacing: 0) {
            HeaderBar(viewModel: viewModel)
            Divider()
            HStack(spacing: 0) {
                Sidebar(viewModel: viewModel)
                    .frame(width: 290)
                Divider()
                RuleList(viewModel: viewModel)
            }
            Divider()
            FooterBar(viewModel: viewModel)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .alert("Permission required", isPresented: writeAccessAlertBinding, presenting: viewModel.writeAccessAlert) { alert in
            Button("Retry") {
                viewModel.retryWriteAccessAction(alert.retryAction)
            }
            Button("Open Settings") {
                viewModel.openFullDiskAccessSettings()
            }
            Button("Cancel", role: .cancel) {
                viewModel.writeAccessAlert = nil
            }
        } message: { alert in
            Text(alert.message)
        }
        .sheet(isPresented: $viewModel.isShowingBotVerificationSettings) {
            BotVerificationSettingsView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.isShowingCustomListUsernamesSettings) {
            CustomListUsernamesSettingsView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.isShowingGiftSpoofSettings) {
            GiftSpoofSettingsView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.isShowingGiftUniqueSpoofSettings) {
            GiftUniqueSpoofSettingsView(viewModel: viewModel)
        }
        .sheet(item: $viewModel.availableUpdate) { update in
            UpdateAvailableView(
                update: update,
                onOpenRelease: {
                    viewModel.openReleasePage(update)
                    viewModel.availableUpdate = nil
                },
                onClose: {
                    viewModel.availableUpdate = nil
                }
            )
        }
        .task {
            await viewModel.checkForUpdatesOnLaunch()
        }
    }

    private var writeAccessAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.writeAccessAlert != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.writeAccessAlert = nil
                }
            }
        )
    }
}

private struct HeaderBar: View {
    @ObservedObject var viewModel: PatchgramViewModel

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                HStack(spacing: 10) {
                    PatchgramLogo(showsBackground: false)
                        .frame(width: 32, height: 32)
                        .offset(y: 1)
                    Text("Patchgram")
                    Button {
                        viewModel.isShowingAppSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .buttonStyle(.borderless)
                    .help("Settings")
                    .popover(isPresented: $viewModel.isShowingAppSettings, arrowEdge: .top) {
                        AppSettingsView(viewModel: viewModel)
                    }
                }
                .font(.system(size: 22, weight: .semibold))
                Spacer()
                Button {
                    viewModel.openLogsFolder()
                } label: {
                    Label("Logs", systemImage: "doc.text.magnifyingglass")
                }
                .disabled(viewModel.appURL == nil)
                .help("Open the folder with Patchgram logs")
                Button {
                    viewModel.rescanApp()
                } label: {
                    Label("Rescan", systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isWorking || viewModel.appURL == nil)
                Button {
                    viewModel.chooseApp()
                } label: {
                    Label("Choose App", systemImage: "folder")
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isWorking)
            }

            HStack(spacing: 10) {
                Image(systemName: viewModel.isValidApp ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(viewModel.isValidApp ? .green : .orange)
                Text(currentPath)
                    .font(.system(.body, design: .monospaced))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
            }

            HStack(spacing: 10) {
                ProgressView(value: viewModel.operationProgress ?? 0, total: 1)
                    .progressViewStyle(.linear)
                    .opacity(viewModel.operationProgress == nil ? 0.35 : 1)
                    .frame(maxWidth: 260)
                Text(viewModel.statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer()
            }
            .frame(height: 16)
        }
        .padding(18)
    }

    private var currentPath: String {
        viewModel.appURL?.path ?? "No app selected"
    }
}

private struct AppSettingsView: View {
    @ObservedObject var viewModel: PatchgramViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                Image(systemName: "gearshape")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.blue)
                Text("Settings")
                    .font(.title3.weight(.semibold))
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.borderless)
                .controlSize(.small)
                .help("Close")
            }

            Toggle("Check for updates on launch", isOn: $viewModel.updateChecksEnabled)
                .toggleStyle(.checkbox)
                .font(.body)

            HStack(spacing: 10) {
                Button {
                    Task {
                        await viewModel.checkForUpdates()
                        if viewModel.availableUpdate != nil {
                            dismiss()
                        }
                    }
                } label: {
                    Label("Check Now", systemImage: "arrow.down.circle")
                }
                .font(.body)
                .disabled(viewModel.isCheckingForUpdates)

                if viewModel.isCheckingForUpdates {
                    ProgressView()
                        .controlSize(.small)
                }

                Spacer()
            }
        }
        .font(.body)
        .padding(22)
        .frame(width: 360)
    }
}

private struct UpdateAvailableView: View {
    let update: PatchgramAvailableUpdate
    let onOpenRelease: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Update available")
                        .font(.title3.weight(.semibold))
                    Text("Patchgram \(update.currentVersion) -> \(update.latestVersion)")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(update.releaseName)
                    .font(.headline)
                ScrollView {
                    Text(changelogText)
                        .font(.system(size: 12))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(minHeight: 160, maxHeight: 260)
                .padding(10)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            HStack(spacing: 10) {
                Spacer()
                Button("Later") {
                    onClose()
                }
                Button {
                    onOpenRelease()
                } label: {
                    Label("Open Release", systemImage: "safari")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(22)
        .frame(width: 520)
    }

    private var changelogText: String {
        update.changelog.isEmpty ? "No changelog provided." : update.changelog
    }
}

private struct Sidebar: View {
    @ObservedObject var viewModel: PatchgramViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StatBlock(
                title: "Executable",
                value: viewModel.executableSize,
                symbol: "terminal"
            )
            StatBlock(
                title: "Enabled rules",
                value: "\(viewModel.enabledCount)",
                symbol: "checklist.checked"
            )
            StatBlock(
                title: "Pending",
                value: viewModel.hasPendingChanges ? "Yes" : "No",
                symbol: "tray.and.arrow.down"
            )

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    if let icon = viewModel.selectedAppIcon {
                        Image(nsImage: icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                    } else {
                        Image(systemName: "app")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text("Selected app")
                }
                .font(.headline)
                Text(viewModel.appInfo)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                if !viewModel.binaryRows.isEmpty {
                    let available = viewModel.binaryRows.filter { $0.status.state != .unavailable }.count
                    Text("\(available) of \(viewModel.binaryRows.count) patches available for this client version")
                        .font(.caption)
                        .foregroundStyle(available == viewModel.binaryRows.count ? .green : .secondary)
                }
                Text("The selected bundle must be writable before patching.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Label("Changed targets", systemImage: "doc.text")
                    .font(.headline)
                if viewModel.lastChangedFiles.isEmpty {
                    Text("No changes")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.lastChangedFiles, id: \.self) { file in
                        Text(file)
                            .font(.system(size: 11, design: .monospaced))
                            .lineLimit(2)
                            .textSelection(.enabled)
                    }
                }
            }

            Spacer()
        }
        .padding(18)
        .background(Color(nsColor: .underPageBackgroundColor))
    }
}

private struct StatBlock: View {
    let title: String
    let value: String
    let symbol: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 28, height: 28)
                .foregroundStyle(.blue)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(size: 18, weight: .semibold))
            }
            Spacer()
        }
    }
}

private struct RuleList: View {
    @ObservedObject var viewModel: PatchgramViewModel
    @State private var openCategory: BinaryPatchCategory?

    var body: some View {
        ZStack {
            if let category = openCategory,
               let section = PatchgramViewModel.sections.first(where: { $0.category == category }) {
                SectionDetail(viewModel: viewModel, section: section) {
                    withAnimation(.easeInOut(duration: 0.18)) { openCategory = nil }
                }
                .transition(.opacity)
            } else {
                SectionMenu(viewModel: viewModel) { category in
                    viewModel.searchText = ""
                    withAnimation(.easeInOut(duration: 0.18)) { openCategory = category }
                }
                .transition(.opacity)
            }
        }
    }
}

// Main menu: the 4 patch sections.
private struct SectionMenu: View {
    @ObservedObject var viewModel: PatchgramViewModel
    let onOpen: (BinaryPatchCategory) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Label("Patches", systemImage: "square.grid.2x2")
                    .font(.headline)
                Spacer()
                Button {
                    Task { await viewModel.updatePatches() }
                } label: {
                    Label("Update patches", systemImage: "arrow.down.circle")
                }
                .disabled(viewModel.isUpdatingPatches || viewModel.isWorking)
                .help("Fetch the latest signed patch bundle (engine + patches) from GitHub")
            }
            .padding(18)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(PatchgramViewModel.sections) { section in
                        SectionCard(section: section, count: viewModel.rowCount(in: section.category)) {
                            onOpen(section.category)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 18)
            }
        }
    }
}

// One section's patches, with the same filters as before + back (button / Esc / two-finger swipe).
private struct SectionDetail: View {
    @ObservedObject var viewModel: PatchgramViewModel
    let section: PatchgramViewModel.PatchSection
    let onBack: () -> Void
    @State private var isShowingFilters = false
    @State private var swipeMonitor: Any?

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button(action: onBack) {
                    Label("Sections", systemImage: "chevron.left")
                }
                .keyboardShortcut(.cancelAction)
                .help("Back to sections (Esc)")
                Divider().frame(height: 18)
                SectionIcon(name: section.icon, inset: 3).frame(width: 22, height: 22)
                Text(section.title).font(.headline)
                TextField("Search method or constructor", text: $viewModel.searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 280)
                Button {
                    isShowingFilters.toggle()
                } label: {
                    Label("Filters", systemImage: "line.3.horizontal.decrease.circle")
                }
                .popover(isPresented: $isShowingFilters, arrowEdge: .bottom) {
                    VStack(alignment: .leading, spacing: 14) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Type").font(.caption).foregroundStyle(.secondary)
                            Picker("Type", selection: $viewModel.deliveryFilter) {
                                ForEach(PatchDeliveryFilter.allCases) { filter in
                                    Text(filter.label).tag(filter)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sort").font(.caption).foregroundStyle(.secondary)
                            Picker("Sort", selection: $viewModel.sortOrder) {
                                ForEach(PatchSortOrder.allCases) { order in
                                    Text(order.label).tag(order)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                    .padding(14)
                    .frame(width: 260)
                }
                Spacer()
            }
            .padding(18)

            let rows = viewModel.filteredRows(in: section.category)
            if rows.isEmpty {
                Spacer()
                Text(viewModel.searchText.isEmpty ? "No patches in this section." : "No patches match your search.")
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(rows) { row in
                            BinaryRuleCard(row: row, isWorking: viewModel.isWorking) { enabled in
                                viewModel.setDesired(enabled, for: row)
                            } onSubpatchToggle: { ruleId, subpatchId, enabled in
                                viewModel.setSubpatch(ruleId: ruleId, subpatchId: subpatchId, enabled: enabled)
                            } onSubpatchChange: { ruleId, subpatchId in
                                viewModel.changeSubpatch(ruleId: ruleId, subpatchId: subpatchId)
                            } onUpdate: {
                                viewModel.updateAppliedPatch(for: row)
                            } onSettings: { ruleId, subpatchId in
                                viewModel.showSubpatchSettings(ruleId: ruleId, subpatchId: subpatchId)
                            } onRuleSettings: {
                                if row.status.rule.kind == .starGiftSpoof {
                                    viewModel.showGiftSpoofSettings()
                                } else if row.status.rule.kind == .starGiftUniqueSpoof {
                                    viewModel.showGiftUniqueSpoofSettings()
                                } else {
                                    viewModel.showBotVerificationSettings()
                                }
                            } onOpenLogs: {
                                viewModel.openMtprotoLogsFolder()
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 18)
                }
            }
        }
        // Two-finger trackpad swipe-right → back. Vertical scrolls are ignored (deltaX must dominate).
        .onAppear {
            swipeMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
                if event.scrollingDeltaX > 45, abs(event.scrollingDeltaX) > abs(event.scrollingDeltaY) * 2.5 {
                    onBack()
                }
                return event
            }
        }
        .onDisappear {
            if let swipeMonitor { NSEvent.removeMonitor(swipeMonitor) }
            swipeMonitor = nil
        }
    }
}

private struct SectionCard: View {
    let section: PatchgramViewModel.PatchSection
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                SectionIcon(name: section.icon, inset: 10).frame(width: 46, height: 46)
                VStack(alignment: .leading, spacing: 3) {
                    Text(section.title).font(.system(size: 17, weight: .semibold))
                    Text(section.description).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(count)").font(.system(.body, design: .rounded)).foregroundStyle(.secondary)
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// Renders a section's white-line SVG, tinted white inside a gradient tile.
private struct SectionIcon: View {
    let name: String
    var inset: CGFloat = 10

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color(red: 0.22, green: 0.66, blue: 0.98), Color(red: 0.08, green: 0.39, blue: 0.83)],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
            if let image = Self.image(named: name) {
                Image(nsImage: image)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .padding(inset)
                    .foregroundStyle(.white)
            } else {
                Image(systemName: "square.grid.2x2")
                    .foregroundStyle(.white)
            }
        }
    }

    private static func image(named name: String) -> NSImage? {
        for url in appResourceURLs(named: "section-\(name)", extension: "svg") {
            guard let url, let image = NSImage(contentsOf: url) else { continue }
            image.isTemplate = true
            return image
        }
        return nil
    }
}

private struct BinaryRuleCard: View {
    let row: BinaryRuleRowState
    let isWorking: Bool
    let onToggle: @MainActor @Sendable (Bool) -> Void
    let onSubpatchToggle: @MainActor @Sendable (String, String, Bool) -> Void
    let onSubpatchChange: @MainActor @Sendable (String, String) -> Void
    let onUpdate: @MainActor @Sendable () -> Void
    let onSettings: @MainActor @Sendable (String, String) -> Void
    let onRuleSettings: @MainActor @Sendable () -> Void
    let onOpenLogs: @MainActor @Sendable () -> Void
    @State private var showsSubpatches = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text(row.status.rule.title)
                            .font(.system(size: 17, weight: .semibold))
                        AvailabilityBadge(isAvailable: row.status.state != .unavailable)
                        DeliveryBadge(label: row.patchDeliveryLabel, usesDylib: row.usesDylibPatch)
                        StateBadge(state: row.status.state, pendingState: row.needsApply ? (isWorking ? .pending : .selected) : nil)
                    }
                    Text(row.status.rule.methodName)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                HStack(alignment: .center, spacing: 10) {
                    UpdatePatchButton(title: row.updateButtonTitle, isDisabled: isWorking, action: onUpdate)
                    if row.id == "binary.mtproto.logger" {
                        Button {
                            onOpenLogs()
                        } label: {
                            Label("Open logs", systemImage: "doc.text.magnifyingglass")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                        .help("Open the MTProto logger's log files (logs_mtproto_pg)")
                    }
                    if row.status.rule.kind == .botVerification || row.status.rule.kind == .starGiftSpoof || row.status.rule.kind == .starGiftUniqueSpoof {
                        Button {
                            onRuleSettings()
                        } label: {
                            Label("Settings", systemImage: "gearshape")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                        .help(row.status.rule.kind == .starGiftSpoof ? "Configure profile gift spoofing"
                              : row.status.rule.kind == .starGiftUniqueSpoof ? "Configure profile unique gift spoofing"
                              : "Manage bot verification presets")
                        .disabled(isWorking)
                    }
                    Toggle("", isOn: Binding(
                        get: { row.desiredEnabled },
                        set: { value in onToggle(value) }
                    ))
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .disabled(isWorking || row.status.state == .unavailable)
                    .frame(height: 32, alignment: .center)
                }
                .frame(height: 32, alignment: .center)
            }

            Text(row.status.rule.summary)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            if !row.subpatches.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            showsSubpatches.toggle()
                        }
                    } label: {
                        HStack(spacing: 7) {
                            Image(systemName: showsSubpatches ? "chevron.down" : "chevron.right")
                                .font(.caption.weight(.semibold))
                                .frame(width: 12)
                            Text("Subpatches")
                            if let summary = row.subpatchSummary {
                                Text(summary)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(isWorking)

                    if showsSubpatches {
                        VStack(spacing: 6) {
                            ForEach(row.subpatches) { subpatch in
                                SubpatchToggleRow(
                                    subpatch: subpatch,
                                    isWorking: isWorking,
                                    onToggle: { subpatchId, enabled in
                                        onSubpatchToggle(row.id, subpatchId, enabled)
                                    },
                                    onChange: { subpatchId in
                                        onSubpatchChange(row.id, subpatchId)
                                    },
                                    onSettings: {
                                        onSettings(row.id, subpatch.id)
                                    }
                                )
                            }
                        }
                        .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.18), value: showsSubpatches)
            }
        }
        .padding(14)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 0.6)
        }
    }
}

private struct BotVerificationSettingsView: View {
    @ObservedObject var viewModel: PatchgramViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var customEmojiId = ""
    @State private var description = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Label("Bot Verification Settings", systemImage: "checkmark.seal")
                    .font(.headline)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Label("Done", systemImage: "checkmark")
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(18)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Presets")
                            .font(.headline)
                        BotVerificationPresetRow(
                            title: BotVerificationPreset.scaredCat.label,
                            customEmojiId: BotVerificationPatchConfig.scaredCatEmojiId,
                            description: BotVerificationPatchConfig.scaredCatDescription,
                            isBuiltIn: true,
                            onDelete: nil
                        )
                        ForEach(viewModel.botVerificationUserPresets) { preset in
                            BotVerificationPresetRow(
                                title: preset.normalizedTitle,
                                customEmojiId: preset.customEmojiId,
                                description: preset.normalizedDescription,
                                isBuiltIn: false,
                                onDelete: {
                                    viewModel.deleteBotVerificationUserPreset(preset)
                                }
                            )
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Add Preset")
                            .font(.headline)
                        TextField("Name", text: $title)
                            .textFieldStyle(.roundedBorder)
                        TextField("custom_emoji_id", text: $customEmojiId)
                            .textFieldStyle(.roundedBorder)
                        TextField("description", text: $description)
                            .textFieldStyle(.roundedBorder)
                        HStack {
                            Spacer()
                            Button {
                                guard viewModel.addBotVerificationUserPreset(
                                    title: title,
                                    customEmojiIdText: customEmojiId,
                                    description: description
                                ) else {
                                    return
                                }
                                title = ""
                                customEmojiId = ""
                                description = ""
                            } label: {
                                Label("Add", systemImage: "plus")
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(viewModel.isWorking)
                        }
                    }
                }
                .padding(18)
            }
        }
        .frame(width: 520, height: 520)
    }
}

private struct BotVerificationPresetRow: View {
    let title: String
    let customEmojiId: UInt64
    let description: String
    let isBuiltIn: Bool
    let onDelete: (() -> Void)?
    @State private var isConfirmingDelete = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                    if isBuiltIn {
                        Text("Built-in")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                    }
                }
                Text("custom_emoji_id: \(String(customEmojiId))")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                Text("description: \(description)")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
            Spacer()
            if let onDelete {
                Button(role: .destructive) {
                    isConfirmingDelete = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .alert("Delete preset?", isPresented: $isConfirmingDelete) {
                    Button("Cancel", role: .cancel) {}
                    Button("Delete", role: .destructive) {
                        onDelete()
                    }
                } message: {
                    Text("This preset will be removed from Bot verification choices.")
                }
            }
        }
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 0.6)
        }
    }
}

private struct CustomUsernameDraft: Identifiable, Hashable {
    var id = UUID()
    var username: String
    var status: CustomUsernameStatus
    var isPrimary: Bool
    var collectibleInfo: CollectibleInfoDraft
}

private struct CollectibleInfoDraft: Hashable {
    var purchaseDateText: String
    var currency: String
    var amount: String
    var cryptoCurrency: String
    var cryptoAmount: String
    var url: String

    init(_ config: UsernameCollectibleInfoPatchConfig = .defaultConfig) {
        purchaseDateText = config.purchaseDateText
        currency = config.currency
        amount = String(config.amount)
        cryptoCurrency = config.cryptoCurrency
        cryptoAmount = String(config.cryptoAmount)
        url = config.url
    }

    func config(statusMessage: Binding<String>) -> UsernameCollectibleInfoPatchConfig? {
        let amountText = amount.trimmingCharacters(in: .whitespacesAndNewlines)
        let cryptoAmountText = cryptoAmount.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let amountValue = amountText.isEmpty ? 0 : Int64(amountText), amountValue >= 0 else {
            statusMessage.wrappedValue = "Enter a valid collectible amount."
            return nil
        }
        guard let cryptoAmountValue = cryptoAmountText.isEmpty ? 0 : Int64(cryptoAmountText),
              cryptoAmountValue >= 0 else {
            statusMessage.wrappedValue = "Enter a valid collectible crypto amount."
            return nil
        }
        let config = UsernameCollectibleInfoPatchConfig(
            purchaseDateText: purchaseDateText,
            currency: currency,
            amount: amountValue,
            cryptoCurrency: cryptoCurrency,
            cryptoAmount: cryptoAmountValue,
            url: url
        ).normalized
        guard config.purchaseDateUnix != nil else {
            statusMessage.wrappedValue = "Enter purchase date as unix-time or HH:MM:SS dd.mm.yyyy."
            return nil
        }
        guard config.currency.count <= 32, config.cryptoCurrency.count <= 32 else {
            statusMessage.wrappedValue = "Enter currency values up to 32 characters."
            return nil
        }
        guard config.url.count <= 256 else {
            statusMessage.wrappedValue = "Enter a URL up to 256 characters."
            return nil
        }
        return config
    }
}

private struct GiftSpoofSettingsView: View {
    @ObservedObject var viewModel: PatchgramViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var targetMode: BotVerificationTargetMode = .onlySelf
    @State private var senderIdText = "0"
    @State private var dateText = "0"
    @State private var giftIdText = "0"
    @State private var stickerEmojiIdText = "0"
    @State private var starsText = "0"
    @State private var caption = ""
    @State private var availableText = "0"
    @State private var totalText = "0"
    @State private var forceLimited = false
    @State private var forceUpgrade = false
    @State private var forceAuction = false
    @State private var upgradePriceText = "0"
    @State private var auctionTitle = ""
    @State private var giftNumberText = "0"
    @State private var wasRefunded = false
    @State private var isResolvingSticker = false
    @State private var stickerLookupNote = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Label("Spoof Profile Gifts", systemImage: "gift")
                    .font(.headline)
                Spacer()
                Button {
                    viewModel.updateStarGiftSpoofConfig(currentConfig, applyNow: false)
                    dismiss()
                } label: {
                    Label("Save", systemImage: "checkmark")
                }
                .disabled(viewModel.isWorking)
                Button {
                    // Sticker emoji id is required to apply; if missing, keep the window open.
                    if viewModel.updateStarGiftSpoofConfig(currentConfig, applyNow: true) {
                        dismiss()
                    }
                } label: {
                    Label("Save & Apply", systemImage: "bolt.fill")
                }
                .keyboardShortcut(.defaultAction)
                .disabled(viewModel.isWorking)
                Button { dismiss() } label: {
                    Label("Cancel", systemImage: "xmark")
                }
            }
            .padding(18)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Rewrite the star gifts shown on a profile. Leave a numeric field at 0 to keep the original value; an empty caption keeps the original message. \"Save & Apply\" updates a running Telegram live — re-open the profile to refresh.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Whose profile")
                            .font(.subheadline).bold()
                        Picker("", selection: $targetMode) {
                            ForEach(BotVerificationTargetMode.allCases, id: \.self) { mode in
                                Text(mode.label).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }

                    field("Sender id", text: $senderIdText, prompt: "0 = keep · user id · -100… = channel")
                    field("Date", text: $dateText, prompt: "0 = keep · unix · HH:mm:ss dd.MM.yyyy")
                    field("Gift id", text: $giftIdText, prompt: "0 = keep original id")

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sticker emoji id")
                            .font(.subheadline).bold()
                        HStack(spacing: 8) {
                            TextField("required — the gift's custom emoji id", text: $stickerEmojiIdText)
                                .textFieldStyle(.roundedBorder)
                            Button {
                                let giftId = giftIdText
                                isResolvingSticker = true
                                stickerLookupNote = ""
                                Task {
                                    let resolved = await viewModel.resolveGiftStickerEmojiId(giftIdText: giftId)
                                    isResolvingSticker = false
                                    if let resolved {
                                        stickerEmojiIdText = String(resolved)
                                    } else {
                                        stickerLookupNote = "No emoji for that gift id on the API."
                                    }
                                }
                            } label: {
                                Text("Get id from gift")
                            }
                            .disabled(isResolvingSticker)
                        }
                        if isResolvingSticker {
                            Text("Looking up…").font(.caption).foregroundStyle(.secondary)
                        } else if !stickerLookupNote.isEmpty {
                            Text(stickerLookupNote).font(.caption).foregroundStyle(.orange)
                        } else {
                            Text("Required to apply. Use an animated (TGS/WEBM) custom emoji so it renders inside the gift, not just in the list.")
                                .font(.caption).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    field("Stars price", text: $starsText, prompt: "0 = keep original price")

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Badges")
                            .font(.subheadline).bold()
                        Toggle("Limited", isOn: $forceLimited)
                        if forceLimited {
                            HStack(alignment: .top, spacing: 12) {
                                field("Supply available", text: $availableText, prompt: "availability_remains (0 = sold out)")
                                field("Supply total", text: $totalText, prompt: "availability_total")
                            }
                            .padding(.leading, 20)
                        }
                        Toggle("Can upgrade", isOn: $forceUpgrade)
                        if forceUpgrade {
                            field("Upgrade price", text: $upgradePriceText, prompt: "0 = default (25⭐) · upgrade_stars")
                                .padding(.leading, 20)
                        }
                        Toggle("Auction", isOn: $forceAuction)
                        if forceAuction {
                            VStack(alignment: .leading, spacing: 4) {
                                field("Auction title", text: $auctionTitle, prompt: "gift name (starGift.title)")
                                field("Gift number", text: $giftNumberText, prompt: "0 = none · savedStarGift.gift_num")
                            }
                            .padding(.leading, 20)
                        }
                        Toggle("Was refunded", isOn: $wasRefunded)
                        Text("Supply lives under Limited and is written exactly as entered. Badges/caption make room by clearing the sticker preview; if a gift can't fit, that gift is left unchanged (no crash).")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .toggleStyle(.checkbox)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Caption")
                            .font(.subheadline).bold()
                        TextField("Empty = keep original message", text: $caption)
                            .textFieldStyle(.roundedBorder)
                        Text("Adding a caption clears the sticker preview to free room, and only applies when it fits the existing response.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(18)
            }
        }
        .frame(width: 560, height: 600)
        .onAppear(perform: load)
    }

    @ViewBuilder
    private func field(_ title: String, text: Binding<String>, prompt: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline).bold()
            TextField(prompt, text: text)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var currentConfig: StarGiftSpoofPatchConfig {
        StarGiftSpoofPatchConfig(
            targetMode: targetMode,
            senderIdText: senderIdText,
            dateText: dateText,
            giftIdText: giftIdText,
            stickerEmojiIdText: stickerEmojiIdText,
            starsText: starsText,
            caption: caption,
            availableText: availableText,
            totalText: totalText,
            forceLimited: forceLimited,
            forceUpgrade: forceUpgrade,
            forceAuction: forceAuction,
            upgradePriceText: upgradePriceText,
            auctionTitle: auctionTitle,
            giftNumberText: giftNumberText,
            wasRefunded: wasRefunded
        )
    }

    private func load() {
        let c = viewModel.starGiftSpoofConfig.normalized
        targetMode = c.targetMode
        senderIdText = c.senderIdText
        dateText = c.dateText
        giftIdText = c.giftIdText
        stickerEmojiIdText = c.stickerEmojiIdText
        starsText = c.starsText
        caption = c.caption
        availableText = c.availableText
        totalText = c.totalText
        forceLimited = c.forceLimited
        forceUpgrade = c.forceUpgrade
        forceAuction = c.forceAuction
        upgradePriceText = c.upgradePriceText
        auctionTitle = c.auctionTitle
        giftNumberText = c.giftNumberText
        wasRefunded = c.wasRefunded
    }
}

/// GroupBox style for the gift settings sections: native-looking rounded fill but with a bit more inner
/// padding so the label + content breathe away from the box edges.
private struct PaddedSectionGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            configuration.label
            configuration.content
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.quaternary.opacity(0.5))
        )
    }
}

private struct GiftUniqueSpoofSettingsView: View {
    @ObservedObject var viewModel: PatchgramViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var targetMode: BotVerificationTargetMode = .onlySelf
    @State private var giftName = ""
    @State private var title = ""
    @State private var numText = "0"
    @State private var selectedBackdropName = ""
    @State private var bdCenter: Int32 = 0
    @State private var bdEdge: Int32 = 0
    @State private var bdPattern: Int32 = 0
    @State private var bdText: Int32 = 0
    @State private var bdRarity: Int32 = 0
    @State private var selectedModelName = ""
    @State private var modelEmojiId: Int64 = 0
    @State private var modelRarity: Int32 = 0
    @State private var selectedSymbolName = ""
    @State private var symbolEmojiId: Int64 = 0
    @State private var symbolRarity: Int32 = 0
    @State private var totalUpgradedText = "0"
    @State private var maxUpgradedText = "0"
    @State private var modelCustom = false
    @State private var modelCustomName = ""
    @State private var modelCustomId = ""
    @State private var modelCustomPct = ""
    @State private var symbolCustom = false
    @State private var symbolCustomName = ""
    @State private var symbolCustomId = ""
    @State private var symbolCustomPct = ""
    @State private var suppressGiftReset = false
    @State private var senderText = ""
    @State private var ownerText = ""
    @State private var hostEnabled = false
    @State private var hostText = ""
    @State private var ownerAddressEnabled = false
    @State private var ownerAddressText = ""
    @State private var dateText = "0"
    @State private var valueCurrencyText = ""
    @State private var valueAmountText = ""
    @State private var valueUsdAmountText = ""
    @State private var lastResaleCurrencyText = ""
    @State private var lastResaleAmountText = ""
    @State private var lastResaleDateText = "0"

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Label("Spoof Profile Unique Gifts", systemImage: "sparkles")
                    .font(.headline)
                Spacer()
                Button {
                    viewModel.updateStarGiftUniqueSpoofConfig(currentConfig, applyNow: false)
                    dismiss()
                } label: { Label("Save", systemImage: "checkmark") }
                .disabled(viewModel.isWorking)
                Button {
                    if viewModel.updateStarGiftUniqueSpoofConfig(currentConfig, applyNow: true) {
                        dismiss()
                    }
                } label: { Label("Save & Apply", systemImage: "bolt.fill") }
                .keyboardShortcut(.defaultAction)
                .disabled(viewModel.isWorking)
                Button { dismiss() } label: { Label("Cancel", systemImage: "xmark") }
            }
            .padding(18)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Make a profile's gift show as an upgraded (unique) gift. Works on already-unique gifts AND converts regular gifts. Pick a gift for its real model/symbol/backdrop lists, or “Empty” to type fully-custom model/symbol ids with backdrops from the full list. \"Save & Apply\" updates a running Telegram live — re-open the profile to refresh.")
                        .font(.callout).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    GroupBox {
                        Picker("", selection: $targetMode) {
                            ForEach(BotVerificationTargetMode.allCases, id: \.self) { mode in
                                Text(mode.label).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented).labelsHidden()
                    } label: { Text("Whose profile").font(.subheadline).bold() }

                    GroupBox {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Picker("", selection: $giftName) {
                                    Text("Select a gift…").tag("")
                                    Text("Empty (fully custom)").tag(PatchgramViewModel.emptyGiftName)
                                    ForEach(viewModel.uniqueGiftNames, id: \.self) { name in
                                        Text(name).tag(name)
                                    }
                                }
                                .labelsHidden().pickerStyle(.menu)
                                .onChange(of: giftName) { newValue in
                                    if suppressGiftReset { suppressGiftReset = false; return }
                                    selectedBackdropName = ""; bdCenter = 0; bdEdge = 0; bdPattern = 0; bdText = 0; bdRarity = 0
                                    selectedModelName = ""; modelEmojiId = 0; modelRarity = 0
                                    selectedSymbolName = ""; symbolEmojiId = 0; symbolRarity = 0
                                    if newValue == PatchgramViewModel.emptyGiftName { modelCustom = true; symbolCustom = true }
                                    viewModel.loadUniqueGiftBackdrops(forGift: newValue)
                                }
                                if viewModel.isLoadingUniqueGiftData { ProgressView().controlSize(.small) }
                                Button {
                                    viewModel.refreshUniqueGiftCatalog(currentGift: giftName)
                                } label: { Label("Update lists", systemImage: "arrow.clockwise") }
                                .controlSize(.small)
                                .disabled(viewModel.isLoadingUniqueGiftData)
                            }
                            field("Title", text: $title, prompt: "Empty = use the chosen gift's name")
                            field("Unique number", text: $numText, prompt: "0 = keep · the “#N” shown on the gift")
                            HStack(alignment: .top, spacing: 12) {
                                field("Upgraded (issued)", text: $totalUpgradedText, prompt: "0 = default · “N” in “N of M”")
                                field("Max (total)", text: $maxUpgradedText, prompt: "0 = default · “M”")
                            }
                        }
                    } label: { Text("Gift").font(.subheadline).bold() }

                    GroupBox {
                        if giftName.isEmpty {
                            Text("Pick a gift (or “Empty”) to set its model, symbol and backdrop.")
                                .font(.caption).foregroundStyle(.secondary)
                        } else {
                            VStack(alignment: .leading, spacing: 10) {
                                attributeBlock(
                                    title: "Model", custom: $modelCustom,
                                    customName: $modelCustomName, customId: $modelCustomId, customPct: $modelCustomPct,
                                    selected: $selectedModelName, options: viewModel.uniqueGiftModels,
                                    keepLabel: "Keep original model",
                                    onPick: { m in modelEmojiId = m?.customEmojiId ?? 0; modelRarity = m?.rarityPermille ?? 0 }
                                )
                                attributeBlock(
                                    title: "Symbol", custom: $symbolCustom,
                                    customName: $symbolCustomName, customId: $symbolCustomId, customPct: $symbolCustomPct,
                                    selected: $selectedSymbolName, options: viewModel.uniqueGiftSymbols,
                                    keepLabel: "Keep original symbol",
                                    onPick: { s in symbolEmojiId = s?.customEmojiId ?? 0; symbolRarity = s?.rarityPermille ?? 0 }
                                )
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Backdrop").font(.subheadline).bold()
                                    Picker("", selection: $selectedBackdropName) {
                                        Text("Keep original backdrop").tag("")
                                        ForEach(viewModel.uniqueGiftBackdrops) { drop in
                                            Text("\(drop.name) · \(rarityLabel(drop.rarityPermille))").tag(drop.name)
                                        }
                                    }
                                    .labelsHidden().pickerStyle(.menu)
                                    .onChange(of: selectedBackdropName) { newValue in
                                        if let drop = viewModel.uniqueGiftBackdrops.first(where: { $0.name == newValue }) {
                                            bdCenter = drop.centerColor; bdEdge = drop.edgeColor
                                            bdPattern = drop.patternColor; bdText = drop.textColor
                                            bdRarity = drop.rarityPermille
                                        }
                                    }
                                    if !selectedBackdropName.isEmpty {
                                        HStack(spacing: 6) {
                                            swatch(bdCenter); swatch(bdEdge); swatch(bdPattern); swatch(bdText)
                                            Text("center · edge · pattern · text").font(.caption).foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    } label: { Text("Appearance").font(.subheadline).bold() }

                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            field("Sender (from)", text: $senderText, prompt: "empty = base · user id · -100… = channel")
                            field("Owner", text: $ownerText, prompt: "empty = keep · user id · -100… = channel")
                            field("Date", text: $dateText, prompt: "0 = keep · HH:mm:ss dd.MM.yyyy · or unix")
                            VStack(alignment: .leading, spacing: 4) {
                                Toggle("Host", isOn: $hostEnabled).toggleStyle(.checkbox)
                                if hostEnabled {
                                    TextField("host peer id · -100… = channel", text: $hostText).textFieldStyle(.roundedBorder)
                                }
                            }
                            .onChange(of: hostEnabled) { isOn in
                                // host needs an owner address to render → turning host on also turns it on
                                // (but enabling owner address alone never flips host on).
                                if isOn { ownerAddressEnabled = true }
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Toggle("Owner address", isOn: $ownerAddressEnabled).toggleStyle(.checkbox)
                                if ownerAddressEnabled {
                                    TextField("TON owner address", text: $ownerAddressText).textFieldStyle(.roundedBorder)
                                }
                            }
                        }
                    } label: { Text("Identity").font(.subheadline).bold() }

                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Value")
                                .font(.caption).foregroundStyle(.secondary)
                            HStack(alignment: .top, spacing: 12) {
                                field("Currency", text: $valueCurrencyText, prompt: "empty = keep · e.g. TON")
                                field("Amount", text: $valueAmountText, prompt: "0 = keep · raw long")
                            }
                            field("USD amount", text: $valueUsdAmountText, prompt: "0 = keep · raw long")
                            Divider()
                            Text("Last resale")
                                .font(.caption).foregroundStyle(.secondary)
                            HStack(alignment: .top, spacing: 12) {
                                field("Currency", text: $lastResaleCurrencyText, prompt: "empty = keep · e.g. TON")
                                field("Amount", text: $lastResaleAmountText, prompt: "0 = keep · raw long")
                            }
                            field("Last resale date", text: $lastResaleDateText, prompt: "0 = keep · HH:mm:ss dd.MM.yyyy · or unix")
                            Text("Last-resale fields need a gift that already has resale history (else only its current value updates).")
                                .font(.caption2).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                        }
                    } label: { Text("Value").font(.subheadline).bold() }

                    Text(GiftChangesAPI.attribution)
                        .font(.caption2).foregroundStyle(.secondary).padding(.top, 2)
                }
                .padding(18)
                .groupBoxStyle(PaddedSectionGroupBoxStyle())
            }
        }
        .frame(width: 560, height: 680)
        .onAppear(perform: load)
    }

    @ViewBuilder
    private func field(_ title: String, text: Binding<String>, prompt: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.subheadline).bold()
            TextField(prompt, text: text).textFieldStyle(.roundedBorder)
        }
    }

    /// Model/Symbol block: a Custom toggle (locked on for the "Empty" gift) switching between a
    /// list pick and three typed fields (name / emoji id / rarity %).
    @ViewBuilder
    private func attributeBlock(
        title: String,
        custom: Binding<Bool>,
        customName: Binding<String>,
        customId: Binding<String>,
        customPct: Binding<String>,
        selected: Binding<String>,
        options: [GiftChangesAttribute],
        keepLabel: String,
        onPick: @escaping (GiftChangesAttribute?) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 14) {
                Text(title).font(.subheadline).bold()
                Toggle("Custom", isOn: custom).toggleStyle(.checkbox).font(.caption)
                    .disabled(giftName == PatchgramViewModel.emptyGiftName)
                Spacer()
            }
            if custom.wrappedValue {
                TextField("\(title.lowercased()) name", text: customName).textFieldStyle(.roundedBorder)
                TextField("custom emoji id (document id)", text: customId).textFieldStyle(.roundedBorder)
                TextField("rarity %, e.g. 0.5", text: customPct).textFieldStyle(.roundedBorder)
            } else {
                Picker("", selection: selected) {
                    Text(keepLabel).tag("")
                    ForEach(options) { o in
                        Text("\(o.name) · \(rarityLabel(o.rarityPermille))").tag(o.name)
                    }
                }
                .labelsHidden().pickerStyle(.menu)
                .onChange(of: selected.wrappedValue) { newValue in
                    onPick(options.first(where: { $0.name == newValue }))
                }
            }
        }
    }

    private func swatch(_ rgb: Int32) -> some View {
        let v = UInt32(bitPattern: rgb)
        let r = Double((v >> 16) & 0xFF) / 255.0
        let g = Double((v >> 8) & 0xFF) / 255.0
        let b = Double(v & 0xFF) / 255.0
        return RoundedRectangle(cornerRadius: 4)
            .fill(Color(red: r, green: g, blue: b))
            .frame(width: 22, height: 22)
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(.secondary.opacity(0.4)))
    }

    private func rarityLabel(_ permille: Int32) -> String {
        String(format: "%.1f%%", Double(permille) / 10.0)
    }

    private var currentConfig: StarGiftUniqueSpoofPatchConfig {
        // Model/symbol: custom mode = typed name + id + rarity%; else the list pick.
        let pctToPermille: (String) -> Int32 = { Int32(((Double($0.trimmingCharacters(in: .whitespaces)) ?? 0) * 10).rounded()) }
        let mCustomName = modelCustomName.trimmingCharacters(in: .whitespaces)
        let mName = modelCustom ? (mCustomName.isEmpty ? "Custom" : mCustomName) : selectedModelName
        let mId = modelCustom ? (Int64(modelCustomId.trimmingCharacters(in: .whitespaces)) ?? 0) : modelEmojiId
        let mRar = modelCustom ? pctToPermille(modelCustomPct) : modelRarity
        let sCustomName = symbolCustomName.trimmingCharacters(in: .whitespaces)
        let sName = symbolCustom ? (sCustomName.isEmpty ? "Custom" : sCustomName) : selectedSymbolName
        let sId = symbolCustom ? (Int64(symbolCustomId.trimmingCharacters(in: .whitespaces)) ?? 0) : symbolEmojiId
        let sRar = symbolCustom ? pctToPermille(symbolCustomPct) : symbolRarity
        return StarGiftUniqueSpoofPatchConfig(
            targetMode: targetMode,
            giftName: giftName,
            title: title,
            numText: numText,
            backdropName: selectedBackdropName,
            backdropCenterColor: bdCenter,
            backdropEdgeColor: bdEdge,
            backdropPatternColor: bdPattern,
            backdropTextColor: bdText,
            backdropRarityPermille: bdRarity,
            modelName: mName,
            modelEmojiId: mId,
            modelRarityPermille: mRar,
            symbolName: sName,
            symbolEmojiId: sId,
            symbolRarityPermille: sRar,
            totalUpgradedText: totalUpgradedText,
            maxUpgradedText: maxUpgradedText,
            modelCustom: modelCustom,
            symbolCustom: symbolCustom,
            senderText: senderText,
            ownerText: ownerText,
            hostEnabled: hostEnabled,
            hostText: hostText,
            ownerAddressEnabled: ownerAddressEnabled,
            ownerAddressText: ownerAddressText,
            dateText: dateText,
            valueCurrencyText: valueCurrencyText,
            valueAmountText: valueAmountText,
            valueUsdAmountText: valueUsdAmountText,
            lastResaleCurrencyText: lastResaleCurrencyText,
            lastResaleAmountText: lastResaleAmountText,
            lastResaleDateText: lastResaleDateText
        )
    }

    private func load() {
        let c = viewModel.starGiftUniqueSpoofConfig.normalized
        targetMode = c.targetMode
        suppressGiftReset = (giftName != c.giftName)  // setting giftName below would otherwise wipe selections
        giftName = c.giftName
        title = c.title
        numText = c.numText
        selectedBackdropName = c.backdropName
        bdCenter = c.backdropCenterColor
        bdEdge = c.backdropEdgeColor
        bdPattern = c.backdropPatternColor
        bdText = c.backdropTextColor
        bdRarity = c.backdropRarityPermille
        totalUpgradedText = c.totalUpgradedText
        maxUpgradedText = c.maxUpgradedText
        modelCustom = c.modelCustom
        symbolCustom = c.symbolCustom
        senderText = c.senderText
        ownerText = c.ownerText
        hostEnabled = c.hostEnabled
        hostText = c.hostText
        ownerAddressEnabled = c.ownerAddressEnabled
        ownerAddressText = c.ownerAddressText
        dateText = c.dateText
        valueCurrencyText = c.valueCurrencyText
        valueAmountText = c.valueAmountText
        valueUsdAmountText = c.valueUsdAmountText
        lastResaleCurrencyText = c.lastResaleCurrencyText
        lastResaleAmountText = c.lastResaleAmountText
        lastResaleDateText = c.lastResaleDateText
        let permilleToPct: (Int32) -> String = { $0 == 0 ? "" : String(format: "%g", Double($0) / 10.0) }
        if c.modelCustom {
            modelCustomName = (c.modelName == "Custom") ? "" : c.modelName
            modelCustomId = c.modelEmojiId != 0 ? String(c.modelEmojiId) : ""
            modelCustomPct = permilleToPct(c.modelRarityPermille)
        } else {
            selectedModelName = c.modelName; modelEmojiId = c.modelEmojiId; modelRarity = c.modelRarityPermille
        }
        if c.symbolCustom {
            symbolCustomName = (c.symbolName == "Custom") ? "" : c.symbolName
            symbolCustomId = c.symbolEmojiId != 0 ? String(c.symbolEmojiId) : ""
            symbolCustomPct = permilleToPct(c.symbolRarityPermille)
        } else {
            selectedSymbolName = c.symbolName; symbolEmojiId = c.symbolEmojiId; symbolRarity = c.symbolRarityPermille
        }
        viewModel.loadUniqueGiftCatalogIfNeeded()
        if !c.giftName.isEmpty { viewModel.loadUniqueGiftBackdrops(forGift: c.giftName) }
    }
}

private struct CustomListUsernamesSettingsView: View {
    @ObservedObject var viewModel: PatchgramViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var entries: [CustomUsernameDraft] = []
    @State private var useSharedCollectibleInfo = true
    @State private var sharedInfo = CollectibleInfoDraft()

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Label("Custom List Usernames", systemImage: "at")
                    .font(.headline)
                Spacer()
                Button {
                    addEntry()
                } label: {
                    Label("Add", systemImage: "plus")
                }
                Button {
                    save()
                } label: {
                    Label("Save", systemImage: "checkmark")
                }
                .keyboardShortcut(.defaultAction)
                Button {
                    if save() {
                        dismiss()
                    }
                } label: {
                    Label("Done", systemImage: "xmark")
                }
            }
            .padding(18)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Toggle("Use one collectible info for all collectible usernames", isOn: $useSharedCollectibleInfo)
                        .toggleStyle(.checkbox)

                    if useSharedCollectibleInfo {
                        CollectibleInfoEditor(title: "Shared collectible info", draft: $sharedInfo)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Usernames")
                            .font(.headline)
                        if entries.isEmpty {
                            Text("No usernames")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach($entries) { $entry in
                                CustomUsernameDraftRow(
                                    entry: $entry,
                                    useSharedCollectibleInfo: useSharedCollectibleInfo,
                                    onMakePrimary: {
                                        setPrimary(entry.id)
                                    },
                                    onDelete: {
                                        let wasPrimary = entry.isPrimary
                                        entries.removeAll { $0.id == entry.id }
                                        if wasPrimary {
                                            ensurePrimary()
                                        }
                                    }
                                )
                            }
                        }
                    }
                }
                .padding(18)
            }
        }
        .frame(width: 720, height: 620)
        .onAppear(perform: load)
    }

    private func load() {
        let config = viewModel.customListUsernamesConfigForSettings()
        useSharedCollectibleInfo = config.useSharedCollectibleInfo
        sharedInfo = CollectibleInfoDraft(config.sharedCollectibleInfo)
        entries = config.entries.map {
            CustomUsernameDraft(
                id: $0.id,
                username: $0.username,
                status: $0.status,
                isPrimary: $0.isPrimary,
                collectibleInfo: CollectibleInfoDraft($0.collectibleInfo)
            )
        }
    }

    private func addEntry() {
        entries.append(
            CustomUsernameDraft(
                username: "",
                status: .default,
                isPrimary: entries.isEmpty,
                collectibleInfo: CollectibleInfoDraft(sharedInfo.config(statusMessage: .constant("")) ?? .defaultConfig)
            )
        )
    }

    private func setPrimary(_ id: UUID) {
        entries = entries.map { entry in
            var next = entry
            next.isPrimary = entry.id == id
            return next
        }
    }

    private func ensurePrimary() {
        guard !entries.isEmpty, !entries.contains(where: \.isPrimary) else {
            return
        }
        entries[0].isPrimary = true
    }

    @discardableResult
    private func save() -> Bool {
        let sharedConfig: UsernameCollectibleInfoPatchConfig
        if let config = sharedInfo.config(statusMessage: $viewModel.statusMessage) {
            sharedConfig = config
        } else {
            return false
        }
        let primaryId = entries.first(where: \.isPrimary)?.id ?? entries.first?.id
        let configs: [CustomUsernameEntryPatchConfig] = entries.compactMap { draft in
            let username = CustomUsernameEntryPatchConfig.normalizedUsername(draft.username)
            guard CustomUsernameEntryPatchConfig.isValidUsername(username) else {
                viewModel.statusMessage = "Enter usernames up to \(CustomUsernameEntryPatchConfig.maxUsernameLength) characters using letters, digits, underscore, dot or dash."
                return nil
            }
            let info: UsernameCollectibleInfoPatchConfig
            if useSharedCollectibleInfo {
                info = sharedConfig
            } else if let config = draft.collectibleInfo.config(statusMessage: $viewModel.statusMessage) {
                info = config
            } else {
                return nil
            }
            return CustomUsernameEntryPatchConfig(
                id: draft.id,
                username: username,
                status: draft.status,
                isPrimary: draft.id == primaryId,
                collectibleInfo: info
            )
        }
        guard configs.count == entries.count else { return false }
        viewModel.updateCustomListUsernamesConfig(
            CustomListUsernamesPatchConfig(
                entries: configs,
                useSharedCollectibleInfo: useSharedCollectibleInfo,
                sharedCollectibleInfo: sharedConfig
            )
        )
        entries = configs.map {
            CustomUsernameDraft(
                id: $0.id,
                username: $0.username,
                status: $0.status,
                isPrimary: $0.isPrimary,
                collectibleInfo: CollectibleInfoDraft($0.collectibleInfo)
            )
        }
        return true
    }
}

private struct CustomUsernameDraftRow: View {
    @Binding var entry: CustomUsernameDraft
    let useSharedCollectibleInfo: Bool
    let onMakePrimary: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                TextField("username", text: $entry.username)
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 180)
                    .onChange(of: entry.username) { value in
                        guard value.count > CustomUsernameEntryPatchConfig.maxUsernameLength else {
                            return
                        }
                        entry.username = String(value.prefix(CustomUsernameEntryPatchConfig.maxUsernameLength))
                    }
                Picker("Status", selection: $entry.status) {
                    ForEach(CustomUsernameStatus.allCases, id: \.self) { status in
                        Text(status.label).tag(status)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 220)
                Button {
                    onMakePrimary()
                } label: {
                    Label(entry.isPrimary ? "First" : "Make First", systemImage: entry.isPrimary ? "1.circle.fill" : "1.circle")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(entry.isPrimary)
                Spacer()
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .buttonStyle(.bordered)
            }

            if entry.status == .collectible && !useSharedCollectibleInfo {
                CollectibleInfoEditor(title: "Collectible info", draft: $entry.collectibleInfo)
            }
        }
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 0.6)
        }
    }
}

private struct CollectibleInfoEditor: View {
    let title: String
    @Binding var draft: CollectibleInfoDraft

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
            labeledField("Purchase date", text: $draft.purchaseDateText, placeholder: "0 or 12:34:56 07.06.2026")
            HStack(spacing: 10) {
                labeledField("Currency", text: $draft.currency, placeholder: "USD")
                labeledField("Amount", text: $draft.amount, placeholder: "0")
            }
            HStack(spacing: 10) {
                labeledField("Crypto", text: $draft.cryptoCurrency, placeholder: "TON")
                labeledField("Crypto amount", text: $draft.cryptoAmount, placeholder: "0")
            }
            labeledField("URL", text: $draft.url, placeholder: "https://fragment.com/username/...")
        }
    }

    private func labeledField(_ title: String, text: Binding<String>, placeholder: String) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .frame(width: 104, alignment: .trailing)
            TextField(placeholder, text: text)
                .textFieldStyle(.roundedBorder)
        }
    }
}

private struct SubpatchToggleRow: View {
    let subpatch: BinarySubpatchRowState
    let isWorking: Bool
    let onToggle: @MainActor @Sendable (String, Bool) -> Void
    let onChange: @MainActor @Sendable (String) -> Void
    let onSettings: @MainActor @Sendable () -> Void

    var body: some View {
        Button {
            guard !isWorking else { return }
            onToggle(subpatch.id, !subpatch.desiredEnabled)
        } label: {
            HStack(spacing: 10) {
                Text(subpatch.title)
                    .font(.system(size: 13, weight: .medium))
                Spacer()
                if subpatch.desiredEnabled != subpatch.appliedEnabled {
                    Text(subpatch.desiredEnabled ? "Selected" : "Will disable")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(subpatch.desiredEnabled ? .blue : .orange)
                } else if subpatch.parametersChanged {
                    Text("Parameters changed")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.blue)
                }
                if subpatch.showsChangeButton && subpatch.desiredEnabled {
                    Button("Change") {
                        onChange(subpatch.id)
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                    .disabled(isWorking)
                }
                if subpatch.showsSettingsButton {
                    Button {
                        onSettings()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .buttonStyle(.borderless)
                    .help("Manage bot verification presets")
                    .disabled(isWorking)
                }
                Toggle("", isOn: .constant(subpatch.desiredEnabled))
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .allowsHitTesting(false)
            }
            .padding(.horizontal, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isWorking)
        .frame(minHeight: 26)
    }
}

private struct DeliveryBadge: View {
    let label: String
    let usesDylib: Bool

    var body: some View {
        Text(label)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .foregroundStyle(usesDylib ? .indigo : .brown)
            .background((usesDylib ? Color.indigo : Color.brown).opacity(0.14))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

private struct AvailabilityBadge: View {
    let isAvailable: Bool

    var body: some View {
        Text(isAvailable ? "Available" : "Unavailable")
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .foregroundStyle(isAvailable ? .green : .red)
            .background((isAvailable ? Color.green : Color.red).opacity(0.14))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .help(isAvailable
                ? "This patch matches the selected Telegram version."
                : "This patch does not match the selected Telegram version and can't be toggled.")
    }
}

private struct UpdatePatchButton: View {
    let title: String?
    let isDisabled: Bool
    let action: @MainActor @Sendable () -> Void

    var body: some View {
        Group {
            if let title {
                Button {
                    action()
                } label: {
                    Label(title, systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .help(title == "Change" ? "Change patch value" : "Update patch")
                .disabled(isDisabled)
            } else {
                Color.clear
            }
        }
        .frame(width: 96, height: 32, alignment: .trailing)
    }
}

private struct StateBadge: View {
    enum PendingState {
        case selected
        case pending
    }

    let state: RuleApplicationState
    let pendingState: PendingState?

    var body: some View {
        Text(displayLabel)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .foregroundStyle(displayForeground)
            .background(displayBackground.opacity(0.16))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    private var displayLabel: String {
        switch pendingState {
        case .selected:
            return "Selected"
        case .pending:
            return "Pending"
        case nil:
            return label
        }
    }

    private var displayForeground: Color {
        switch pendingState {
        case .selected:
            return .blue
        case .pending:
            return .orange
        case nil:
            return foreground
        }
    }

    private var displayBackground: Color {
        switch pendingState {
        case .selected:
            return .blue
        case .pending:
            return .orange
        case nil:
            return background
        }
    }

    private var label: String {
        switch state {
        case .applied: "Enabled"
        case .notApplied: "Disabled"
        case .partial: "Partial"
        case .unavailable: "Unavailable"
        }
    }

    private var foreground: Color {
        switch state {
        case .applied: .green
        case .notApplied: .secondary
        case .partial: .orange
        case .unavailable: .red
        }
    }

    private var background: Color {
        switch state {
        case .applied: .green
        case .notApplied: .gray
        case .partial: .orange
        case .unavailable: .red
        }
    }
}

private struct FooterBar: View {
    @ObservedObject var viewModel: PatchgramViewModel
    @State private var isShowingAbout = false
    @State private var isConfirmingDisableAll = false

    var body: some View {
        HStack(spacing: 12) {
            Text(viewModel.patchStateSummary)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer()
            Button {
                isShowingAbout = true
            } label: {
                Label("About", systemImage: "info.circle")
            }
            .popover(isPresented: $isShowingAbout, arrowEdge: .bottom) {
                AboutView {
                    isShowingAbout = false
                }
            }
            Button {
                viewModel.restoreOriginalBinary()
            } label: {
                Label("Restore Backup", systemImage: "arrow.uturn.backward")
            }
            .disabled(viewModel.isWorking || !viewModel.isValidApp)
            Button(role: .destructive) {
                isConfirmingDisableAll = true
            } label: {
                Label("Disable All", systemImage: "power")
            }
            .disabled(viewModel.isWorking || !viewModel.isValidApp || !viewModel.hasAnyAppliedBinary)
            .alert("Disable all patches?", isPresented: $isConfirmingDisableAll) {
                Button("Cancel", role: .cancel) {}
                Button("Disable All", role: .destructive) {
                    viewModel.disableAll()
                }
            } message: {
                Text("Are you sure you want to disable all patches?")
            }
            Button {
                viewModel.applyChanges()
            } label: {
                Label("Apply", systemImage: "checkmark.circle")
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isWorking || !viewModel.isValidApp || !viewModel.hasPendingChanges)
        }
        .padding(14)
    }
}

private struct AboutView: View {
    let onClose: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 18) {
                PatchgramLogo(showsBackground: false)
                    .frame(width: 84, height: 84)

                VStack(spacing: 5) {
                    Text("Patchgram")
                        .font(.system(size: 22, weight: .semibold))
                    Text(AppVersion.displayString)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Text("Native macOS patcher for Telegram Desktop")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 10) {
                    Link(destination: URL(string: "https://github.com/patchgram/osx")!) {
                        Label {
                            Text("GitHub")
                        } icon: {
                            GitHubIcon()
                                .frame(width: 15, height: 15)
                        }
                    }
                    .buttonStyle(.bordered)

                    Link(destination: URL(string: "https://t.me/patchgram")!) {
                        Label {
                            Text("Telegram")
                        } icon: {
                            TelegramIcon()
                                .frame(width: 15, height: 15)
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(28)
            .frame(width: 360)

            Button {
                onClose()
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.borderless)
            .controlSize(.small)
            .help("Close")
            .padding(12)
        }
    }
}

private enum AppVersion {
    static var displayString: String {
        let info = Bundle.main.infoDictionary ?? [:]
        let shortVersion = info["CFBundleShortVersionString"] as? String
        let buildVersion = info["CFBundleVersion"] as? String

        switch (shortVersion?.isEmpty == false ? shortVersion : nil, buildVersion?.isEmpty == false ? buildVersion : nil) {
        case let (short?, build?) where short != build:
            return "Version \(short) (\(build))"
        case let (short?, _):
            return "Version \(short)"
        case let (_, build?):
            return "Version \(build)"
        default:
            return "Version unknown"
        }
    }
}

private struct PatchgramLogo: View {
    var showsBackground = true

    var body: some View {
        ZStack {
            if showsBackground {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.22, green: 0.66, blue: 0.98),
                                Color(red: 0.08, green: 0.39, blue: 0.83)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            if let image = Self.image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(showsBackground ? 8 : 0)
            } else {
                Image(systemName: "switch.2")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(showsBackground ? .white : .primary)
            }
        }
        .shadow(color: showsBackground ? .black.opacity(0.12) : .clear, radius: 3, y: 1)
        .accessibilityLabel("Patchgram")
    }

    private static let image: NSImage? = {
        for url in appResourceURLs(named: "PatchgramLogo", extension: "svg") {
            guard let url, let image = NSImage(contentsOf: url) else { continue }
            image.isTemplate = false
            return image
        }
        return nil
    }()
}

private struct GitHubIcon: View {
    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let rect = CGRect(
                x: (proxy.size.width - size) / 2,
                y: (proxy.size.height - size) / 2,
                width: size,
                height: size
            )

            Path { path in
                path.addEllipse(in: rect.insetBy(dx: size * 0.16, dy: size * 0.24))
                path.move(to: CGPoint(x: rect.minX + size * 0.29, y: rect.minY + size * 0.37))
                path.addLine(to: CGPoint(x: rect.minX + size * 0.24, y: rect.minY + size * 0.13))
                path.addLine(to: CGPoint(x: rect.minX + size * 0.45, y: rect.minY + size * 0.27))
                path.closeSubpath()
                path.move(to: CGPoint(x: rect.minX + size * 0.71, y: rect.minY + size * 0.37))
                path.addLine(to: CGPoint(x: rect.minX + size * 0.76, y: rect.minY + size * 0.13))
                path.addLine(to: CGPoint(x: rect.minX + size * 0.55, y: rect.minY + size * 0.27))
                path.closeSubpath()
                path.addRoundedRect(
                    in: CGRect(
                        x: rect.minX + size * 0.38,
                        y: rect.minY + size * 0.67,
                        width: size * 0.24,
                        height: size * 0.22
                    ),
                    cornerSize: CGSize(width: size * 0.07, height: size * 0.07)
                )
            }
            .fill(.primary)
        }
        .accessibilityHidden(true)
    }
}

private struct TelegramIcon: View {
    var body: some View {
        Group {
            if let image = Self.image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.blue)
            }
        }
        .accessibilityHidden(true)
    }

    private static let image: NSImage? = {
        for url in appResourceURLs(named: "TelegramLogo", extension: "svg") {
            guard let url, let image = NSImage(contentsOf: url) else { continue }
            image.isTemplate = false
            return image
        }
        return nil
    }()
}

func appResourceURLs(named name: String, extension fileExtension: String) -> [URL?] {
    let resourceURL = Bundle.main.resourceURL
    return [
        Bundle.main.url(forResource: name, withExtension: fileExtension),
        resourceURL?.appendingPathComponent("\(name).\(fileExtension)"),
        resourceURL?
            .appendingPathComponent("Patchgram_Patchgram.bundle", isDirectory: true)
            .appendingPathComponent("\(name).\(fileExtension)")
    ]
}
