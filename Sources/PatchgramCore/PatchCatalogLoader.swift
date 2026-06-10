import Foundation

/// On-disk shape of `patches.json`: modules (preserving group + order) each holding their rules.
struct PatchCatalogFile: Codable {
    var schemaVersion: Int
    var modules: [PatchCatalogModule]
}

struct PatchCatalogModule: Codable {
    var moduleId: String
    var order: Int
    var rules: [BinaryPatchRule]
}

/// Decodes the externalized patch catalog (`patches.json`, bundled default or fetched cache) into
/// the in-memory `[BinaryPatchRule]`, preserving the module `(order, moduleId)` flatten order that
/// `BinaryPatchRuleCatalog` used when the rules were Swift literals.
enum PatchCatalogLoader {
    static func decode(_ data: Data) throws -> PatchCatalogFile {
        try JSONDecoder().decode(PatchCatalogFile.self, from: data)
    }

    static func flattenedRules(from file: PatchCatalogFile) -> [BinaryPatchRule] {
        file.modules
            .filter { !$0.rules.isEmpty }
            .sorted { $0.order != $1.order ? $0.order < $1.order : $0.moduleId < $1.moduleId }
            .flatMap(\.rules)
    }

    /// The active catalog: the provider's patches.json (cache override → bundled). Falls back to the
    /// bundled default if a fetched cache file is malformed, so a bad update can't empty the catalog.
    static func load(provider: PatchgramResourceProvider = .shared) -> [BinaryPatchRule] {
        if let file = try? decode(provider.patchesJSON()) {
            return flattenedRules(from: file)
        }
        if let bundled = try? decode(provider.bundledData(named: PatchgramResourceProvider.patchesJSONName)) {
            return flattenedRules(from: bundled)
        }
        return []
    }
}
