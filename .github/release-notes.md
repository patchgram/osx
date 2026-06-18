Release 1.1.1

- **New "Spoof profile unique gifts" patch** (Gifts, dylib). Makes a profile's gift show as an upgraded (unique) gift — locally — by rewriting the `payments.savedStarGifts` response. In its Settings window you pick an upgradable gift (catalog from `api.changes.tg`) or **Empty** for fully-custom ids, then set the title, unique number, model, symbol, backdrop, issued/total counts, value and last-resale, and identity (sender, owner, host, owner address, date). Works on already-unique gifts and converts regular gifts to unique; for a converted gift it also answers the value-details request locally so it shows instead of failing. Live "Save & Apply" with whose-profile targeting.
- **Account freeze** subpatch (Custom account settings): shows your account as frozen — locally — by injecting freeze dates and an appeal URL into the `help.appConfig` response.
- Fixed a rare crash when switching channels/chats with gift spoofing active.

Run "Update patches" to pull the matching patch bundle (this bundle requires app 1.1.1+).
