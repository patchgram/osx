public final class BinaryInlinePatchModule: BinaryPatchRuleModule {
    public override class var order: Int { 20 }

    public override class var rules: [BinaryPatchRule] {
        BinaryPatchRuleDefinitions.rules(withIds: [
            "binary.inline.callback_hover"
        ])
    }
}
