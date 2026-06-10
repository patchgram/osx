Release

- Update patches without rebuilding the app: the new "Update patches" button fetches signed patch + engine bundles from GitHub, verifies them (Ed25519 + SHA-256), and applies them on the next patch.
- Each patch now shows whether it is available for the selected Telegram version, with an "N of M patches available" count under the app info.
- Enabled patches whose definition changed in an update now offer a per-patch "Update" button to re-apply cleanly.
