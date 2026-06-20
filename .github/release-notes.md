Release 1.2.0

- **New "Fake transfer" patch** (Gifts, dylib). Makes a spoofed gift transferable and fakes the transfer — locally. It adds a **Transfer** button to the gift on your own profile and in the gift-send window, and when you transfer it, a "transferred" service message appears in the recipient's chat. Requires **Spoof profile unique gifts**.
  - **Safe:** with it on, even a real gift is never actually transferred — the request is invalidated, so nothing reaches the server and the recipient receives nothing. The injected message is local-only and disappears on restart.

Run "Update patches" to pull the matching patch bundle (this bundle requires app 1.2.0+).
