# Patchgram (macOS) — Patch Authoring Guide

Audience: an AI agent (or engineer) who wants to add a **new patch** to the macOS Patchgram, using only
this repo + public sources. It explains the architecture, how to find what you need in the target binary,
how to write each kind of patch, and how to build / test / ship it.

- This repo: <https://github.com/patchgram/osx>
- Windows port (parallel design, different ABI): <https://github.com/patchgram/win> — see its `docs/patch-authoring.md`
- Target: **Telegram Desktop 6.9.3**, arm64 (Apple Silicon). Download: <https://telegram.org/dl/desktop/mac>
- Telegram Desktop source (read this to understand the functions/structs you patch): **tag `v6.9.3`** →
  <https://github.com/telegramdesktop/tdesktop/tree/v6.9.3>
- MTProto/TL schema (constructor ids + field layout), **layer 227**: the project bundles it as
  `Sources/PatchgramCore/Resources/tl_schema.json`; upstream is tdesktop's
  [`scheme.tl`](https://github.com/telegramdesktop/tdesktop/tree/v6.9.3/Telegram/SourceFiles/mtproto/scheme)
  and <https://core.telegram.org/schema>.
- Gift catalog (gift ids, models, symbols, backdrops, emoji ids): **@GiftChanges** — <https://api.changes.tg>
  (used by `Sources/Patchgram/GiftChangesAPI.swift`).

---

## 1. Architecture in one screen

Patchgram is a SwiftUI app that patches a **copy** of Telegram Desktop in two ways:

| Type | Mechanism | Where it lives |
| --- | --- | --- |
| **`dylib`** (runtime) | An injected library `Patchgram.dylib`, compiled at apply-time from [`engine.c.template`](../Sources/PatchgramCore/Resources/engine.c.template), hooks two MTProto functions and rewrites the TL wire buffers in flight (and adds AppKit overlays). Loaded via a `DYLD_INSERT_LIBRARIES` launcher wrapper. | `engine.c.template` + a config flag + a rule + UI |
| **`binary`** (AOB byte-patch) | A pattern (`original` bytes + `mask`) located in the executable's `__text` and overwritten with `patched` bytes. Applied/reverted by the same dylib at runtime (`runtimeMemory` delivery) so it survives updates and is toggleable. | a rule entry in [`patches.json`](../Sources/PatchgramCore/Resources/patches.json) |

Almost every server-data patch is a **dylib** patch because the whole MTProto-rewrite family hangs on just
**two hooks**:

- `MTP::details::Session::sendPrepared` — outgoing requests. VMADDR `0x105d74850`
  (`PATCHGRAM_SESSION_SEND_PREPARED_VMADDR`). Hook = `patchgram_session_send_prepared`.
- `MTP::details::SessionPrivate::tryToReceive` — incoming responses. VMADDR `0x105d6b498`
  (`PATCHGRAM_SESSION_PRIVATE_TRY_TO_RECEIVE_VMADDR`). Hook = `patchgram_session_private_try_to_receive`.

Hooks are installed by AOB **signature** (not a hardcoded address) so they survive minor Telegram updates:
`patchgram_find_signature` (pattern+mask scan of `__text`) → `patchgram_allocate_trampoline` (copy prologue
to an mmap'd page) → `patchgram_install_hook` (write an absolute branch). The VMADDRs above are only a
fallback / sanity reference.

---

## 2. Tools you need

| Tool | Why | Notes |
| --- | --- | --- |
| **Xcode + Swift toolchain** (`swift build`, `clang`) | Build the app; the dylib is compiled by `clang` at apply time. | macOS only. `swift test` runs the unit tests. |
| **A throwaway copy of `Telegram.app` 6.9.3 (arm64)** | The RE target + apply target. | Never patch your real install. |
| **IDA Pro / idalib** | Decompile + find functions, fields, AOB sites. | This environment exposes idalib via MCP tools (`mcp__plugin_ida-pro_idalib__*`). A prebuilt `.i64` makes analysis instant; full auto-analysis can crash on the ~200 MB binary, so open the `.i64` or analyze selectively. |
| **lief + capstone** (`pip install lief capstone`) | Lightweight scripted RE when idalib is overkill (read `__text`, disasm a range, derive an AOB). | See `scripts/mtproto_decode.py` for TL-decoding helpers. |
| **openssl** | Sign patch bundles (Ed25519). | Key at `signing/patchgram-ed25519-private.pem` (gitignored). |
| **python3** | Codegen + RE scripts in `scripts/`. | `gen_tl_schema*.py`, `generate-binary-patch-registry.py`, `mtproto_decode.py`. |

---

## 3. The TL wire format + the in-dylib rewriter (read before writing a dylib patch)

MTProto request/response bodies are **TL** (Type Language): a flat little-endian `uint32` word stream.
A boxed value starts with a 4-byte **constructor id** (e.g. `payments.savedStarGifts#…`), followed by its
fields in schema order. `flags:#` is a bitmask whose set bits decide which optional fields follow. Vectors
are `vector#1cb5c415` + an `int32` count + items. Strings are length-prefixed and padded to 4 bytes.
**The wire format is identical on every platform** — this is why the TL engine ports between macOS and Windows.

The engine ships a schema-driven decoder/rewriter:
- `tl_schema.c.inc` (generated from `tl_schema.json`, layer 227) — the constructor + field tables.
- A walker `patchgram_tl_decode_ctor` / `patchgram_tl_decode_value` that walks any value, threading a
  `struct PatchgramTLRewrite *rw` context. To **read** a field you set finder flags on `rw` (e.g.
  `rw->find_doc_id`, `rw->find_first_doc`) and read back `rw->found_off` / `rw->found_len`. To **rewrite** a
  field you set values on `rw` (e.g. `rw->convert_stars`, `rw->sticker_id`) and `patchgram_gift_rewrite_field`
  overwrites it in place when the walker reaches it.

Qt6 memory layout you rely on (both request and response buffers are a `QVector<mtpPrime>`):
- `QVector`/`QList`/`QString` = `{ Data* d@0x0; T* ptr@0x8; qsizetype size@0x10; }`.
  Read words with `memcpy(&ptr, base+0x8, 8)`, count with `memcpy(&size, base+0x10, 8)`.
- The `d` block is a Qt6 `QArrayData` header (`ref@0`, `flags@4`, `alloc@8`), data at `ptr`. `ref==1` ⇒
  uniquely owned ⇒ safe to edit in place.

### Buffer-writing rules (critical — getting this wrong corrupts the heap)

- **Shrink / equal-size edits**: write in place, update `size@0x10`.
- **Grow into existing spare capacity**: read `alloc` at `d+8`; if `new_words <= alloc`, append + bump
  `size`. Never assume capacity — check it (`patchgram_inject_hidden_gifts`, the gift rebuild do this).
- **Grow a request you own (`ref==1`)**: a guarded `realloc` of the `QArrayData` is OK (see
  `patchgram_autoload_append_emoji`). Re-point `d` and `ptr` after.
- **Consume-once responses** (e.g. an rpc_error/fragment-phone reply that the client reads exactly once):
  you may install a *borrowed* buffer (`d=NULL`, your own `ptr`/`size`). **Never** do this for cached /
  deep-copied responses like `payments.savedStarGifts` — it crashes. When in doubt, rebuild into a real
  malloc'd Qt buffer (`patchgram_gift_build`).
- **Always validate** the rewritten buffer re-decodes and consumes exactly its length, and **revert on
  failure** so a bad patch never destabilises the client. Per-patch handlers share static scratch buffers,
  so the whole receive loop is serialized by one mutex (`g_received_queue_mutex`).

---

## 4. How to author a **dylib** (runtime) patch — step by step

Goal example: "rewrite field X in response/request Y."

1. **Identify the TL object.** Turn on the **MTProto logger** patch, reproduce the action, and read
   `Telegram.app/Contents/Resources/logs_mtproto_pg/log_*.log` — every request/response is printed as fully
   decoded TL (`name#id { field=value, … }`). Find the constructor + the field you want.
2. **Confirm the schema.** Look the constructor up in `tl_schema.json` / tdesktop `scheme.tl` to get the
   exact field order, flags bits, and types. Add a `#define PATCHGRAM_TL_…` for the ctor id if needed.
3. **Pick the side:** outgoing → extend `patchgram_session_send_prepared`; incoming → add a handler called
   from `patchgram_session_private_try_to_receive`'s receive loop (search `for (uint8_t *response = begin`).
   Mirror an existing handler:
   - response rewrite-in-place / rebuild → `patchgram_apply_gift_spoof_response` / `patchgram_gift_build`
   - response inject entries → `patchgram_inject_hidden_gifts`
   - capture a document by id → `patchgram_unique_capture_response`
   - request drop → return before calling the original (block typing/read)
   - request field force → `forceSerializedBool` style (always-offline, no-phone-on-add)
4. **Write the handler** in `engine.c.template`. Read the buffer via the Qt6 offsets, walk with the TL
   decoder + `rw` finders/rewriters, obey the buffer-writing rules in §3. Gate everything on a global flag
   (`static int g_myfeature_enabled = 0;`) and log via `patchgram_log(...)` (capped).
5. **Wire the dispatch:** call your handler in the receive/send path, guarded by the flag.
6. **Plumb the config flag** so the app can turn it on:
   - Parse it in the config reader (search `patchgram_json_bool(json, "...")`) into your global.
   - Add the key to `PatchgramRuntimeConfigFile` + map it in `writeRuntimeConfig`
     ([`BinaryPatchEngine.swift`](../Sources/PatchgramCore/BinaryPatchEngine.swift), `runtimeConfigName =
     "PatchgramRuntime.json"`). The dylib re-reads this JSON (mtime-watched) at runtime.
7. **Register the rule** so it appears in the patcher: add a `runtimeMemory`/dylib rule with a new
   `id` (e.g. `binary.<area>.<name>`) and `category` to `patches.json`, and to the built-in catalog in
   `BinaryPatchRule.swift` (`rawBuiltInRules` + `category(forRuleId:)`). Add it to the dylib rule sets in
   `PatchgramViewModel.swift` (`dylibRuleIds` / `runtimeRuleIds`).
8. **UI** (optional settings): add a settings view in `Sources/Patchgram/ContentView.swift` if the patch is
   configurable.
9. **Build + test** (§6).

The whole-config init in Swift has ~50 args; if the type-checker chokes, see the workaround noted in the
overlay code. Gift patches' rules are **hand-maintained in `patches.json`** (they aren't generated).

---

## 5. How to author a **binary** (AOB byte-patch) — step by step

Use this for local checks / limits that aren't on the wire (account limit, sensitive blur, recent-stickers
limit, premium effects, spoilers, open-links, callback-hover, hide-stories client half).

1. **Find the function** in tdesktop source (`v6.9.3`) by name/behavior, then find it in the binary with
   idalib (decompile, confirm the exact instruction you want to change).
2. **Decide the minimal edit** — same byte-length is easiest (flip a compare, `mov reg,#imm`, `xor eax,eax;
   ret`, branch→`b`/`nop`). Match the macOS arm64 encoding.
3. **Derive the AOB**: take ≥16 bytes around the site as `original`, and a `mask` where `0xFF` = fixed
   opcode bytes and `0x00` = wildcard over rip/adrp-relative displacements and call targets. Verify the
   pattern is **unique** in `__text` (else add more context or set `expectedOccurrences`).
4. **Add the rule** to `patches.json`: `id`, `category`, `kind`/`delivery` (`runtimeMemory`), `methodName`,
   and `replacements` with `original`/`patched`/`mask` (hex), `expectedOccurrences`, and an
   `alternativeGroup` if it's one of several sites for one feature. Multi-site features list several
   replacements (see `binary.accounts.limit_999`, `binary.visual.disable_spoilers`).
5. The dylib's reusable applier locates each AOB at runtime and overwrites it (reverting cleanly on
   toggle-off). `scripts/generate-binary-patch-registry.py` regenerates the in-dylib table from the rules.
6. **Build + test** (§6).

---

## 6. Finding things — RE recipes

- **From a log string / literal**: find the unique string in `__cstring`/`__const`, find the
  `adrp/add` (or `lea` on x86) that references it, walk up to the enclosing function.
- **From tdesktop source**: the function name → its behavior → match constants/calls in the disassembly.
- **idalib (MCP)**: open the prebuilt `.i64` (instant) or analyze selectively — `decompile`, `disasm`,
  `xrefs_to`, `find_bytes`, `make_signature_for_function`. Avoid blind full auto-analysis on the 200 MB
  binary (it can crash); target candidate addresses.
- **lief + capstone**: for quick scripted reads of `__text` and AOB uniqueness checks without IDA.
- **Struct field offsets**: cross-check against tdesktop source; the Qt6 container offsets are fixed
  (§3). Validate before trusting an offset.

When you find a hook function, record: function VMADDR, ≥16 entry bytes, and an AOB signature (fixed bytes +
`0x00` wildcards over relative operands).

---

## 7. Build, test, ship

```sh
# Unit tests (rule catalog, config plumbing, bundle signing, and a real engine compile)
swift test

# Build + sign the app into .build/Patchgram.app (then copy to /Applications to test)
./scripts/build-app.sh

# Build + Ed25519-sign an OTA patch bundle (patches.json + engine.c.template + manifest + sig)
./scripts/build-patch-bundle.sh <bundleVersion> <minAppVersion> signing/patchgram-ed25519-private.pem dist
```

- The engine is a **template**: `engine.c.template` has three placeholders substituted at apply time
  (`__PATCHGRAM_MEMORY_PATCH_TABLE_PLACEHOLDER__`, `__PATCHGRAM_TL_SCHEMA_PLACEHOLDER__`,
  `__PATCHGRAM_BUILD_MARKER_PLACEHOLDER__`). It compiles as **Objective-C with ARC** (it includes AppKit for
  the overlay). To syntax-check standalone, substitute the placeholders with stubs and run
  `clang -fsyntax-only -x objective-c -arch arm64 -fobjc-arc -fmodules`.
- **OTA delivery**: installed apps fetch the latest signed bundle via the "Update patches" button. The
  manifest is hashed + Ed25519-signed; the app verifies it against the pinned public key
  (`PatchBundleManifest.swift`, `pinnedPublicKeyBase64`). Signing is deterministic, so the committed
  `patch-manifest.json` + `.sig` are byte-identical to CI output.
- **Releases**: a patches-only change ships as a `patches-vN` git tag → CI signs + publishes the bundle
  (no app rebuild needed if `minAppVersion` is satisfied). An app change ships as a `vX.Y.Z` tag → DMG.
  Bundle version numbers are **monotonic — never reuse one** that was published.

---

## 8. Golden rules

1. **Local only.** Patches change what the client sends/blocks/shows; they never mutate server data. Keep
   it that way.
2. **Validate + revert on failure.** A rewrite that doesn't re-decode to exactly its length must be
   abandoned, leaving the original buffer untouched. A patch must never crash the client.
3. **Respect buffer ownership** (§3). Never install a borrowed buffer for a cached/deep-copied response;
   never grow past `alloc` without a real realloc on a `ref==1` buffer.
4. **Gate every patch on its flag**, log under a cap, and serialize anything touching shared scratch.
5. **Pin RE facts to the version** (`v6.9.3`). A new Telegram version may shift offsets — re-derive
   signatures, don't hardcode addresses.

## 9. File map

| Path | What |
| --- | --- |
| `Sources/PatchgramCore/Resources/engine.c.template` | The runtime hook engine (all dylib patches). |
| `Sources/PatchgramCore/Resources/patches.json` | Rule definitions (every patch + byte-patch AOBs). |
| `Sources/PatchgramCore/Resources/tl_schema.json` / `tl_schema.c.inc` | TL schema (layer 227). |
| `Sources/PatchgramCore/BinaryPatchEngine.swift` | Apply/restore, runtime-config writer, bundle verify. |
| `Sources/PatchgramCore/BinaryPatchRule.swift` | Built-in rule catalog + per-patch config structs. |
| `Sources/PatchgramCore/PatchBundleManifest.swift` | Pinned key + bundle signature verification. |
| `Sources/Patchgram/` | SwiftUI app (UI, view model, `GiftChangesAPI.swift`). |
| `scripts/` | `build-app.sh`, `build-patch-bundle.sh`, `generate-binary-patch-registry.py`, `gen_tl_schema*.py`, `mtproto_decode.py`, `generate-signing-key.sh`. |
| `patchlist.md` / `patchlist_ru.md` / `README.md` | Human patch list + per-patch code links. |
