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
| Always offline | `dylib` | Keeps your account offline by forcing the `account.updateStatus` request to offline. |
| 999 accounts | `binary` | Raises the local account limit from 6 to 999. |
| Custom account settings | `dylib` | A grouped local account-customization patch (balance, badge, verification, identity, attached channel, Fragment phone, custom usernames, account freeze). |
| Block typing activity | `dylib` | Stops Telegram Desktop from sending typing activity by invalidating the typing request. |
| Don't share phone when adding contacts | `dylib` | Stops sending the phone-privacy exception when you add a contact. |

### Messages

| Patch | Type | What it does |
| --- | --- | --- |
| Message settings | `dylib` | Groups message-privacy subpatches: typing, read receipts, local drafts, scheduled send, custom Fact Check, copy/save protect, and TTL. |
| Hide blocked users' messages | `dylib` | Hides messages from people who are in your blocklist (blocked users). Reacts immediately when you block/unblock someone. |
| Show bot callback-data on hover | `dylib` | Shows bot inline-button callback data locally on hover/copy. |
| Sensitive blur | `dylib` | Disables local sensitive-content blur. |
| Open links without warning | `dylib` | Opens hidden/external links directly, without Telegram's confirmation warning. |
| Disable media spoilers | `dylib` | Shows spoiler-marked photos and videos normally. |
| Block read messages | `dylib` | Blocks read-history requests so messages are not marked as read through the patched request path. |
| More recent stickers | `dylib` | Raises the Recent stickers panel limit from 20 to 200. |

### Optimizations

| Patch | Type | What it does |
| --- | --- | --- |
| Disable Premium, Stars, TON & Gifts | `dylib` | Disables Premium, Stars, TON, Gifts, boosts and related monetization UI/requests at runtime. |
| Disable premium effects | `dylib` | Stops Premium sticker/effect animations locally. |
| Hide stories | `dylib` | Hides stories locally and blocks story fetch/read/view requests. |
| Disable ads | `dylib` | Disables Telegram Ads and proxy sponsor promotion surfaces. |

### Gifts

| Patch | Type | What it does |
| --- | --- | --- |
| Spoof profile gifts | `dylib` | Rewrites the star gifts shown on a profile — sender, date, gift id, Stars price and more. |
| Show hidden gifts | `dylib` | Adds extra star gifts to the gift-purchase menu locally. |
| Spoof profile unique gifts | `dylib` | Shows a profile's gift as an upgraded (unique) gift with a title, number, model, symbol and backdrop you choose. |
| Fake transfer | `dylib` | Makes a spoofed gift transferable and fakes the transfer with a local service message. Requires Spoof profile unique gifts. |

### Misc

| Patch | Type | What it does |
| --- | --- | --- |
| Dylib injection | `dylib` | Injects Patchgram.dylib into Telegram via a DYLD_INSERT_LIBRARIES launcher — the base hook every runtime patch loads through. |
| Profile rain overlay | `dylib` | Rains a chosen image or animated sticker over an open profile, drawn natively by the dylib. |
| MTProto request/response logger | `dylib` | Logs every MTProto request and response (fully decoded TL, timestamped) to log files next to Telegram. |

## Message Settings Subpatches

| Subpatch | What it does |
| --- | --- |
| Typing activity | Stops typing indicators from being sent. |
| Read receipts | Stops read-history requests from being sent through the patched paths. |
| Local drafts | Keeps drafts local by blocking draft sync requests. |
| Scheduled send | Enables Patchgram's local scheduled-send runtime flag. |
| Custom Fact Check | Replaces `messages.getFactCheck` responses with your own Fact Check text. |
| Copy/save protect content | Clears `noforwards` locally so you can copy text and save media from restricted chats. |
| Disable TTL | Zeroes self-destruct and auto-delete timers locally. |

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
| Custom Stars | Locally overrides your displayed Stars balance. |
| Custom TON | Locally overrides your displayed TON balance. |
| Custom level rating | Overrides the local Stars level/rating for selected users. |
| Visual peer badge | Adds a local Verified, Scam, or Fake badge to selected peers. |
| Bot verification | Adds local bot-verification details to selected peers. |
| Local Telegram Premium | Makes the client treat Premium as locally available for UI gates. |
| Custom phone number | Locally replaces your own phone number. |
| Custom userID | Locally replaces your own displayed user id. |
| Local attached channel | Locally attaches a channel to your own profile by id. |
| Fragment phone | Makes your phone look collectible (Fragment) with local `collectibleInfo` values. |
| Custom list usernames | Replaces the username list shown on your own profile, with local Fragment collectible info. |

## Disable Ads Subpatches

| Subpatch | What it does |
| --- | --- |
| Telegram Ads | Blocks sponsored message request paths. |
| Proxy sponsor | Blocks proxy sponsor promotion request/UI paths. |
