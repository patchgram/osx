import Foundation
import PatchgramCore

/// Result of a patch-bundle update check.
enum PatchBundleUpdateOutcome: Equatable {
    case upToDate(version: Int)
    case updated(from: Int, to: Int, notes: String?)
}

enum PatchBundleUpdaterError: LocalizedError {
    case unexpectedStatus(Int)
    case noPatchReleases
    case missingAsset(String)

    var errorDescription: String? {
        switch self {
        case let .unexpectedStatus(code): return "GitHub returned HTTP \(code)."
        case .noPatchReleases: return "No signed patch bundle releases were found."
        case let .missingAsset(name): return "The patch release is missing the `\(name)` asset."
        }
    }
}

/// Fetches the latest signed patch bundle from a `patches-vN` GitHub release, verifies it against the
/// pinned Ed25519 key + per-file SHA-256, and (only on success) writes it into the resource cache so
/// the next catalog reload / dylib recompile uses it. Never writes a partial or unverified bundle.
enum PatchBundleUpdater {
    static let releasesURL = URL(string: "https://api.github.com/repos/patchgram/osx/releases?per_page=30")!
    static let tagPrefix = "patches-v"

    static func checkAndApply(
        appVersion: String,
        provider: PatchgramResourceProvider = .shared
    ) async throws -> PatchBundleUpdateOutcome {
        let releases = try await fetchReleases()
        let candidates = releases.filter { $0.tagName.hasPrefix(tagPrefix) && !$0.draft && !$0.prerelease }
        guard let release = candidates.max(by: { bundleVersion(fromTag: $0.tagName) < bundleVersion(fromTag: $1.tagName) }) else {
            throw PatchBundleUpdaterError.noPatchReleases
        }

        let installed = provider.installedBundleVersion()
        let manifestData = try await download(release, asset: PatchgramResourceProvider.patchManifestName)
        let signature = try await download(release, asset: PatchgramResourceProvider.patchManifestName + ".sig")

        // Pre-parse for an early up-to-date exit; the authoritative check is the verify() below.
        let preview = try JSONDecoder().decode(PatchBundleManifest.self, from: manifestData)
        guard preview.bundleVersion > installed else {
            return .upToDate(version: installed)
        }

        var files: [String: Data] = [:]
        for name in preview.files.keys {
            files[name] = try await download(release, asset: name)
        }

        // Trust gate: Ed25519 signature over the manifest + per-file SHA-256 + min-app-version.
        let verified = try PatchBundleVerifier().verify(
            manifestData: manifestData,
            signature: signature,
            files: files,
            appVersion: appVersion
        )

        var cachePayload = files
        cachePayload[PatchgramResourceProvider.patchManifestName] = manifestData
        try provider.writeCacheFiles(cachePayload)

        return .updated(from: installed, to: verified.bundleVersion, notes: verified.notes)
    }

    // MARK: - GitHub plumbing

    private static func fetchReleases() async throws -> [GitHubReleaseAssets] {
        var request = URLRequest(url: releasesURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("Patchgram", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        try ensureOK(response)
        return try JSONDecoder().decode([GitHubReleaseAssets].self, from: data)
    }

    private static func download(_ release: GitHubReleaseAssets, asset name: String) async throws -> Data {
        guard let asset = release.assets.first(where: { $0.name == name }) else {
            throw PatchBundleUpdaterError.missingAsset(name)
        }
        var request = URLRequest(url: asset.downloadURL)
        request.setValue("application/octet-stream", forHTTPHeaderField: "Accept")
        request.setValue("Patchgram", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        try ensureOK(response)
        return data
    }

    private static func ensureOK(_ response: URLResponse) throws {
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw PatchBundleUpdaterError.unexpectedStatus(http.statusCode)
        }
    }

    private static func bundleVersion(fromTag tag: String) -> Int {
        Int(tag.dropFirst(tagPrefix.count).prefix { $0.isNumber }) ?? 0
    }
}

private struct GitHubReleaseAssets: Decodable {
    let tagName: String
    let draft: Bool
    let prerelease: Bool
    let assets: [Asset]

    struct Asset: Decodable {
        let name: String
        let downloadURL: URL
        enum CodingKeys: String, CodingKey {
            case name
            case downloadURL = "browser_download_url"
        }
    }

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case draft
        case prerelease
        case assets
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        tagName = try c.decode(String.self, forKey: .tagName)
        draft = try c.decodeIfPresent(Bool.self, forKey: .draft) ?? false
        prerelease = try c.decodeIfPresent(Bool.self, forKey: .prerelease) ?? false
        assets = try c.decodeIfPresent([Asset].self, forKey: .assets) ?? []
    }
}
