# KeyRoute

KeyRoute is a lightweight macOS menu bar app that switches your keyboard input source based on the app or window you are using.

It is built for workflows where some apps or browser windows should use Vietnamese Telex, while everything else should stay on English ABC.

## What It Does

- Watches the focused macOS app/window.
- Switches whitelisted apps/windows to Vietnamese Simple Telex.
- Switches everything outside the whitelist back to English ABC.
- Runs as a menu bar app, not a Dock app.
- Provides a whitelist manager with a visible-window dropdown.
- Uses native Swift/AppKit APIs with no Electron runtime and no external dependencies.

## Default Routing

| Focused context | Input source |
| --- | --- |
| Matches a whitelist rule | `com.apple.inputmethod.VietnameseIM.VietnameseSimpleTelex` |
| Does not match a whitelist rule | `com.apple.keylayout.ABC` |

## Requirements

- macOS 13 or newer
- Xcode Command Line Tools or Xcode
- Swift Package Manager
- The macOS input sources you want to route must be enabled in System Settings

Verify Swift is available:

```sh
swift --version
```

## Build And Run

Clone the repo:

```sh
git clone https://github.com/thanhmanci/keyroute-macos.git
cd keyroute-macos
```

Build and run the self-test:

```sh
swift build
swift run keyroute-selftest
```

Build the menu bar app bundle:

```sh
scripts/build-app.sh
open dist/KeyRoute.app
```

The build script creates an ad-hoc signed app at `dist/KeyRoute.app`. It is suitable for local use and development, but it is not notarized.

## First-Time Setup

1. Open `dist/KeyRoute.app`.
2. Click the KeyRoute icon in the macOS menu bar.
3. Choose `Grant Accessibility Permission`.
4. Enable KeyRoute in `System Settings > Privacy & Security > Accessibility`.
5. Quit and reopen KeyRoute if macOS does not apply the permission immediately.
6. Add app or window rules from the menu bar item.

App-wide rules can work from frontmost-app detection. Window-title rules need Accessibility permission because macOS protects focused window metadata.

## Usage

Click the KeyRoute menu bar icon to access:

- `Auto switch`: turn automatic routing on or off.
- `Add Focused App to Vietnamese Whitelist`: route the entire focused app to Vietnamese.
- `Add Focused Window to Vietnamese Whitelist`: route the current focused window title to Vietnamese.
- `Manage Whitelist...`: open the full whitelist manager.
- `Grant Accessibility Permission`: open the required macOS privacy setting.

The menu also shows:

- current focused app/window,
- target route, such as `Vietnamese Telex` or `English ABC`,
- current macOS input source ID.

## Whitelist Rule Types

| Rule type | Behavior |
| --- | --- |
| `App` | Every focused window in the app routes to Vietnamese |
| `Window contains` | The focused window title must contain the saved text |
| `Window exact` | The focused window title must exactly match the saved text |

`Window contains` is usually best for browsers and editors because titles often include tab, file, or project suffixes.

## CLI

KeyRoute includes a small command-line utility for testing input sources:

```sh
swift run keyroutectl current
swift run keyroutectl list
swift run keyroutectl en
swift run keyroutectl vi
swift run keyroutectl select <input-source-id>
```

Example:

```sh
swift run keyroutectl select com.apple.keylayout.ABC
```

## Development

Project layout:

```text
Sources/
  KeyRoute/              AppKit menu bar app
  KeyRouteKit/           Rule models and routing logic
  keyroutectl/           CLI input-source utility
  keyroute-selftest/     Lightweight self-test executable
docs/wiki/               Project documentation
scripts/build-app.sh     Release-style local app bundle build
```

Useful commands:

```sh
swift build
swift run keyroute-selftest
swift run keyroutectl list
scripts/build-app.sh
codesign --verify --deep --strict dist/KeyRoute.app
```

## How It Works

KeyRoute uses:

- `NSWorkspace` to detect frontmost app changes,
- Accessibility APIs to read the focused window title and observe focused-window changes,
- `CGWindowListCopyWindowInfo` to populate the visible-window dropdown,
- Carbon Text Input Source APIs to select the target input source.

The app avoids a tight loop. It uses event-driven updates where possible and a low-frequency fallback timer to catch browser tab/title changes.

## Troubleshooting

### KeyRoute does not switch for window rules

Grant Accessibility permission, then quit and reopen KeyRoute.

### Window dropdown shows missing or generic titles

Some apps do not expose window titles consistently. Add an app-wide rule instead, or focus the exact window and use `Add Focused Window to Vietnamese Whitelist`.

### Vietnamese Telex does not activate

Make sure Vietnamese Simple Telex is enabled in:

```text
System Settings > Keyboard > Text Input > Edit
```

Then verify the source exists:

```sh
swift run keyroutectl list
```

### The app opens but does not appear in the Dock

That is expected. KeyRoute is configured with `LSUIElement=true`, so it runs as a menu bar app only.

## Current Limitations

- The UI currently routes to English ABC and Vietnamese Simple Telex by default.
- There is no notarized release artifact yet.
- Launch-at-login is not implemented yet.

## License

MIT. See [LICENSE](LICENSE).
