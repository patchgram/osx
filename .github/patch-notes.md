Signed patch bundle (bundleVersion 17, minApp 1.2.0). Update via the app's "Update patches" button — no app reinstall needed.

## Changelog
- **Custom emoji auto-load by id** — across all gift patches, enter just an emoji id and the patch fetches
  its document + full pack automatically (no need to open the pack manually):
  - **Spoof Profile Unique Gifts** — model / symbol;
  - **Spoof Profile Gifts** — the gift's sticker;
  - **Show Hidden Gifts** — each hidden gift's emoji.
- **Fix (unique gifts):** the spoofed gift's **model** could stay the original gift's sticker (the model /
  symbol document cache collided and dropped the model). Model and symbol now render reliably.
