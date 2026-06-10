import Foundation

open class BinaryPatchRuleModule {
    public required init() {}

    open class var moduleId: String {
        String(describing: Self.self)
    }

    open class var order: Int {
        1_000
    }

    open class var rules: [BinaryPatchRule] {
        []
    }
}

public enum BinaryPatchRuleCatalog {
    public static let modules: [BinaryPatchRuleModule.Type] = GeneratedBinaryPatchRuleRegistry.modules
        .filter { !$0.rules.isEmpty }
        .sorted {
            if $0.order != $1.order {
                return $0.order < $1.order
            }
            return $0.moduleId < $1.moduleId
        }

    // Loaded from the externalized `patches.json` (bundled default → fetched cache), not the Swift
    // module literals, so patches can be updated from GitHub without rebuilding the app. The module
    // classes are retained only to preserve module grouping/order metadata (`modules`).
    //
    // Cached behind a lock and invalidatable via `reloadFromDisk()` so a fetched update takes effect
    // without restarting the app: the cache file changes, `reloadFromDisk()` clears the cache, and
    // the next access (and the next dylib recompile) sees the new rules.
    private static let rulesLock = NSLock()
    nonisolated(unsafe) private static var cachedRules: [BinaryPatchRule]?

    public static var rules: [BinaryPatchRule] {
        rulesLock.lock()
        defer { rulesLock.unlock() }
        if let cachedRules {
            return cachedRules
        }
        let computed = computeRules()
        cachedRules = computed
        return computed
    }

    /// Re-read `patches.json` after a verified update wrote a new cache file. Call on the main actor
    /// before rebuilding the rows / re-applying so the catalog reflects the fetched patches.
    public static func reloadFromDisk() {
        rulesLock.lock()
        cachedRules = nil
        rulesLock.unlock()
    }

    private static func computeRules() -> [BinaryPatchRule] {
        let flattened = PatchCatalogLoader.load()
        let duplicateIds = Dictionary(grouping: flattened, by: \.id)
            .filter { $0.value.count > 1 }
            .map(\.key)
            .sorted()
        precondition(duplicateIds.isEmpty, "Duplicate binary patch rule ids: \(duplicateIds.joined(separator: ", "))")
        return flattened
    }

    public static func rule(id: String) -> BinaryPatchRule? {
        rules.first { $0.id == id }
    }
}
