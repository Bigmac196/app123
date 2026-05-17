# HypeCheck

Fully offline iOS app: share a product link (Amazon, TikTok Shop, Walmart,
Target, Temu, …) and get an instant, explainable verdict on whether it's worth
buying or just hype. **No backend, no accounts, no data leaves the device.**

## What's in this repo

| Path | Purpose |
|---|---|
| `Sources/HypeCheckKit/` | Pure-Swift, **dependency-free** core: models, HTML parsing, category classifier, 10 category analyzers, scoring engine. Builds & tests on any platform. |
| `Tests/HypeCheckKitTests/` | XCTest suite + HTML fixtures. |
| `App/HypeCheck/` | SwiftUI app (MVVM), SwiftData history, SwiftSoup selector extractor. |
| `App/HypeCheckShare/` | Share Extension (URL + JS-preprocessed page text → App Group → deep link). |
| `Package.swift` | SPM manifest for the core kit (no third-party deps). |
| `project.yml` | XcodeGen spec that wires the app + extension + SwiftSoup. |

## Architecture

`Share → URL → PageFetcher (URLSession) → ProductParser (JSON-LD / OpenGraph /
microdata / SwiftSoup selectors) → CategoryClassifier → category Analyzer →
ScoringEngine → Verdict → SwiftData history → SwiftUI result screen.`

The core engine is split out as `HypeCheckKit` so it is unit-testable without
Xcode. SwiftSoup is layered in via the `HTMLExtracting` protocol — the core
parser already handles JSON-LD/OG/microdata with zero dependencies; SwiftSoup
only adds per-retailer CSS-selector fallbacks.

## Build & run

### 1. Core engine tests (no Xcode needed)

```bash
swift test            # runs HypeCheckKitTests
```

### 2. Full iOS app

```bash
brew install xcodegen          # one-time
xcodegen generate              # creates HypeCheck.xcodeproj
open HypeCheck.xcodeproj
```

Then in Xcode:

1. Set your team and a unique bundle ID prefix on both targets.
2. Enable the **App Groups** capability on `HypeCheck` and `HypeCheckShare`,
   using the same group id as `AppGroup.identifier`
   (`group.com.hypecheck.app` by default — change consistently).
3. Run on a device/simulator. Test the share flow from Safari, and the
   in-app **Check a product** manual path (reviewer-friendly, no share sheet).

## Privacy

- The only network request is the user-initiated download of the exact product
  page they shared, straight from the device (same as opening it in Safari).
- No analytics, no accounts, no third-party services. App Privacy =
  *Data Not Collected*. Add `PrivacyInfo.xcprivacy` before submission.

## Disclaimers

Verdicts are heuristic estimates from listing text — not lab tests, and not
medical/financial advice. The skincare/supplement analyzers surface this
explicitly in-app.

See the engineering plan for MVP scope, phases, risks and App Store strategy.
