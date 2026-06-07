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
        .alert(item: $viewModel.writeAccessAlert) { alert in
            Alert(
                title: Text("Permission required"),
                message: Text(alert.message),
                primaryButton: .default(Text("Open Settings")) {
                    viewModel.openFullDiskAccessSettings()
                },
                secondaryButton: .cancel()
            )
        }
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
                }
                .font(.system(size: 22, weight: .semibold))
                Spacer()
                Button {
                    viewModel.rescanApp()
                } label: {
                    Label("Rescan", systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isWorking || viewModel.appURL == nil)
                Button {
                    viewModel.copySelectedApp()
                } label: {
                    Label("Copy App", systemImage: "doc.on.doc")
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
                Text("Patch a copy unless you intentionally want to modify the selected bundle.")
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

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Label("Rules", systemImage: "slider.horizontal.3")
                    .font(.headline)
                TextField("Search method or constructor", text: $viewModel.searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 360)
                Picker("Filters", selection: $viewModel.deliveryFilter) {
                    ForEach(PatchDeliveryFilter.allCases) { filter in
                        Text(filter.label).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 210)
                Spacer()
            }
            .padding(18)

            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.filteredBinaryRows) { row in
                        BinaryRuleCard(row: row, isWorking: viewModel.isWorking) { enabled in
                            viewModel.setDesired(enabled, for: row)
                        } onSubpatchToggle: { ruleId, subpatchId, enabled in
                            viewModel.setSubpatch(ruleId: ruleId, subpatchId: subpatchId, enabled: enabled)
                        } onUpdate: {
                            viewModel.updateAppliedPatch(for: row)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 18)
            }
        }
    }
}

private struct BinaryRuleCard: View {
    let row: BinaryRuleRowState
    let isWorking: Bool
    let onToggle: @MainActor @Sendable (Bool) -> Void
    let onSubpatchToggle: @MainActor @Sendable (String, String, Bool) -> Void
    let onUpdate: @MainActor @Sendable () -> Void
    @State private var showsSubpatches = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text(row.status.rule.title)
                            .font(.system(size: 17, weight: .semibold))
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
                                .contentTransition(.symbolEffect(.replace))
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

private struct SubpatchToggleRow: View {
    let subpatch: BinarySubpatchRowState
    let isWorking: Bool
    let onToggle: @MainActor @Sendable (String, Bool) -> Void

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
            .disabled(viewModel.isWorking || !viewModel.isValidApp)
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
        let urls = [
            Bundle.main.url(forResource: "PatchgramLogo", withExtension: "svg"),
            Bundle.module.url(forResource: "PatchgramLogo", withExtension: "svg")
        ]

        for url in urls {
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
        let urls = [
            Bundle.main.url(forResource: "TelegramLogo", withExtension: "svg"),
            Bundle.module.url(forResource: "TelegramLogo", withExtension: "svg")
        ]

        for url in urls {
            guard let url, let image = NSImage(contentsOf: url) else { continue }
            image.isTemplate = false
            return image
        }
        return nil
    }()
}
