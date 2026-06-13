Release 1.0.9

- New patch: **MTProto request/response logger** (Misc, dylib). Logs every MTProto request Telegram sends and every response it receives — each timestamped — to `log_<start>.log` files in `Telegram.app/Contents/Resources/logs_mtproto_pg`. The logger starts inside the injected dylib's constructor, before Telegram sends its first packet, so the trace is complete from launch.
- The log is **fully decoded inline**: each line is the TL method/type plus its recursively-decoded fields (flags, vectors, nested objects, strings) via a built-in TL decoder (TL layer 227) — readable with no external tools.
- An **Open logs** button next to the patch reveals the newest log file, and enabling the logger auto-enables **Dylib injection**.

Run "Update patches" to pull the matching patch bundle (this bundle requires app 1.0.9+).
