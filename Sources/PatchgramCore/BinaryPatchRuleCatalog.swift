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

    public static let rules: [BinaryPatchRule] = {
        let flattened = modules.flatMap(\.rules)
        let duplicateIds = Dictionary(grouping: flattened, by: \.id)
            .filter { $0.value.count > 1 }
            .map(\.key)
            .sorted()
        precondition(duplicateIds.isEmpty, "Duplicate binary patch rule ids: \(duplicateIds.joined(separator: ", "))")
        return flattened
    }()

    public static func rule(id: String) -> BinaryPatchRule? {
        rules.first { $0.id == id }
    }
}
