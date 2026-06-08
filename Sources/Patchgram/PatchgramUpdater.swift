import Foundation

struct PatchgramAvailableUpdate: Identifiable, Equatable {
    let id: String
    let currentVersion: String
    let latestVersion: String
    let releaseName: String
    let changelog: String
    let releaseURL: URL
}

enum PatchgramUpdater {
    static let releasesURL = URL(string: "https://api.github.com/repos/patchgram/osx/releases/latest")!

    static var currentVersion: String {
        let info = Bundle.main.infoDictionary ?? [:]
        let shortVersion = (info["CFBundleShortVersionString"] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return shortVersion?.isEmpty == false ? shortVersion! : "0.0.0"
    }

    static func checkForUpdate() async throws -> PatchgramAvailableUpdate? {
        var request = URLRequest(url: releasesURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("Patchgram", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, !(200..<300).contains(httpResponse.statusCode) {
            throw PatchgramUpdaterError.unexpectedStatus(httpResponse.statusCode)
        }

        let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
        guard !release.draft, !release.prerelease else {
            return nil
        }

        let current = normalizedVersion(currentVersion)
        let latest = normalizedVersion(release.tagName)
        guard compareVersions(latest, current) == .orderedDescending else {
            return nil
        }

        return PatchgramAvailableUpdate(
            id: release.tagName,
            currentVersion: displayVersion(currentVersion),
            latestVersion: displayVersion(release.tagName),
            releaseName: release.name.isEmpty ? displayVersion(release.tagName) : release.name,
            changelog: release.body.trimmingCharacters(in: .whitespacesAndNewlines),
            releaseURL: release.htmlURL
        )
    }

    private static func normalizedVersion(_ version: String) -> [Int] {
        let trimmed = version
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingPrefix("v")
            .trimmingPrefix("V")
        return trimmed
            .split(separator: ".", omittingEmptySubsequences: false)
            .map { component in
                let numericPrefix = component.prefix { $0.isNumber }
                return Int(numericPrefix) ?? 0
            }
    }

    private static func compareVersions(_ lhs: [Int], _ rhs: [Int]) -> ComparisonResult {
        let count = max(lhs.count, rhs.count)
        for index in 0..<count {
            let left = index < lhs.count ? lhs[index] : 0
            let right = index < rhs.count ? rhs[index] : 0
            if left < right {
                return .orderedAscending
            }
            if left > right {
                return .orderedDescending
            }
        }
        return .orderedSame
    }

    private static func displayVersion(_ version: String) -> String {
        let trimmed = version.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.trimmingPrefix("v").trimmingPrefix("V")
    }
}

private struct GitHubRelease: Decodable {
    let tagName: String
    let name: String
    let body: String
    let htmlURL: URL
    let draft: Bool
    let prerelease: Bool

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case body
        case htmlURL = "html_url"
        case draft
        case prerelease
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        tagName = try container.decode(String.self, forKey: .tagName)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        body = try container.decodeIfPresent(String.self, forKey: .body) ?? ""
        htmlURL = try container.decode(URL.self, forKey: .htmlURL)
        draft = try container.decodeIfPresent(Bool.self, forKey: .draft) ?? false
        prerelease = try container.decodeIfPresent(Bool.self, forKey: .prerelease) ?? false
    }
}

private enum PatchgramUpdaterError: LocalizedError {
    case unexpectedStatus(Int)

    var errorDescription: String? {
        switch self {
        case let .unexpectedStatus(statusCode):
            return "GitHub returned HTTP \(statusCode)."
        }
    }
}

private extension String {
    func trimmingPrefix(_ prefix: Character) -> String {
        guard first == prefix else {
            return self
        }
        return String(dropFirst())
    }
}
