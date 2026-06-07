public final class BinaryRuntimePatchModule: BinaryPatchRuleModule {
    public override class var order: Int { 35 }

    public override class var rules: [BinaryPatchRule] {
        BinaryPatchRuleDefinitions.rules(withIds: [
            "binary.visual.sensitive_blur"
        ])
    }
}
