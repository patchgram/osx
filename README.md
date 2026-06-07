# Patchgram
Required: ARM MacOS 12.0+ (Apple Silicon devices), [Telegram Desktop 6.8.5 beta](https://telegram.org/dl/desktop/mac?beta=1)

Enter this command in console to fix "The application "Patchgram" can't be opened":
```sh
xattr -dr com.apple.quarantine /Applications/Patchgram.app
```
