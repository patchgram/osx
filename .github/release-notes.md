Release 1.1.0

- **New "Gifts" section + "Spoof Profile Gifts" patch** (dylib). Rewrites the star gifts shown on a profile — locally — by rewriting the `payments.savedStarGifts` server response inside the injected dylib. It has its own Settings window:
  - **Spoof the sender** (user, channel, or chat — Bot-API-style id where `-100…` is a channel), **date**, **gift id**, **Stars price**, and a **gift caption**.
  - **Supply** (available / total) and **badges**: **Limited**, **Can upgrade** (with an upgrade price), **Auction** (with a title and gift number), and **Was refunded**.
  - **Custom sticker** for the gift: set a custom-emoji id, or press **Get id from gift** to pull it from `api.changes.tg` by the gift id. Open that emoji's sticker pack once so Patchgram captures its full document, then the gift's sticker is substituted consistently — it shows both in the gifts list and inside the opened gift. Use an animated (TGS/WEBM) custom emoji so it renders in the gift's detail view.
  - **Live apply** — "Save & Apply" updates a running Telegram with no restart; just re-open the profile to refresh. Whose-profile targeting (only me / everyone / everyone except me).
- **More recent stickers** patch (Messages, dylib): raises the "Recent" stickers display limit from Telegram's default 20 to 200.

Run "Update patches" to pull the matching patch bundle (this bundle requires app 1.1.0+).
