# Patchgram Patch List

This file describes the patches available in Patchgram in plain language.

## Patch Types

| Type | What it means | When it is used |
| --- | --- | --- |
| `dylib` | Patchgram installs its local runtime hook library into Telegram Desktop and changes behavior while the app is running. | Visual/local features, configurable values, and patches that should be updated without rewriting many executable bytes. |
| `binary` | Patchgram edits matched byte patterns in the Telegram Desktop executable. | Stable request/constructor patches and local checks that are easier to change directly in the binary. |

> Most patches are local client-side changes. They change what your Telegram Desktop sends, blocks, or displays locally. They do not change Telegram server-side account data.

## Patches

Patchgram's main screen groups patches into five sections — **Accounts**, **Messages**, **Optimizations**, **Gifts**, and **Misc**. Each patch below is listed under the section it appears in.

### Accounts

| Patch | Type | What it does |
| --- | --- | --- |
| Always offline | `dylib` | Keeps your account shown as offline by forcing the local `account.updateStatus` offline value. |
| 999 accounts | `binary` | Raises the local account limit from Telegram Desktop's normal limit to 999 accounts. |
| Custom account settings | `dylib` | A grouped local account customization patch. It contains visual balance, badge, Premium, verification, identity, attached channel, Fragment phone, custom usernames, and account freeze subpatches. The account freeze subpatch makes Telegram Desktop show the account as frozen by injecting freeze dates and an appeal URL into the local `help.appConfig` response. |
| Block typing activity | `dylib` | Stops Telegram Desktop from sending typing activity by invalidating the typing request. |
| Don't share phone when adding contacts | `dylib` | Prevents Telegram Desktop from sending the phone privacy exception flag when adding a contact. |

### Messages

| Patch | Type | What it does |
| --- | --- | --- |
| Message settings | `dylib` | A grouped privacy patch for typing activity, read receipts, local drafts, scheduled send, and local channel post Fact Check text. |
| Show bot callback-data on hover | `dylib` | Shows bot button callback data locally when hovering/copying inline button text. |
| Sensitive blur | `dylib` | Disables local sensitive-content blur checks. |
| Open links without warning | `dylib` | Opens hidden/external links without Telegram's extra confirmation warning. |
| Disable media spoilers | `dylib` | Shows spoiler-marked photos/videos normally instead of blurring them locally. |
| Block read messages | `dylib` | Blocks read-history requests so messages are not marked as read through the patched request path. |
| More recent stickers | `dylib` | Raises the recent stickers display limit from Telegram's default 20 to 200, so the "Recent" row in the sticker panel shows many more recently-used stickers. Runtime memory patch on `kRecentDisplayLimit` in `StickersListWidget::collectRecentStickers`. |

### Optimizations

| Patch | Type | What it does |
| --- | --- | --- |
| Disable Premium, Stars, TON & Gifts | `dylib` | Disables selected monetization UI and request paths at runtime: Premium, Stars, TON, Gifts, boosts, paid reactions, emoji statuses, and related app config parts. |
| Disable premium effects | `dylib` | Stops Premium sticker/effect animations from starting locally. |
| Hide stories | `dylib` | Hides story state locally and blocks known story fetch/read/view request paths. |
| Disable ads | `dylib` | Blocks Telegram Ads and proxy sponsor promotion surfaces. |

### Gifts

| Patch | Type | What it does |
| --- | --- | --- |
| Spoof profile gifts | `dylib` | Rewrites the star gifts shown on a profile, locally, by rewriting the `payments.savedStarGifts` response inside the runtime library. It has its own Settings window where you set the spoofed sender (user/channel/chat, Bot-API-style id), date, gift id, Stars price, caption, supply (available/total) and badges (Limited, Can upgrade with a price, Auction with title + gift number, Was refunded). It can also swap the gift's sticker to a custom emoji: enter the custom-emoji id or press **Get id from gift** (looks it up from `api.changes.tg`), then open that emoji's pack once so the full document is captured and substituted (use an animated TGS/WEBM emoji so it renders inside the gift, not only in the list). "Save & Apply" updates a running Telegram live — re-open the profile to refresh. No Telegram bytes are patched. |
| Show hidden gifts | `dylib` | Adds extra star gifts to the gift purchase menu, locally, by appending entries to the `payments.starGifts` response inside the runtime library. The injected gifts (price 50 Stars, not limited) appear at the **top** of the list; their stickers use the matching custom emoji resolved from `api.changes.tg`. No Telegram bytes are patched. |
| Spoof profile unique gifts | `dylib` | Makes a profile's gift show as an upgraded (unique) gift, locally, by rewriting the `payments.savedStarGifts` response inside the runtime library. Its own Settings window: pick an upgradable gift (catalog from `api.changes.tg`) or **Empty** for fully-custom ids, then set title, unique number, model, symbol, backdrop, issued/total counts, value and last-resale, and identity (sender, owner, host, owner address, date). Works on already-unique gifts and converts regular gifts to unique. For a converted gift it also answers the gift's value-details request locally so it shows instead of failing. "Save & Apply" updates a running Telegram live — re-open the profile to refresh; whose-profile targeting (only me / everyone / everyone except me). No Telegram bytes are patched. |

### Misc

| Patch | Type | What it does |
| --- | --- | --- |
| Dylib injection | `dylib` | Injects Patchgram's runtime library (`Patchgram.dylib`) into Telegram Desktop through a `DYLD_INSERT_LIBRARIES` launcher wrapper. This is the base hook every runtime patch loads through; on its own it loads the library with no behavior change. |
| Profile rain overlay | `dylib` | Shows a native AppKit overlay inside Telegram: a floating button opens a panel where you pick a `.png` image or an animated `.tgs` sticker plus an animation style (rain / snow / float / burst), with size, speed and opacity sliders. With it on, the chosen image rains over an open profile and auto-follows it (both the centred profile card and the right info column). Drawn entirely by `Patchgram.dylib` — no Telegram bytes are patched. |
| MTProto request/response logger | `dylib` | Logs every MTProto request Telegram sends and every response it receives — each with a timestamp — to `log_<start>.log` files in `Telegram.app/Contents/Resources/logs_mtproto_pg`. The logger opens its file in the injected dylib's constructor, before Telegram sends its first packet, so the trace is complete from launch. Each line is the **fully decoded TL** — method/type plus its recursively-decoded fields (flags, vectors, nested objects, strings) — via a built-in TL decoder, so logs are readable with no external tools. An **Open logs** button next to the toggle reveals the newest log. Enabling it auto-enables Dylib injection. Drawn by `Patchgram.dylib` — no Telegram bytes are patched. |

## Message Settings Subpatches

| Subpatch | What it does |
| --- | --- |
| Typing activity | Stops typing indicators from being sent. |
| Read receipts | Stops read-history requests from being sent through the patched paths. |
| Local drafts | Keeps drafts local by blocking draft sync requests. |
| Scheduled send | Enables Patchgram's local scheduled-send runtime flag. |
| Custom Fact Check | Locally triggers Telegram Desktop's Fact Check request path for visible posts and replaces `messages.getFactCheck` responses with your own Fact Check text. |
| Copy/save protect content | Forces `message#7600b9d3` `noforwards` (flags.26) to false on each message locally, so you can copy text and save media from chats/channels that restrict saving. (Forwarding can still be blocked by the separate channel-level restriction.) |
| Disable TTL | Disables self-destruct/auto-delete timers locally: forces media `ttl_seconds` (view-once video/document) to 0 at construction, and zeroes the message `ttl_period` auto-delete time so timed messages are not removed locally. |

## Disable Premium, Stars, TON & Gifts Subpatches

| Subpatch | What it does |
| --- | --- |
| App config | Blocks the monetization app config request. |
| Premium UI | Hides or disables Premium UI entry points locally. |
| Gifts | Hides or blocks gift-related UI/actions locally. |
| Paid reactions | Blocks paid reaction availability/sending/decoding paths locally. |
| Emoji statuses and effects | Hides or blocks emoji status and related premium effects locally. |
| Stars, TON and collectibles | Hides or blocks Stars, TON, and collectible monetization surfaces locally. |
| Boosts | Hides or disables boost-related menu/actions locally. |
| Read receipts fix | Keeps the local who-read menu behavior compatible with the monetization patch. |

## Custom Account Settings Subpatches

| Subpatch | What it does |
| --- | --- |
| Custom Stars | Visually changes your Stars balance in My Stars and monetization-related places. |
| Custom TON | Visually changes your TON balance in My TON and monetization-related places. |
| Custom level rating | Visually changes Stars level/rating values for selected users. |
| Visual peer badge | Visually adds a local Verified, Scam, or Fake badge to selected users/channels. |
| Bot verification | Visually adds local bot verification details. You can choose where it appears and which preset to use. |
| Local Telegram Premium | Makes Telegram Desktop treat Premium as locally available for UI gates. |
| Custom phone number | Visually replaces your own phone number locally. Empty value means original phone. |
| Custom userID | Visually replaces your own displayed user ID locally. Empty value means original ID. |
| Local attached channel | Visually attaches another channel by channel ID. For it to display correctly in your own client, open/load that channel in Telegram Desktop first. |
| Fragment phone | Makes the displayed phone look collectible locally and lets you set local `fragment.collectibleInfo` values. |
| Custom list usernames | Replaces the username list shown in your self-profile locally. Usernames can be regular or collectible, and collectible usernames can return custom `fragment.collectibleInfo` values. |

## Disable Ads Subpatches

| Subpatch | What it does |
| --- | --- |
| Telegram Ads | Blocks sponsored message request paths. |
| Proxy sponsor | Blocks proxy sponsor promotion request/UI paths. |
