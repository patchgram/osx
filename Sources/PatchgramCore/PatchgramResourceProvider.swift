import Foundation

/// Supplies the two externalized Patchgram artifacts — the patch catalog (`patches.json`) and the
/// dylib engine source (`engine.c.template`) — preferring an on-disk cache (written by a future
/// "Update patches" fetch) over the version bundled inside the app.
///
/// Phase 1 ships only the bundled defaults; the cache directory is normally empty, so the provider
/// returns the bundled bytes and behavior is identical to a fully-compiled-in catalog. The provider
/// never throws for a missing/unreadable cache file — it silently falls back to the bundle so a bad
/// cached update can never brick the app.
public struct PatchgramResourceProvider: Sendable {
    public static let shared = PatchgramResourceProvider()

    public static let patchesJSONName = "patches.json"
    public static let engineTemplateName = "engine.c.template"
    public static let patchManifestName = "patch-manifest.json"

    private let cacheDirectoryOverride: URL?

    public init() {
        self.cacheDirectoryOverride = nil
    }

    /// Test seam: point the cache at an arbitrary directory.
    init(cacheDirectory: URL?) {
        self.cacheDirectoryOverride = cacheDirectory
    }

    /// `~/Library/Application Support/Patchgram/cache` — where fetched updates are written. Shares
    /// the `Patchgram` base directory already used for bot-verification presets.
    public var cacheDirectory: URL? {
        if let cacheDirectoryOverride {
            return cacheDirectoryOverride
        }
        guard let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        return base.appendingPathComponent("Patchgram", isDirectory: true)
            .appendingPathComponent("cache", isDirectory: true)
    }

    /// Raw bytes for a resource: the cache copy if present and non-empty, otherwise the bundled default.
    public func data(named name: String) -> Data {
        if let cacheURL = cacheDirectory?.appendingPathComponent(name),
           FileManager.default.fileExists(atPath: cacheURL.path),
           let cached = try? Data(contentsOf: cacheURL),
           !cached.isEmpty {
            return cached
        }
        return bundledData(named: name)
    }

    /// The bundled default bytes shipped inside the app. Traps only if the resource is missing from
    /// the bundle entirely, which is a build/packaging error (the file is a committed resource).
    public func bundledData(named name: String) -> Data {
        let components = name.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        let resource = String(components[0])
        let ext = components.count > 1 ? String(components[1]) : ""
        guard let url = Bundle.module.url(forResource: resource, withExtension: ext),
              let data = try? Data(contentsOf: url) else {
            fatalError("Missing bundled Patchgram resource: \(name). Check Package.swift resources and build-app.sh bundle copy.")
        }
        return data
    }

    public func patchesJSON() -> Data {
        data(named: Self.patchesJSONName)
    }

    public func engineTemplate() -> String {
        String(decoding: data(named: Self.engineTemplateName), as: UTF8.self)
    }

    /// Manifest of the currently active bundle (cache override → bundled default).
    public func patchManifest() -> PatchBundleManifest? {
        try? JSONDecoder().decode(PatchBundleManifest.self, from: data(named: Self.patchManifestName))
    }

    /// Version of the active bundle; 0 if no manifest is present.
    public func installedBundleVersion() -> Int {
        patchManifest()?.bundleVersion ?? 0
    }

    /// Atomically write the verified bundle files into the cache so the next catalog reload / dylib
    /// recompile picks them up. Each file is written via a temp+rename (Data `.atomic`).
    public func writeCacheFiles(_ files: [String: Data]) throws {
        guard let dir = cacheDirectory else {
            throw CocoaError(.fileNoSuchFile)
        }
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        for (name, bytes) in files {
            try bytes.write(to: dir.appendingPathComponent(name), options: .atomic)
        }
    }
}
