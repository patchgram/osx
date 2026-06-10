#!/usr/bin/env bash
# Generate the Ed25519 keypair that signs patch bundles. Run once.
#   - Private key: signing/patchgram-ed25519-private.pem  (KEEP SECRET — gitignored)
#   - Public key:  printed below; paste into PatchBundleVerifier.pinnedPublicKeyBase64
# Then store the private key as a GitHub Actions secret so the patches workflow can sign:
#   gh secret set PATCHGRAM_SIGNING_KEY < signing/patchgram-ed25519-private.pem
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT/signing"
KEY="$ROOT/signing/patchgram-ed25519-private.pem"
if [ -f "$KEY" ]; then
  echo "Refusing to overwrite existing $KEY (delete it first to rotate keys)." >&2
  exit 1
fi
openssl genpkey -algorithm ed25519 -out "$KEY"
PUB="$(openssl pkey -in "$KEY" -pubout -outform DER | tail -c 32 | base64)"
echo
echo "Private key written to: $KEY  (gitignored — keep secret)"
echo "Pinned public key (set PatchBundleVerifier.pinnedPublicKeyBase64 to this):"
echo "  $PUB"
echo
echo "Upload the private key as a GitHub secret for the patches workflow:"
echo "  gh secret set PATCHGRAM_SIGNING_KEY < \"$KEY\""
