public final class BinaryAdsPatchModule: BinaryPatchRuleModule {
    public override class var order: Int { 60 }

    public override class var rules: [BinaryPatchRule] {
        BinaryPatchRuleDefinitions.rules(withIds: [
            "binary.ads.disable_sponsored"
        ])
    }
}
