# Menu Bar Auto Switcher

## Goal

KeyRoute runs as a macOS menu bar app. It watches the currently focused application/window and applies this policy:

- If the focused app/window matches the whitelist, select `com.apple.inputmethod.VietnameseIM.VietnameseSimpleTelex`.
- Otherwise, select `com.apple.keylayout.ABC`.

The app is intended to stay light: native Swift/AppKit only, no Electron, no polling-heavy automation, no AppleScript loop.

## Architecture

- `KeyRouteKit`
  - `KeyboardContext`: focused process/app/window data.
  - `WhitelistRule`: app-wide or window-title matching rules.
  - `RuleEngine`: maps context plus settings to English or Vietnamese.
- `KeyRoute`
  - `FocusMonitor`: watches frontmost app via `NSWorkspace` and window title via Accessibility APIs.
  - `InputSourceSwitcher`: switches input sources through Carbon `TISSelectInputSource`.
  - `StatusBarController`: menu bar item and quick actions.
  - `RulesWindowController`: whitelist manager with visible-window dropdown.
  - `SettingsStore`: persists settings/rules to `UserDefaults`.
- `keyroutectl`
  - Small CLI for manual input-source testing.

## Permissions

App-wide rules can work with only `NSWorkspace` focus events. Window-title rules need macOS Accessibility permission so KeyRoute can read the focused window title.

Grant it from the menu bar item:

1. Click the KeyRoute icon in the menu bar.
2. Choose `Grant Accessibility Permission`.
3. Enable KeyRoute in `System Settings > Privacy & Security > Accessibility`.
4. Quit and reopen KeyRoute if macOS does not apply the permission immediately.

## Whitelist Rules

There are three rule types:

- `App`: every focused window in the selected app switches to Vietnamese.
- `Window contains`: the focused window title must contain the saved title text. This is the default for browser tabs and editor windows because titles often include file/project suffixes.
- `Window exact`: the focused window title must equal the saved title text.

Rules are additive. If any enabled whitelist rule matches, KeyRoute switches to Vietnamese.

## UI Workflow

- Open the menu bar item and use `Add Focused App to Vietnamese Whitelist` for app-wide rules.
- Use `Add Focused Window to Vietnamese Whitelist` for the current focused window title.
- Open `Manage Whitelist...` for the full UI:
  - dropdown of visible windows,
  - match mode dropdown,
  - add app/window rule buttons,
  - remove selected rules,
  - auto-switch toggle.

## Performance Notes

KeyRoute uses event-driven focus changes from `NSWorkspace` and Accessibility notifications where available. A low-frequency fallback timer checks the focused context every 450 ms with tolerance, which keeps browser tab/title changes responsive without running a tight loop.

The input source is only selected when the target source changes. Repeated focus notifications for the same app/window do not repeatedly call `TISSelectInputSource`.

## Build And Run

Build from source:

```sh
swift build
swift run keyroute-selftest
```

Build a menu bar `.app`:

```sh
scripts/build-app.sh
open dist/KeyRoute.app
```

The app bundle uses `LSUIElement=true`, so it appears in the menu bar and not in the Dock.

## Input Source IDs

KeyRoute defaults to the IDs detected on this machine:

```text
English:    com.apple.keylayout.ABC
Vietnamese: com.apple.inputmethod.VietnameseIM.VietnameseSimpleTelex
```

Verify sources:

```sh
swift run keyroutectl list
```

Manual switch:

```sh
swift run keyroutectl en
swift run keyroutectl vi
```
