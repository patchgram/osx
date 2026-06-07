public final class BinaryStoriesPatchModule: BinaryPatchRuleModule {
    public override class var order: Int { 50 }

    public override class var rules: [BinaryPatchRule] {
        BinaryPatchRuleDefinitions.rules(withIds: [
            "binary.stories.hide"
        ])
    }
}
