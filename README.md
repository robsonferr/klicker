# Klicker

A lightweight, open-source macOS menu bar app that plays a sound on every mouse click.

![macOS](https://img.shields.io/badge/macOS-13%2B-blue?logo=apple)
![Swift](https://img.shields.io/badge/Swift-pure-orange?logo=swift)
![License](https://img.shields.io/badge/license-MIT-green)
![No Dependencies](https://img.shields.io/badge/dependencies-none-brightgreen)

## Why?

Some people find audible click feedback satisfying, helpful for focus, or useful for screen recordings and live demos. Klicker adds a subtle click sound to every mouse press — left or right — and lives quietly in your menu bar.

Inspired by [Mouse Click Sound](https://apps.apple.com/lr/app/mouse-click-sound/id6698888058?mt=12) on the Mac App Store, but free and open-source.

## Features

| Feature | Description |
|---|---|
| **Enable / Disable** | Toggle sounds on or off (shortcut: `T`) |
| **Separate sounds** | Choose different sounds for left and right click |
| **14 built-in sounds** | Tink, Pop, Purr, Hero, Blow, Bottle, Frog, Funk, Glass, Morse, Ping, Submarine, Sosumi, Basso |
| **Custom sounds** | Load any audio file (`.aiff`, `.wav`, `.mp3`, `.m4a`) |
| **Volume control** | 25%, 50%, 75%, or 100% |
| **Launch at Login** | Built-in toggle — no need to configure manually |
| **Native menu bar icon** | Custom-drawn cursor + sound waves, adapts to light/dark theme |
| **Persistent settings** | All preferences are saved automatically between sessions |

## Requirements

- macOS 13 (Ventura) or later
- Xcode Command Line Tools:
  ```bash
  xcode-select --install
  ```

## Build

```bash
git clone https://github.com/robsonferr/klicker.git
cd klicker
chmod +x build.sh
./build.sh
```

The build script compiles a single Swift file into a native `.app` bundle — no Xcode project needed.

## Install & Run

```bash
# Copy to your Applications folder
cp -r build/Klicker.app ~/Applications/

# Launch
open ~/Applications/Klicker.app
```

Klicker appears as a small icon in the **menu bar** (not in the Dock).

## Accessibility Permission

On first launch, macOS will prompt you to grant Accessibility permission. This is required to detect global mouse clicks.

1. Open **System Settings** → **Privacy & Security** → **Accessibility**
2. Enable **Klicker**
3. If needed, quit and relaunch the app

> **Note:** Klicker only listens for mouse-down events. It does not log, record, or transmit any data.

## Launch at Login

Click the Klicker menu bar icon and enable **"Launch at Login"**. The app will start automatically on every login using macOS native `SMAppService`.

Alternatively, you can add it manually:
1. Open **System Settings** → **General** → **Login Items**
2. Add `Klicker.app`

## Project Structure

```
klicker/
├── main.swift           # The entire app (~280 lines)
├── build.sh             # Build script (compiles + creates .app bundle)
├── generate_icon.swift  # Generates the app icon programmatically
├── Klicker.icns         # Pre-built app icon
├── icon.iconset/        # Icon PNGs for all sizes
├── sounds/              # Sample custom click sounds
└── README.md
```

## Tech Stack

- **Swift** — no dependencies, no packages, no Xcode project
- **Cocoa** — `NSEvent.addGlobalMonitorForEvents` for global click detection, `NSSound` for audio playback
- **ServiceManagement** — `SMAppService` for launch-at-login
- **CoreGraphics** — programmatically drawn menu bar icon and app icon
- **Build** — single `swiftc` command via shell script

## How It Works

1. Klicker registers a global event monitor for `leftMouseDown` and `rightMouseDown`
2. On each event, it plays the configured sound using `NSSound`
3. Each sound is played on a copy of the `NSSound` instance, allowing overlapping clicks
4. The menu bar icon is drawn at runtime using `CoreGraphics` with `isTemplate = true`, so macOS handles light/dark theme adaptation automatically

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.

Some ideas:
- [ ] Trackpad click support
- [ ] Per-application enable/disable rules
- [ ] Keyboard sound support
- [ ] More built-in click sounds
- [ ] Localization

## License

MIT — see [LICENSE](LICENSE) for details.
