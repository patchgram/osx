# Patch bundles (GitHub-delivered updates)

Patchgram loads its **patches** (`patches.json`) and **dylib engine** (`engine.c.template`) as data
shipped in the app, and can refresh them from GitHub via the app's **Update patches** button — so
fixing a patch or supporting a new Telegram Desktop version no longer requires rebuilding the `.app`.

Updates are **Ed25519-signed** and delivered as **GitHub release assets**. The app pins the public
key (`PatchBundleVerifier.pinnedPublicKeyBase64`) and refuses any bundle whose signature or per-file
SHA-256 doesn't match — this gate matters because the engine C is compiled and injected into Telegram.

## How a bundle is structured

A `patches-vN` release carries four assets:

| Asset | Purpose |
|---|---|
| `patches.json` | the patch catalog |
| `engine.c.template` | the dylib engine source |
| `patch-manifest.json` | `bundleVersion`, `minAppVersion`, per-file SHA-256 |
| `patch-manifest.json.sig` | detached Ed25519 signature over the manifest bytes |

The app offers an update only when `bundleVersion` exceeds the installed one and `minAppVersion` ≤ the
running app version.

## One-time setup

A keypair already exists at `signing/patchgram-ed25519-private.pem` (gitignored) and its public key is
pinned in the app. To enable publishing, upload the private key as a repo secret:

```sh
gh secret set PATCHGRAM_SIGNING_KEY < signing/patchgram-ed25519-private.pem
```

To rotate keys instead: delete `signing/`, run `scripts/generate-signing-key.sh`, paste the printed
public key into `PatchBundleVerifier.pinnedPublicKeyBase64`, re-sign the bundled manifest, and update
the secret.

## Publishing an update

1. Edit `Sources/PatchgramCore/Resources/patches.json` and/or `engine.c.template` (or regenerate them).
2. Tag and push — `N` is the new `bundleVersion`:
   ```sh
   git tag patches-v2 && git push origin patches-v2
   ```
   The **Patch bundle** workflow (`.github/workflows/patches.yml`) builds the manifest, signs it with
   the secret key, and creates the `patches-v2` release.
3. Users click **Update patches**; the app verifies + caches the bundle to
   `~/Library/Application Support/Patchgram/cache/`, hot-reloads the catalog, and recompiles the dylib
   on the next apply.

Build + sign a bundle locally (e.g. to test) with:

```sh
scripts/build-patch-bundle.sh 2 1.0.4 signing/patchgram-ed25519-private.pem dist
```
