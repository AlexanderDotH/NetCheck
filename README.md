<div align="center">

# NetCheck

**A native macOS menu bar app to monitor your network in real time.**

Sit in your menu bar. Green when online, orange when degraded, red when down.
Click to open WiFi Finder, WiFi Diagnostic, Speed Test, Traceroute, or Usage Quality.

[![Platform](https://img.shields.io/badge/platform-macOS%2026%2B-blue.svg)](https://www.apple.com/macos)
[![Release](https://img.shields.io/github/v/release/vincentlauriat/NetCheck?color=brightgreen)](https://github.com/vincentlauriat/NetCheck/releases/latest)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

<br/>

*Walk toward your router · measure your connection · trace every hop · know what your network can handle*

<br/>

| WiFi Finder | Speed Test | Traceroute | Usage Quality |
|:-----------:|:----------:|:----------:|:-------------:|
| <img src="docs/screenshots/wifi-finder.png" width="180" alt="WiFi Finder"/> | <img src="docs/screenshots/speed-test.png" width="180" alt="Speed Test"/> | <img src="docs/screenshots/traceroute.png" width="180" alt="Traceroute"/> | <img src="docs/screenshots/usage.png" width="180" alt="Usage Quality"/> |
| Geiger-counter sound guides you to the strongest WiFi spot | Download, upload, RPM and ping latency via Apple's engine | 3D globe with borders and place names — the whole route at a glance | Single latency mapped to hierarchical thresholds per use case |

</div>

---

## Features

| | |
| --- | --- |
| 🌐 **Globe icon** | Green / orange / red connectivity indicator, always visible in the menu bar |
| 📡 **WiFi Finder** | Walk around with Geiger-counter sound and concentric waves — find the strongest spot |
| 🔎 **WiFi Diagnostic** | Every visible access point listed individually (per-BSSID, not grouped by name) with signal, noise/SNR, channel width, Wi-Fi generation and security level — optional grouping by SSID |
| ⚡ **Speed Test** | Download, upload, RPM and latency via Apple's `networkQuality` engine |
| 🗺️ **Traceroute** | 3D globe with country borders and names — the full route is drawn at once and framed as hops arrive |
| 📊 **Usage Quality** | Single latency measurement mapped to hierarchical thresholds (mail → gaming) |
| ⚙️ **Preferences** | Launch at login via `SMAppService`, Sparkle auto-updates |

Choose **System default**, **English**, **Deutsch**, or **Français** in Preferences.
The language changes immediately in open windows and is saved for your next launch.
System default follows your preferred supported macOS language, with English as the fallback.

## Install

Grab the latest `.dmg` from the [Releases page](https://github.com/vincentlauriat/NetCheck/releases/latest), mount it, and drag `NetCheck.app` to `/Applications`.

**Requirements:** macOS 26 or later.

Releases are signed with an Apple Developer ID, built with the Hardened Runtime, and notarized by Apple — they open without any Gatekeeper warning.

## Build from source

**Requirements:** macOS 26+, Xcode 16+, [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen
git clone https://github.com/vincentlauriat/NetCheck.git
cd NetCheck
xcodegen generate
open NetCheck.xcodeproj
```

Or use the build script:

```bash
./Scripts/build.sh run   # build Debug + launch
```

## Architecture

Three targets, strict Swift 6 concurrency, no sandbox:

| Target | Role |
| --- | --- |
| `NetCheckCore` | Network logic — actors, async/await, zero UI |
| `NetCheckUI` | Shared SwiftUI components — Liquid Glass panels, `StatusBadge`, `FeatureWindowBackground` |
| `NetCheck` | App assembly — `NSStatusItem`, `WindowManager`, feature views |

See [ARCHITECTURE.md](ARCHITECTURE.md) for the full design.

## License

MIT © 2026 Vincent Lauriat — see [LICENSE](LICENSE).
