Signed patch bundle (bundleVersion 16, minApp 1.2.0). Update via the app's "Update patches" button — no app reinstall needed.

## Changelog
- **Spoof Profile Unique Gifts:** custom **model / symbol** emoji now **auto-load by id** — enter just the
  emoji id and the patch fetches its document + full pack automatically (no need to open the pack manually).
- **Fix:** the spoofed gift's **model** could stay the original gift's sticker (the model/symbol document
  cache collided and dropped the model). Model and symbol now render reliably.
