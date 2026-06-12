Release 1.0.7 (build fix)

- **Fixed: the app could crash on launch.** The released build couldn't locate its bundled resources (`Bundle.module` only looked at the .app root and a hardcoded build-machine path), so it worked on the build machine but `fatalError`-crashed on startup for everyone else. Resources are now resolved from the app itself, and the packaging step fails loudly if the resource bundle is missing — so this class of build breakage can't ship again.
- New: **Profile rain overlay** (dylib patch) — a native in-Telegram overlay that "rains" a chosen PNG or `.tgs` animated sticker over an open profile. Includes auto-follow of the profile area, animation styles (rain / snow / float / burst), size / speed / opacity sliders, and multi-window support.

Re-release of 1.0.7 with the launch-crash / build fix.
