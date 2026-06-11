Release

- Fixed visual bugs on the latest Telegram build (6.9.2): custom userID, custom usernames, and fragment phone (and related visual account patches) work again — their runtime hooks now resolve on the new build via widened, version-resilient signature masks.
- Enabling any dylib patch now also turns on the "Dylib injection" patch and keeps it on, so disabling another dylib patch no longer drops the injection.

Ships the updated patch catalog (patches-v4) with the 6.9.2 signature fixes.
