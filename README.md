# Patchgram

![Patchgram](screen/Menu.png)

Required: ARM macOS 12.0+ (Apple Silicon devices), [Telegram Desktop 6.9.3](https://telegram.org/dl/desktop/mac)

Patch list: [RU](patchlist_ru.md) / [EN](patchlist.md)

Enter this command in terminal to fix "The application "Patchgram" can't be opened":
```sh
xattr -dr com.apple.quarantine /Applications/Patchgram.app
```

## Patches

The patcher groups patches into five sections. Each row links to the code that implements it — runtime
behavior lives in the injected hook [`engine.c.template`](Sources/PatchgramCore/Resources/engine.c.template),
and byte-patch / request-rewrite rules are defined in
[`patches.json`](Sources/PatchgramCore/Resources/patches.json). Plain-language descriptions of every patch
are in [patchlist.md](patchlist.md) ([RU](patchlist_ru.md)). To author a new patch (architecture, how to
find sites, write/build/ship a patch, tools), see [docs/patch-authoring.md](docs/patch-authoring.md).

> Code links are pinned to commit [`27d6543`](https://github.com/patchgram/osx/tree/27d6543) so the line
> numbers stay valid as the engine evolves. `engine.c.template:N` = the runtime function; `patches.json:N`
> = the rule (kind, target method, byte patterns).

### Accounts

| Patch | Type | Code |
| --- | --- | --- |
| Always offline | `dylib` | [patches.json:80](https://github.com/patchgram/osx/blob/27d6543/Sources/PatchgramCore/Resources/patches.json#L80) — `forceSerializedBool` on `account.updateStatus` |
| 999 accounts | `binary` | [patches.json:273](https://github.com/patchgram/osx/blob/27d6543/Sources/PatchgramCore/Resources/patches.json#L273) — account-limit byte patch |
| Custom account settings | `dylib` | grouped → [subpatches ↓](#custom-account-settings-subpatches) |
| Block typing activity | `dylib` | [patches.json:110](https://github.com/patchgram/osx/blob/27d6543/Sources/PatchgramCore/Resources/patches.json#L110) — `messages.setTyping` |
| Don't share phone when adding contacts | `dylib` | [patches.json:250](https://github.com/patchgram/osx/blob/27d6543/Sources/PatchgramCore/Resources/patches.json#L250) — `forceSerializedBool` on `contacts.addContact` |

### Messages

| Patch | Type | Code |
| --- | --- | --- |
| Message settings | `dylib` | [patches.json:110](https://github.com/patchgram/osx/blob/27d6543/Sources/PatchgramCore/Resources/patches.json#L110) → [subpatches ↓](#message-settings-subpatches) |
| Show bot callback-data on hover | `dylib` | [patches.json:341](https://github.com/patchgram/osx/blob/27d6543/Sources/PatchgramCore/Resources/patches.json#L341) |
| Sensitive blur | `dylib` | [patches.json:1100](https://github.com/patchgram/osx/blob/27d6543/Sources/PatchgramCore/Resources/patches.json#L1100) |
| Open links without warning | `dylib` | [patches.json:220](https://github.com/patchgram/osx/blob/27d6543/Sources/PatchgramCore/Resources/patches.json#L220) |
| Disable media spoilers | `dylib` | [patches.json:1510](https://github.com/patchgram/osx/blob/27d6543/Sources/PatchgramCore/Resources/patches.json#L1510) |
| Block read messages | `dylib` | [patches.json:110](https://github.com/patchgram/osx/blob/27d6543/Sources/PatchgramCore/Resources/patches.json#L110) — `messages.readHistory` |
| More recent stickers | `dylib` | [patches.json:1123](https://github.com/patchgram/osx/blob/27d6543/Sources/PatchgramCore/Resources/patches.json#L1123) — `kRecentDisplayLimit` 20→200 |

### Optimizations

| Patch | Type | Code |
| --- | --- | --- |
| Disable Premium, Stars, TON & Gifts | `dylib` | [patches.json:377](https://github.com/patchgram/osx/blob/27d6543/Sources/PatchgramCore/Resources/patches.json#L377) |
| Disable premium effects | `dylib` | [patches.json:1488](https://github.com/patchgram/osx/blob/27d6543/Sources/PatchgramCore/Resources/patches.json#L1488) |
| Hide stories | `dylib` | [patches.json:1631](https://github.com/patchgram/osx/blob/27d6543/Sources/PatchgramCore/Resources/patches.json#L1631) |
| Disable ads | `dylib` | [patches.json:1803](https://github.com/patchgram/osx/blob/27d6543/Sources/PatchgramCore/Resources/patches.json#L1803) |

### Gifts

| Patch | Type | Code |
| --- | --- | --- |
| Spoof profile gifts | `dylib` | [engine.c.template:7509](https://github.com/patchgram/osx/blob/27d6543/Sources/PatchgramCore/Resources/engine.c.template#L7509) `patchgram_apply_gift_spoof_response` (rebuild [:6035](https://github.com/patchgram/osx/blob/27d6543/Sources/PatchgramCore/Resources/engine.c.template#L6035)) |
| Show hidden gifts | `dylib` | [engine.c.template:6454](https://github.com/patchgram/osx/blob/27d6543/Sources/PatchgramCore/Resources/engine.c.template#L6454) `patchgram_inject_hidden_gifts` |
| Spoof profile unique gifts | `dylib` | [engine.c.template:7374](https://github.com/patchgram/osx/blob/27d6543/Sources/PatchgramCore/Resources/engine.c.template#L7374) `patchgram_apply_gift_unique_response` (blob [:6845](https://github.com/patchgram/osx/blob/27d6543/Sources/PatchgramCore/Resources/engine.c.template#L6845)) |
| Fake transfer | `dylib` | [engine.c.template:7198](https://github.com/patchgram/osx/blob/27d6543/Sources/PatchgramCore/Resources/engine.c.template#L7198) `patchgram_apply_transfer_response` (updates [:7147](https://github.com/patchgram/osx/blob/27d6543/Sources/PatchgramCore/Resources/engine.c.template#L7147)) |

Custom-emoji auto-load (model/symbol/sticker by id) is shared by the gift patches — append
[engine.c.template:7709](https://github.com/patchgram/osx/blob/27d6543/Sources/PatchgramCore/Resources/engine.c.template#L7709),
capture unique [:6713](https://github.com/patchgram/osx/blob/27d6543/Sources/PatchgramCore/Resources/engine.c.template#L6713) /
spoof [:6377](https://github.com/patchgram/osx/blob/27d6543/Sources/PatchgramCore/Resources/engine.c.template#L6377) /
hidden [:6751](https://github.com/patchgram/osx/blob/27d6543/Sources/PatchgramCore/Resources/engine.c.template#L6751).

### Misc

| Patch | Type | Code |
| --- | --- | --- |
| Dylib injection | `dylib` | [patches.json:12](https://github.com/patchgram/osx/blob/27d6543/Sources/PatchgramCore/Resources/patches.json#L12) — `DYLD_INSERT_LIBRARIES` wrapper ([BinaryPatchEngine.swift:402](https://github.com/patchgram/osx/blob/27d6543/Sources/PatchgramCore/BinaryPatchEngine.swift#L402)) |
| Profile rain overlay | `dylib` | [engine.c.template:9591](https://github.com/patchgram/osx/blob/27d6543/Sources/PatchgramCore/Resources/engine.c.template#L9591) `PatchgramOverlay` (AppKit) |
| MTProto request/response logger | `dylib` | [engine.c.template:7593](https://github.com/patchgram/osx/blob/27d6543/Sources/PatchgramCore/Resources/engine.c.template#L7593) request / [:7652](https://github.com/patchgram/osx/blob/27d6543/Sources/PatchgramCore/Resources/engine.c.template#L7652) response |

### Custom account settings subpatches

| Subpatch | Code |
| --- | --- |
| Custom Stars | [patches.json:1061](https://github.com/patchgram/osx/blob/27d6543/Sources/PatchgramCore/Resources/patches.json#L1061) |
| Custom TON | [patches.json:1028](https://github.com/patchgram/osx/blob/27d6543/Sources/PatchgramCore/Resources/patches.json#L1028) |
| Custom level rating | [patches.json:1358](https://github.com/patchgram/osx/blob/27d6543/Sources/PatchgramCore/Resources/patches.json#L1358) |
| Visual peer badge | [patches.json:1151](https://github.com/patchgram/osx/blob/27d6543/Sources/PatchgramCore/Resources/patches.json#L1151) |
| Bot verification | [patches.json:1345](https://github.com/patchgram/osx/blob/27d6543/Sources/PatchgramCore/Resources/patches.json#L1345) |
| Local Telegram Premium | [patches.json:977](https://github.com/patchgram/osx/blob/27d6543/Sources/PatchgramCore/Resources/patches.json#L977) |
| Custom phone number / userID | [patches.json:1384](https://github.com/patchgram/osx/blob/27d6543/Sources/PatchgramCore/Resources/patches.json#L1384) (`self_identity_override`) |
| Local attached channel | [patches.json:1397](https://github.com/patchgram/osx/blob/27d6543/Sources/PatchgramCore/Resources/patches.json#L1397) |
| Fragment phone | [engine.c.template:4767](https://github.com/patchgram/osx/blob/27d6543/Sources/PatchgramCore/Resources/engine.c.template#L4767) `patchgram_apply_fragment_phone_response` |
| Custom list usernames | [engine.c.template:4227](https://github.com/patchgram/osx/blob/27d6543/Sources/PatchgramCore/Resources/engine.c.template#L4227) `patchgram_apply_custom_username_list_response` |
| Account freeze | [engine.c.template:6587](https://github.com/patchgram/osx/blob/27d6543/Sources/PatchgramCore/Resources/engine.c.template#L6587) `patchgram_apply_account_freeze_response` |

### Message settings subpatches

All grouped under the [`binary.messages.settings`](https://github.com/patchgram/osx/blob/27d6543/Sources/PatchgramCore/Resources/patches.json#L110)
rule; the two runtime-rewrite ones have dedicated engine functions:

| Subpatch | Code |
| --- | --- |
| Copy/save protect content | [engine.c.template:5210](https://github.com/patchgram/osx/blob/27d6543/Sources/PatchgramCore/Resources/engine.c.template#L5210) `patchgram_strip_noforwards_in_response` |
| Custom Fact Check | [engine.c.template:4864](https://github.com/patchgram/osx/blob/27d6543/Sources/PatchgramCore/Resources/engine.c.template#L4864) `patchgram_apply_fact_check_response` |
| Typing / Read receipts / Local drafts / Scheduled send / Disable TTL | [patches.json:110](https://github.com/patchgram/osx/blob/27d6543/Sources/PatchgramCore/Resources/patches.json#L110) (alternative groups) |

The **Disable Premium, Stars, TON & Gifts** and **Disable ads** subpatches are alternative groups under their
parent rules ([:377](https://github.com/patchgram/osx/blob/27d6543/Sources/PatchgramCore/Resources/patches.json#L377)
and [:1803](https://github.com/patchgram/osx/blob/27d6543/Sources/PatchgramCore/Resources/patches.json#L1803)); see
[patchlist.md](patchlist.md) for the per-subpatch breakdown.
