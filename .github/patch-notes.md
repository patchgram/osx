Signed patch bundle (bundleVersion 14, minApp 1.2.0). Update via the app's "Update patches" button — no app reinstall needed.

## Changelog
- **New patch — Fake transfer** (Gifts): makes a spoofed gift transferable and fakes the transfer, locally. Adds a **Transfer** button to the gift (profile + gift-send window); transferring shows a "transferred" service message in the recipient's chat. Even a real gift is never actually transferred (the request is invalidated) — nothing reaches the server, and the message is local-only. Requires **Spoof profile unique gifts**.
