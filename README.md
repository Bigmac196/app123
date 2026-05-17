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

## Build & run — exact step-by-step

You need a **Mac**. Follow these in order. Text in `monospace` is typed
exactly; **bold** is a button/menu you click.

### Step 0 — Install the tools (one time)

1. Open the **App Store** app on your Mac, search **Xcode**, click **Get** /
   **Install**. It's large (~7 GB) — let it finish.
2. Open Xcode once. If it asks to **Install** additional components, click
   **Install** and enter your Mac password.
3. Open the **Terminal** app (press `Cmd+Space`, type `Terminal`, press
   **Return**).
4. Install Homebrew (a tool installer). Copy-paste this whole line into
   Terminal, press **Return**, follow its prompts (it will ask for your Mac
   password — typing shows nothing, that's normal):
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```
5. When it finishes it may print 2 "Next steps" commands starting with
   `echo`. Copy-paste and run those too (skip if it didn't print any).
6. Install XcodeGen — paste and press **Return**:
   ```bash
   brew install xcodegen
   ```

### Step 1 — Get the code onto your Mac

In Terminal, paste these one at a time (press **Return** after each):

```bash
cd ~/Desktop
git clone https://github.com/bigmac196/app123.git
cd app123
git checkout claude/hypecheck-app-design-9hl5N
```

### Step 2 — Check the core logic works (optional but reassuring)

```bash
swift test
```

Wait. You want to see `Test Suite 'All tests' passed`. If you see failures,
copy them to me and stop here.

### Step 3 — Generate the Xcode project

```bash
xcodegen generate
open HypeCheck.xcodeproj
```

Xcode opens. The first time, it downloads packages (SwiftSoup, Google Mobile
Ads) — wait until the top status bar stops saying "Resolving / Cloning".

### Step 4 — Set your signing (so it can run on a simulator/phone)

1. In the left sidebar, click the blue **HypeCheck** icon at the very top.
2. In the middle pane, under **TARGETS**, click **HypeCheck**.
3. Click the **Signing & Capabilities** tab.
4. Check the box **Automatically manage signing**.
5. In the **Team** dropdown, pick your Apple ID. If none is listed: click
   **Add an Account…**, sign in with your Apple ID, then pick it. (A free
   Apple ID is fine for the simulator.)
6. If you see a red error about the bundle identifier being taken: change
   **Bundle Identifier** to something unique, e.g.
   `com.yourname.hypecheck`.
7. Now under **TARGETS** click **HypeCheckShare** and repeat steps 3–6, using
   the matching id `com.yourname.hypecheck.share`.

### Step 5 — Turn on App Groups (lets the Share button talk to the app)

Do this for **both** targets (HypeCheck, then HypeCheckShare):

1. With the target selected, still on **Signing & Capabilities**, click
   **+ Capability** (top-left of that tab).
2. Type `App Groups`, double-click it in the list.
3. A new **App Groups** section appears. Click the small **+** under it.
4. Type exactly: `group.com.hypecheck.app` and press **Return**. Make sure
   the checkbox next to it is ticked.
5. Switch to the other target and repeat — the group name must be **identical**
   on both.

> If you changed the bundle id in Step 4, you can keep the group name
> `group.com.hypecheck.app` as-is — just make sure it matches on both targets
> and matches `AppGroup.identifier` in
> `App/HypeCheck/Services/SharedStore.swift`.

### Step 6 — Hook up StoreKit testing (so the "Remove ads" purchases work locally)

1. Top menu bar: **Product → Scheme → Edit Scheme…**
2. In the left list click **Run**.
3. Click the **Options** tab.
4. Find **StoreKit Configuration**, click its dropdown, choose
   **Products.storekit**.
5. Click **Close**.

### Step 7 — Run it

1. Near the top-left, next to the ▶︎ Play button, there's a device dropdown.
   Click it and pick a simulator, e.g. **iPhone 15**.
2. Click the **▶︎** Play button (or press `Cmd+R`).
3. First run takes a while to build. The simulator launches the app.

### Step 8 — Try the app

- **Manual path (easiest):** on the Home screen tap **Check a link manually**,
  choose **Enter details**, fill in a title/price, tap **Analyze**. You should
  see a verdict, then (because you're not premium) a **test ad**, then the
  result screen.
- **Share path:** in the simulator open **Safari**, go to any Amazon product
  page, tap the **Share** icon, scroll to find **HypeCheck**, tap it.
- **Remove ads:** tap the **crown** icon (top-left on Home) or the
  **Remove ads** button → tap a purchase → in the StoreKit test sheet tap
  **Confirm** (no real money). Ads stop.

---

## Before you publish to the App Store (real money/IDs)

You can skip all of this while testing. Do it only when shipping for real:

1. **Real AdMob IDs**
   - Create a free account at <https://admob.google.com>, add an app, create an
     **Interstitial** ad unit.
   - In Xcode open `App/HypeCheck/Resources/Info.plist`, find
     **GADApplicationIdentifier**, replace its value with your real one
     (`ca-app-pub-XXXX~XXXX`).
   - Open `App/HypeCheck/Services/AdManager.swift`, find the line
     `var interstitialUnitID =` and replace it with your real ad unit id
     (`ca-app-pub-XXXX/XXXX`).
2. **Real in-app purchases** — in App Store Connect create three products with
   these exact IDs: `com.hypecheck.app.adfree.lifetime` (Non-Consumable),
   `com.hypecheck.app.adfree.monthly` and `com.hypecheck.app.adfree.yearly`
   (Auto-Renewable Subscriptions, one group).
3. **Privacy** — open `App/HypeCheck/Resources/PrivacyInfo.xcprivacy` and set
   the real ad tracking domains (Google publishes the list).
4. You'll also need a paid **Apple Developer Program** membership ($99/yr) to
   submit to the App Store.

## Monetization

Free with ads; an optional premium tier removes them.

- **Ads**: Google Mobile Ads (AdMob) interstitial shown after **every** check.
  This is the only ad/tracking component — see Privacy below.
- **Premium (ad-free)** via StoreKit 2, **no backend**:
  - One-time unlock — `com.hypecheck.app.adfree.lifetime` (non-consumable)
  - Subscription — `com.hypecheck.app.adfree.monthly` / `.yearly`
  - Either one sets `PurchaseManager.isPremium`, which suppresses all ads.
- Local testing: in the scheme's **Run → Options**, set the StoreKit
  configuration to `App/HypeCheck/Resources/Products.storekit`.
- **Before shipping**: replace the Google **test** IDs — `GADApplicationIdentifier`
  in `Info.plist` and `AdManager.interstitialUnitID` — with your real AdMob IDs,
  register the matching product IDs in App Store Connect, and set the real
  `NSPrivacyTrackingDomains` in `PrivacyInfo.xcprivacy`.

## Privacy

- **Product analysis is still 100% on-device.** The page fetch + parsing +
  scoring never leave the phone.
- The **ads module is the only networked/tracking component**: it requires the
  App Tracking Transparency prompt (`NSUserTrackingUsageDescription`) and
  collects ad/device identifiers. App Privacy is therefore **Data Collected
  (Third-Party Advertising)** — `PrivacyInfo.xcprivacy` is included and must be
  finalized with your real tracking domains.
- Premium users still see zero ads and zero ad tracking.
- No accounts, no analytics, no servers of your own.

## Disclaimers

Verdicts are heuristic estimates from listing text — not lab tests, and not
medical/financial advice. The skincare/supplement analyzers surface this
explicitly in-app.

See the engineering plan for MVP scope, phases, risks and App Store strategy.
