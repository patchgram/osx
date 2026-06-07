public final class BinaryVisualPatchModule: BinaryPatchRuleModule {
    public override class var order: Int { 40 }

    public override class var rules: [BinaryPatchRule] {
        BinaryPatchRuleDefinitions.rules(withIds: [
            "binary.visual.peer_badge",
            "binary.visual.bot_verification",
            "binary.visual.custom_level_rating",
            "binary.visual.hide_self_phone",
            "binary.visual.no_premium_anim",
            "binary.visual.disable_spoilers"
        ])
    }
}
