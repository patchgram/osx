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
    public static let rlottieLibName = "librlottie.a"

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

    /// Locates `Patchgram_PatchgramCore.bundle` WITHOUT the SwiftPM-generated `Bundle.module`
    /// accessor. On the Xcode-26 toolchain that accessor only checks `Bundle.main.bundleURL` (the
    /// .app ROOT) and a HARDCODED build-machine path — so it loads fine on the dev machine (the
    /// build path exists) but `fatalError`s on every user's machine, even though build-app.sh
    /// installs the bundle into Contents/Resources. We check the real install locations ourselves.
    private static let coreBundle: Bundle = {
        let name = "Patchgram_PatchgramCore.bundle"
        var candidates: [URL] = []
        if let res = Bundle.main.resourceURL { candidates.append(res.appendingPathComponent(name)) }  // Contents/Resources (.app)
        candidates.append(Bundle.main.bundleURL.appendingPathComponent(name))                          // .app root / next to a loose exe
        if let exeDir = Bundle.main.executableURL?.deletingLastPathComponent() {
            candidates.append(exeDir.appendingPathComponent(name))                                      // Contents/MacOS
        }
        for url in candidates where (try? url.checkResourceIsReachable()) == true {
            if let bundle = Bundle(url: url) { return bundle }
        }
        return Bundle.module   // last resort (swift test / running straight from .build)
    }()

    /// The bundled default bytes shipped inside the app. Traps only if the resource is missing from
    /// the bundle entirely, which is a build/packaging error (the file is a committed resource).
    public func bundledData(named name: String) -> Data {
        let components = name.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        let resource = String(components[0])
        let ext = components.count > 1 ? String(components[1]) : ""
        guard let url = Self.coreBundle.url(forResource: resource, withExtension: ext),
              let data = try? Data(contentsOf: url) else {
            fatalError("Missing bundled Patchgram resource: \(name). Check Package.swift resources and build-app.sh bundle copy.")
        }
        return data
    }

    public func patchesJSON() -> Data {
        data(named: Self.patchesJSONName)
    }

    /// On-disk URL of a bundled resource (the file itself, not its bytes) — needed when a tool like
    /// `clang` must reference the path directly (e.g. linking `librlottie.a`). Returns nil if absent.
    public func bundledURL(named name: String) -> URL? {
        let components = name.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        let resource = String(components[0])
        let ext = components.count > 1 ? String(components[1]) : ""
        return Self.coreBundle.url(forResource: resource, withExtension: ext)
    }

    /// Path to the rlottie static library used to render `.tgs` animated stickers — cache copy if a
    /// future update ships one, otherwise the version bundled in the app. Nil if neither exists (an
    /// older app without rlottie); callers must treat `.tgs` support as unavailable in that case.
    public func rlottieLibraryURL() -> URL? {
        if let cacheURL = cacheDirectory?.appendingPathComponent(Self.rlottieLibName),
           FileManager.default.fileExists(atPath: cacheURL.path) {
            return cacheURL
        }
        return bundledURL(named: Self.rlottieLibName)
    }

    public func engineTemplate() -> String {
        String(decoding: data(named: Self.engineTemplateName), as: UTF8.self)
    }

    /// The bundled generated TL-schema C fragment (string pool + ctor/param tables) that fills the
    /// `__PATCHGRAM_TL_SCHEMA_PLACEHOLDER__` in the engine, giving the dylib its in-line MTProto
    /// decoder. Nil on an older app that predates the schema resource → caller substitutes a stub.
    public func tlSchemaInc() -> String? {
        guard let url = Self.coreBundle.url(forResource: "tl_schema", withExtension: "c.inc"),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        return String(decoding: data, as: UTF8.self)
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
