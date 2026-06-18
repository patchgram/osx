import Foundation

// Gift data (upgradable gift names + per-gift backdrops/models/symbols) is sourced from the free,
// unauthenticated @GiftChanges API — thanks to @GiftChanges for this API (api.changes.tg).
// This credit is required by the API and is also surfaced to users in the Spoof-profile-unique-gifts
// settings window. Do not remove it.
public enum GiftChangesAPI {
    public static let attribution = "Gift data: thanks to @GiftChanges (api.changes.tg)"
    private static let base = "https://api.changes.tg"

    /// One backdrop of an upgradable gift: display name + the four colours (RGB ints, exactly the
    /// values the starGiftAttributeBackdrop wire fields take) + rarity in permille.
    public struct Backdrop: Codable, Hashable, Sendable, Identifiable {
        public let name: String
        public let centerColor: Int32
        public let edgeColor: Int32
        public let patternColor: Int32
        public let textColor: Int32
        public let rarityPermille: Int32
        public var id: String { name }

        private enum CodingKeys: String, CodingKey {
            case name, centerColor, edgeColor, patternColor, textColor, rarityPermille
        }
        public init(name: String, centerColor: Int32, edgeColor: Int32, patternColor: Int32, textColor: Int32, rarityPermille: Int32) {
            self.name = name; self.centerColor = centerColor; self.edgeColor = edgeColor
            self.patternColor = patternColor; self.textColor = textColor; self.rarityPermille = rarityPermille
        }
        public init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            name = try c.decode(String.self, forKey: .name)
            centerColor = try c.decodeIfPresent(Int32.self, forKey: .centerColor) ?? 0
            edgeColor = try c.decodeIfPresent(Int32.self, forKey: .edgeColor) ?? 0
            patternColor = try c.decodeIfPresent(Int32.self, forKey: .patternColor) ?? 0
            textColor = try c.decodeIfPresent(Int32.self, forKey: .textColor) ?? 0
            rarityPermille = try c.decodeIfPresent(Int32.self, forKey: .rarityPermille) ?? 0  // global /backdrops has none
        }
    }

    /// A model or symbol (pattern) of an upgradable gift: display name + the custom-emoji document id
    /// that renders its sticker + rarity in permille.
    public struct Attribute: Codable, Hashable, Sendable, Identifiable {
        public let name: String
        public let customEmojiId: Int64
        public let rarityPermille: Int32
        public var id: String { name }
        public init(name: String, customEmojiId: Int64, rarityPermille: Int32) {
            self.name = name; self.customEmojiId = customEmojiId; self.rarityPermille = rarityPermille
        }
    }

    // One model/pattern as /emoji/:gift returns it (id is a JSON string, rarity a percent).
    private struct RawAttribute: Decodable { let name: String; let customEmojiId: String?; let rarity: Double? }
    private static func canon(_ raw: [RawAttribute]) -> [Attribute] {
        raw.map { Attribute(name: $0.name,
                            customEmojiId: Int64($0.customEmojiId ?? "0") ?? 0,
                            rarityPermille: Int32((($0.rarity ?? 0) * 10).rounded())) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// GET /emoji/:gift — the gift's models + patterns (symbols), each with its custom-emoji id. Returns
    /// (models, symbols), both sorted A to Z.
    public static func fetchModelsAndSymbols(gift: String) -> (models: [Attribute], symbols: [Attribute]) {
        guard !gift.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let data = get("/emoji/\(encode(gift: gift))") else { return ([], []) }
        struct Payload: Decodable { let models: [RawAttribute]?; let patterns: [RawAttribute]? }
        guard let p = try? JSONDecoder().decode(Payload.self, from: data) else { return ([], []) }
        return (canon(p.models ?? []), canon(p.patterns ?? []))
    }

    private static func get(_ path: String, timeout: TimeInterval = 8) -> Data? {
        guard let url = URL(string: base + path) else { return nil }
        var request = URLRequest(url: url)
        request.timeoutInterval = timeout
        let semaphore = DispatchSemaphore(value: 0)
        var out: Data?
        URLSession.shared.dataTask(with: request) { data, _, _ in
            out = data
            semaphore.signal()
        }.resume()
        _ = semaphore.wait(timeout: .now() + timeout + 1)
        return out
    }

    private static func encode(gift: String) -> String {
        let trimmed = gift.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? trimmed
    }

    /// GET /gifts — names of all upgradable gifts, returned sorted A→Z (case-insensitive).
    public static func fetchGiftNames() -> [String] {
        guard let data = get("/gifts"),
              let names = try? JSONDecoder().decode([String].self, from: data) else { return [] }
        return names.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    /// GET /backdrops/:gift — the gift's backdrops (name + colours + rarity), sorted A→Z.
    public static func fetchBackdrops(gift: String) -> [Backdrop] {
        guard !gift.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let data = get("/backdrops/\(encode(gift: gift))"),
              let list = try? JSONDecoder().decode([Backdrop].self, from: data) else { return [] }
        return list.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// GET /backdrops — ALL gift backdrops (used by the "Empty" gift, which has no per-gift list), A→Z.
    public static func fetchAllBackdrops() -> [Backdrop] {
        guard let data = get("/backdrops"),
              let list = try? JSONDecoder().decode([Backdrop].self, from: data) else { return [] }
        return list.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}

/// Used by the ViewModel's @Published catalog so the settings window can bind to backdrops/attributes.
public typealias GiftChangesBackdrop = GiftChangesAPI.Backdrop
public typealias GiftChangesAttribute = GiftChangesAPI.Attribute
