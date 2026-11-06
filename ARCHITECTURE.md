# NetCheck — Architecture

## Overview

NetCheck is split into three targets to enforce clean separation:

```
NetCheck/
├── Sources/
│   ├── NetCheckCore/          # Network logic — zero UI
│   │   ├── Monitor/           # ConnectivityMonitor, PingService
│   │   ├── WiFi/              # WiFiScanner, WiFiNetworkScanner, GeigerSoundEngine, WiFiSignal, WiFiNetworkInfo
│   │   ├── SpeedTest/         # SpeedTestService, SpeedTestProgress
│   │   ├── Traceroute/        # TracerouteService, GeoIPService, TracerouteHop
│   │   └── Usage/             # UsageQualityService, UsageProfile, QualityLevel
│   ├── NetCheckUI/            # Shared SwiftUI components
│   │   ├── GlassPanelView     # Liquid Glass panel wrapper
│   │   ├── StatusBadge        # Quality indicator badge
│   │   └── FeatureWindowBackground  # Tinted gradient backdrop, content kept below the title bar
│   └── NetCheck/              # App target — assembly only
│       ├── App/               # NetCheckApp, AppDelegate
│       ├── Features/          # One folder per feature
│       └── Resources/         # Assets.xcassets
├── Tests/
│   └── NetCheckCoreTests/     # Unit tests for Core logic
└── Scripts/
    ├── build.sh               # Debug build
    └── release.sh             # Codesign + notarize + DMG + Sparkle
```

## Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| macOS 26 minimum | Native Liquid Glass APIs |
| XcodeGen + xcodebuild | CLI-only build, no Xcode IDE required |
| `networkQuality` for speed test | Apple-native, same result as System Settings |
| MapKit `.hybrid(elevation: .realistic)` | 3D globe with country borders and place names; the full route is framed at once |
| `ip-api.com` for IP geolocation | Free, 45 req/min, no API key |
| Non-sandboxed | Required for traceroute, CoreWLAN RSSI, networkQuality |
| Sparkle 2.9.1 | EdDSA signatures, proven in production |
| CoreLocation authorization for WiFi Diagnostic | macOS only reveals SSID/BSSID of scanned networks (`CWInterface.scanForNetworks`) once Location Services is authorized — without it, same-name access points can't be told apart |

## Concurrency

All Core services use Swift 6 actors. ViewModels are `@MainActor @Observable`.
