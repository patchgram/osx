public final class BinaryCorePatchModule: BinaryPatchRuleModule {
    public override class var order: Int { 10 }

    public override class var rules: [BinaryPatchRule] {
        BinaryPatchRuleDefinitions.rules(withIds: [
            "binary.presence.force_offline",
            "binary.messages.settings",
            "binary.links.open_without_warning",
            "binary.privacy.no_phone_on_add",
            "binary.accounts.limit_999"
        ])
    }
}
