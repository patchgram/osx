import Foundation
import CryptoKit

/// Metadata for one externalized patch bundle (a `patches-vN` GitHub release). The bundle ships
/// `patches.json`, `engine.c.template`, this `patch-manifest.json`, and a detached Ed25519
/// signature `patch-manifest.json.sig` over the exact manifest bytes. The per-file SHA-256 hashes
/// chain the signed manifest to the actual file contents.
public struct PatchBundleManifest: Codable, Sendable, Equatable {
    /// Monotonic bundle version; an update is offered only when this exceeds the installed one.
    public var bundleVersion: Int
    /// Lowest Patchgram app version (CFBundleShortVersionString) that may apply this bundle.
    public var minAppVersion: String
    /// filename → lowercase SHA-256 hex of that file's bytes.
    public var files: [String: String]
    public var notes: String?

    public init(bundleVersion: Int, minAppVersion: String, files: [String: String], notes: String? = nil) {
        self.bundleVersion = bundleVersion
        self.minAppVersion = minAppVersion
        self.files = files
        self.notes = notes
    }
}

public enum PatchBundleVerificationError: Error, Equatable {
    case pinnedKeyInvalid
    case badSignature
    case malformedManifest
    case missingFile(String)
    case fileHashMismatch(String)
    case appTooOld(minAppVersion: String)
}

/// Verifies a fetched patch bundle before it is allowed to touch the cache. The pinned Ed25519
/// public key is the trust anchor: a bundle is accepted only if the detached signature over the
/// manifest validates against this key AND every file's SHA-256 matches the signed manifest. This
/// gates an arbitrary-code-execution path (the engine C is compiled and injected into Telegram), so
/// any failure rejects the whole bundle — never a partial apply.
public struct PatchBundleVerifier: Sendable {
    /// Base64 of the 32-byte raw Ed25519 public key. Replace via `scripts/generate-signing-key.sh`
    /// if you rotate keys; the matching private key signs releases in the patches workflow.
    public static let pinnedPublicKeyBase64 = "dD62L078DiLD2mTnCvDIE3RzbRXcvSo0FPJjnHQmYqQ="

    public init() {}

    public func publicKey() throws -> Curve25519.Signing.PublicKey {
        guard let raw = Data(base64Encoded: Self.pinnedPublicKeyBase64),
              let key = try? Curve25519.Signing.PublicKey(rawRepresentation: raw) else {
            throw PatchBundleVerificationError.pinnedKeyInvalid
        }
        return key
    }

    /// Returns the validated manifest, or throws on the first failure. `files` maps each filename in
    /// the manifest to its downloaded bytes. `signature` is the raw 64-byte Ed25519 signature.
    @discardableResult
    public func verify(
        manifestData: Data,
        signature: Data,
        files: [String: Data],
        appVersion: String
    ) throws -> PatchBundleManifest {
        let key = try publicKey()
        guard key.isValidSignature(signature, for: manifestData) else {
            throw PatchBundleVerificationError.badSignature
        }
        guard let manifest = try? JSONDecoder().decode(PatchBundleManifest.self, from: manifestData) else {
            throw PatchBundleVerificationError.malformedManifest
        }
        for (name, expectedHex) in manifest.files {
            guard let data = files[name] else {
                throw PatchBundleVerificationError.missingFile(name)
            }
            let actual = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
            guard actual == expectedHex.lowercased() else {
                throw PatchBundleVerificationError.fileHashMismatch(name)
            }
        }
        guard PatchBundleVerifier.version(appVersion, isAtLeast: manifest.minAppVersion) else {
            throw PatchBundleVerificationError.appTooOld(minAppVersion: manifest.minAppVersion)
        }
        return manifest
    }

    /// Semantic-ish version compare on dot-separated integer components ("1.0.4" >= "1.0.4").
    public static func version(_ lhs: String, isAtLeast rhs: String) -> Bool {
        func parts(_ s: String) -> [Int] {
            s.trimmingCharacters(in: .whitespaces)
                .drop { $0 == "v" || $0 == "V" }
                .split(separator: ".")
                .map { Int($0.prefix { $0.isNumber }) ?? 0 }
        }
        let a = parts(lhs), b = parts(rhs)
        for i in 0..<max(a.count, b.count) {
            let x = i < a.count ? a[i] : 0
            let y = i < b.count ? b[i] : 0
            if x != y { return x > y }
        }
        return true
    }
}
