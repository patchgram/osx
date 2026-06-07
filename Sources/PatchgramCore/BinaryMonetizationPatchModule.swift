public final class BinaryMonetizationPatchModule: BinaryPatchRuleModule {
    public override class var order: Int { 30 }

    public override class var rules: [BinaryPatchRule] {
        BinaryPatchRuleDefinitions.rules(withIds: [
            "binary.config.disable_monetization",
            "binary.premium.local",
            "binary.display.custom_ton",
            "binary.display.custom_stars"
        ])
    }
}
