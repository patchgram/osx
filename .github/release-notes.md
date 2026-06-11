Release

New patches (bundle patches-v3)

- Dylib injection: the runtime-library injection is now an explicit patch, kept first in the list. Enabling it installs the `DYLD_INSERT_LIBRARIES` launcher wrapper that loads `Patchgram.dylib` into Telegram on its own (no behavior change) so the runtime hooks are present — the base every other runtime patch loads through.
- Copy/save protect content (Message settings): forces `message` `noforwards` off locally, so you can copy text and save media from chats/channels that restrict saving. (Renamed from "Copy from restricted".)
- Disable TTL (Message settings): clears self-destruct / auto-delete timers locally — forces view-once video/voice/document `ttl_seconds` to 0 at construction and zeroes the message `ttl_period` auto-delete time, so timed content is not removed locally.

App

- "Disable All" now stays inactive until a patch is actually applied — selecting a patch without applying it no longer enables the button.
- Ships the updated patch catalog (patches-v3) with the new patches above.
