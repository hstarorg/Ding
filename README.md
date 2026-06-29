# Ding

A pluggable macOS reminder that pops a top-most alert the moment a condition is met. Ships with **Time** and **Crypto Price** reminders.

Lives in the menu bar (no Dock icon). Every reminder is driven by a **plugin** that decides "is the condition met?" — when it is, Ding throws an always-on-top window in front of you.

## Features

- ⏰ **Time** — fire at a set time, once or every day.
- 💹 **Crypto Price** — fire when a symbol (e.g. BTCUSDT) crosses a threshold (price via Binance public API).
- 🔔 **Top-most popup** — floats above full-screen apps, plays a sound, with "Got it" / "Snooze 5 min".
- 🧩 **Plugin architecture** — a new reminder type is one protocol conformance plus one registration line.

## Run

Open `Ding.xcodeproj` in Xcode and press ⌘R (macOS 14+).

The Crypto Price plugin needs network access: `Signing & Capabilities → App Sandbox → Outgoing Connections (Client)` (already enabled in the project).

## Release & Install

Push a version tag to build and publish a `.dmg` via GitHub Actions:

```bash
git tag v1.0.0 && git push origin v1.0.0
```

The workflow (`.github/workflows/release.yml`) builds Release, packages `Ding.dmg`, and attaches it to the GitHub Release. Open the DMG and drag **Ding** to Applications.

> The build is **ad-hoc signed** (no Apple Developer account), so Gatekeeper will warn on first launch. Right-click the app → **Open**, or run `xattr -dr com.apple.quarantine /Applications/Ding.app`. For warning-free distribution, sign with a Developer ID certificate and notarize.

## Architecture

```
Ding/
├── Core/        ReminderPlugin protocol, model, registry, store, engine, popup
├── Plugins/     TimeReminderPlugin, CryptoPriceReminderPlugin
└── UI/          menu panel, add/edit form, popup view
```

- The **engine** evaluates every enabled reminder every 5s, with **edge-triggered** firing (a condition that stays true won't fire repeatedly).
- Reminders are persisted as JSON in the app container's Application Support directory.

## Writing a plugin

Conform to `ReminderPlugin` (`id` / `displayName` / `defaultConfig` / `summary` / `configView` / `evaluate`),
then add one line to `all` in `Core/PluginRegistry.swift`. `evaluate` returns `.fire` / `.fireOnce` / `.rearm` / `.none`.

## Stack

Swift + SwiftUI (`MenuBarExtra` + a custom always-on-top `NSPanel`). Bundle ID `org.hstar.ding`.
