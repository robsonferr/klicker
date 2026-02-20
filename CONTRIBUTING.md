# Contributing to Klicker

Thanks for your interest in contributing! Klicker is a simple project and contributions of all sizes are welcome.

## Getting Started

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone git@github.com:YOUR_USERNAME/klicker.git
   cd klicker
   ```
3. Build the app:
   ```bash
   chmod +x build.sh
   ./build.sh
   ```
4. Run it:
   ```bash
   open build/Klicker.app
   ```

## Requirements

- macOS 13 (Ventura) or later
- Xcode Command Line Tools (`xcode-select --install`)

## Project Structure

The entire app lives in a single file (`main.swift`), compiled with `swiftc` — no Xcode project needed.

| File | Purpose |
|---|---|
| `main.swift` | All app logic (~330 lines) |
| `build.sh` | Compiles and creates the `.app` bundle |
| `generate_icon.swift` | Generates the app icon programmatically |
| `pt-BR.lproj/Localizable.strings` | Portuguese (Brazil) translations |
| `en.lproj/Localizable.strings` | English translations |

## Making Changes

1. Create a branch for your feature or fix:
   ```bash
   git checkout -b feat/my-feature
   ```
2. Make your changes in `main.swift`
3. Build and test:
   ```bash
   ./build.sh && open build/Klicker.app
   ```
4. Commit with a descriptive message following [Conventional Commits](https://www.conventionalcommits.org/):
   ```
   feat: add trackpad click support
   fix: sound not playing on right click
   docs: update README with new feature
   ```
5. Push and open a Pull Request

## Adding a New Language

1. Create a new folder: `xx.lproj/` (e.g., `es.lproj/` for Spanish)
2. Copy `en.lproj/Localizable.strings` into it
3. Translate all values
4. Add the language entry to the `supportedLanguages` array in `main.swift`
5. Build and test

## Adding New Sounds

Place audio files (`.aiff`, `.wav`, `.mp3`, `.m4a`) in the `sounds/` directory. Keep files small (< 500KB) for quick playback.

## Guidelines

- Keep it simple — the whole app is one file by design
- No external dependencies
- Test on both light and dark mode
- Ensure translations are complete for all supported languages

## Reporting Issues

Open an issue on GitHub with:
- macOS version
- Steps to reproduce
- Expected vs actual behavior

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
