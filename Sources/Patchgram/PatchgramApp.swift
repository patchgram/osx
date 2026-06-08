import AppKit
import SwiftUI

@main
struct PatchgramApp: App {
    init() {
        NSApplication.shared.appearance = NSAppearance(named: .darkAqua)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 940, minHeight: 660)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Patchgram") {
                    PatchgramAboutPanel.show()
                }
            }
        }
    }
}

private enum PatchgramAboutPanel {
    @MainActor
    static func show() {
        var options: [NSApplication.AboutPanelOptionKey: Any] = [:]
        if let image = patchgramLogoImage() {
            options[.applicationIcon] = image
        }
        NSApplication.shared.orderFrontStandardAboutPanel(options: options)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    private static func patchgramLogoImage() -> NSImage? {
        for url in appResourceURLs(named: "PatchgramLogo", extension: "svg") {
            guard let url, let image = NSImage(contentsOf: url) else { continue }
            image.isTemplate = true
            return image
        }
        return nil
    }
}
