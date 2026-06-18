Signed patch bundle (bundleVersion 13, minApp 1.1.1). Update via the app's "Update patches" button — no app reinstall needed.

## Changelog
- **New patch — Spoof profile unique gifts** (Gifts): makes a profile's gift show as an upgraded (unique) gift. Pick an upgradable gift (catalog from `api.changes.tg`) or **Empty** for fully-custom ids, then set title, unique number, model, symbol, backdrop, issued/total, value and last-resale, and identity (sender / owner / host / owner address / date). Converts regular gifts to unique too, and answers a converted gift's value-details request locally.
- **New subpatch — Account freeze** (Custom account settings): shows the account as frozen via the local `help.appConfig` response.
- Crash fix for fast channel/chat switching with gift spoofing active.
