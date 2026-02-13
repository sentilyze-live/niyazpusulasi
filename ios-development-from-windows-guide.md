# iOS Development from Windows: Complete Guide (2025-2026)

## Table of Contents
1. [Cloud Mac Services](#1-cloud-mac-services)
2. [GitHub Actions with macOS Runners](#2-github-actions-with-macos-runners)
3. [Fastlane for Automated Deployment](#3-fastlane-for-automated-deployment)
4. [Swift on Windows](#4-swift-on-windows)
5. [Xcode Cloud](#5-xcode-cloud)
6. [Virtual Mac Options](#6-virtual-mac-options)
7. [Recommended Workflow for Solo Developer on Windows](#7-recommended-workflow)

---

## 1. Cloud Mac Services

### MacStadium
- **What**: Enterprise-grade cloud Mac infrastructure with Orka virtualization
- **Pricing**:
  - M4 Mac mini (10-core, 24GB): **$199/month** per node
  - Mac Studio Ultra (M1 Ultra, 128GB, 4TB SSD): **$599/month**
  - 1-3 year terms available; flat-rate billing (no usage-based surprises)
- **Features**:
  - Private cloud, dedicated servers, colocation
  - Orka virtualization/orchestration integrates with CI/CD tools (Jenkins, GitHub Actions, etc.)
  - Network and VM isolation, Linux workload support
  - SOC2 Type2, ISO certified
  - Ephemeral build environments for iOS testing
- **Best for**: Teams and enterprises with heavy CI/CD needs
- **Website**: https://macstadium.com/pricing

### MacinCloud
- **What**: On-demand cloud Mac servers accessible via remote desktop
- **Pricing**:
  - Managed Server Plans: starting ~**$25/month**
  - Pay-as-You-Go: prepay 30 hours of usage
  - Dedicated Server Plans: full admin/root access (higher tier)
  - **$0.99 trial** (24 hours) for first-time customers
- **Features**:
  - Xcode, Simulator, and common dev tools pre-installed
  - Access via RDP/VNC from Windows
  - Can submit apps to App Store from their servers
  - Supports Swift, Objective-C, Flutter, React Native
- **Best for**: Solo developers and small teams wanting affordable remote Mac access
- **Website**: https://www.macincloud.com

### AWS EC2 Mac Instances
- **What**: Dedicated Mac mini hosts in AWS data centers
- **Pricing** (On-Demand, US East):
  - mac2.metal (M2): **$0.65/hour** (~$468/month if 24/7)
  - mac2-m2.metal (M2): **$0.878/hour** (~$632/month)
  - mac2-m2pro.metal (M2 Pro): **$1.56/hour** (~$1,123/month)
  - mac1.metal (Intel): **$1.083/hour** (~$780/month)
- **Critical caveat**: **Minimum 24-hour allocation** required (Apple licensing). You pay for the dedicated host, not just instance uptime.
- **Best for**: Enterprises already on AWS, burst CI/CD usage
- **Website**: https://aws.amazon.com/ec2/instance-types/mac/

### Newer/Alternative Services (2025-2026)

| Service | Pricing | Notes |
|---------|---------|-------|
| **Codemagic** | 500 free build minutes/month; Pay-as-you-go; Pro $299/month (unlimited minutes) | Purpose-built for mobile CI/CD. Handles iOS builds, code signing, App Store deployment out of the box. |
| **Roundfleet** | Varies | 100% Apple Silicon (M2, M4 Pro). European datacenter (Toulouse, France). |
| **RentAMac.io** | Varies | Flexible rental of latest Mac hardware. |
| **Scaleway** | Varies | Mac mini hosting in European datacenters. |

---

## 2. GitHub Actions with macOS Runners

### Can you build and archive an iOS app?
**Yes, absolutely.** GitHub Actions macOS runners come with Xcode pre-installed. You can:
- Build .ipa files
- Archive the app
- Run unit and UI tests
- Sign with certificates and provisioning profiles

### Can you submit to App Store via Fastlane?
**Yes.** The standard workflow is:
1. Use `fastlane match` to fetch code signing certificates/profiles
2. Build and archive with `fastlane gym`
3. Upload to TestFlight with `fastlane pilot` or to App Store with `fastlane deliver`

### Pricing (as of January 2026)

| Plan | Free Minutes/Month | Storage |
|------|-------------------|---------|
| Free | 2,000 min | 500 MB |
| Pro ($4/mo) | 3,000 min | 1 GB |
| Team ($4/user/mo) | 3,000 min | 2 GB |
| Enterprise Cloud | 50,000 min | 50 GB |

**IMPORTANT: macOS runners have a 10x multiplier.** 1 minute of macOS runner time = 10 minutes from your quota.
- So on the Free plan: 2,000 / 10 = **200 actual macOS minutes/month**
- Per-minute cost for macOS (beyond free tier): ~**$0.08/minute** (reduced by up to 39% starting Jan 2026)

### Example Workflow: Build + Deploy iOS App to TestFlight

```yaml
name: iOS Build & Deploy to TestFlight

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  build-and-deploy:
    runs-on: macos-15
    timeout-minutes: 30

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Select Xcode version
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: latest-stable

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.3'
          bundler-cache: true

      - name: Install Fastlane
        run: bundle install

      - name: Decode App Store Connect API Key
        env:
          ASC_KEY_BASE64: ${{ secrets.ASC_KEY_BASE64 }}
        run: |
          echo "$ASC_KEY_BASE64" | base64 --decode > AuthKey.p8

      - name: Build and Upload to TestFlight
        env:
          ASC_KEY_ID: ${{ secrets.ASC_KEY_ID }}
          ASC_ISSUER_ID: ${{ secrets.ASC_ISSUER_ID }}
          ASC_KEY_PATH: AuthKey.p8
          MATCH_GIT_PRIVATE_KEY: ${{ secrets.MATCH_GIT_PRIVATE_KEY }}
          MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
        run: bundle exec fastlane ios build_upload_testflight
```

**Corresponding Fastfile:**
```ruby
default_platform(:ios)

platform :ios do
  desc "Build and upload to TestFlight"
  lane :build_upload_testflight do
    setup_ci  # creates temporary keychain on CI

    # Load App Store Connect API key
    api_key = app_store_connect_api_key(
      key_id: ENV["ASC_KEY_ID"],
      issuer_id: ENV["ASC_ISSUER_ID"],
      key_filepath: ENV["ASC_KEY_PATH"]
    )

    # Fetch signing certificates and profiles
    match(
      type: "appstore",
      readonly: true,
      api_key: api_key
    )

    # Increment build number
    increment_build_number(
      build_number: latest_testflight_build_number(api_key: api_key) + 1
    )

    # Build the app
    build_app(
      scheme: "YourAppScheme",
      export_method: "app-store",
      clean: true
    )

    # Upload to TestFlight
    upload_to_testflight(
      api_key: api_key,
      skip_waiting_for_build_processing: true
    )
  end
end
```

### Required GitHub Secrets:
| Secret | Description |
|--------|-------------|
| `ASC_KEY_ID` | App Store Connect API Key ID |
| `ASC_ISSUER_ID` | App Store Connect Issuer ID |
| `ASC_KEY_BASE64` | Base64-encoded AuthKey.p8 file |
| `MATCH_GIT_PRIVATE_KEY` | SSH key for Match certificates repo |
| `MATCH_PASSWORD` | Encryption password for Match |

---

## 3. Fastlane for Automated Deployment

### Can it handle code signing and provisioning profiles?
**Yes.** Fastlane's `match` tool is the industry standard:
- Stores certificates and provisioning profiles in a central location (Git repo, Google Cloud, or S3)
- All team members and CI systems pull from the same source
- Automatically creates/renews certificates when needed
- Supports development, ad-hoc, and App Store distribution profiles

### Can it submit to App Store Connect / TestFlight?
**Yes, fully.**
- `fastlane pilot` / `upload_to_testflight` - Upload to TestFlight
- `fastlane deliver` / `upload_to_app_store` - Submit to App Store review
- Can also manage screenshots, metadata, app descriptions
- Supports App Store Connect API key authentication (no interactive login needed)

### Does it work from CI/CD without a physical Mac?
**Yes, with a caveat**: It must run on macOS (physical or virtual). It works perfectly on:
- GitHub Actions macOS runners
- Codemagic
- MacStadium Orka VMs
- AWS EC2 Mac instances
- Any cloud Mac service

**Key Fastlane actions for CI/CD:**
| Action | Purpose |
|--------|---------|
| `setup_ci` | Creates temp keychain for CI environments |
| `match` | Fetches/manages code signing |
| `build_app` / `gym` | Builds and archives the .ipa |
| `upload_to_testflight` / `pilot` | Uploads to TestFlight |
| `upload_to_app_store` / `deliver` | Submits to App Store |
| `scan` | Runs tests |

---

## 4. Swift on Windows

### Can you compile Swift on Windows?
**Yes.** Swift has official Windows support since Swift 5.3 (2020), with continuous improvements.

**Installation**:
1. Download from https://www.swift.org/install/windows/
2. Install Windows toolchain (includes compiler, SPM, debugger)
3. ARM64 prebuilt toolchains now also available

### Can you run unit tests on Windows?
**Yes.**
- Both **XCTest** and the newer **Swift Testing** framework (included in Swift 6) work on Windows
- Swift Package Manager discovers and runs tests
- The VS Code Swift extension populates the Test Explorer with discovered tests

### Limitations
| What Works on Windows | What Does NOT Work on Windows |
|----------------------|-------------------------------|
| Swift language (full) | SwiftUI |
| Swift Package Manager | UIKit / AppKit |
| Foundation (cross-platform subset) | Interface Builder / Storyboards |
| Networking (URLSession basics) | iOS Simulator |
| XCTest and Swift Testing | Core Data (Apple-specific) |
| Command-line tools | Any Apple framework (MapKit, ARKit, etc.) |
| Server-side Swift (Vapor, Hummingbird) | .xcodeproj build system |
| Business logic, data models, algorithms | Code signing / provisioning |

**Practical takeaway**: You can write and test your **business logic, data models, networking layer, and algorithms** in Swift on Windows. You **cannot** build the UI or anything that depends on Apple frameworks.

---

## 5. Xcode Cloud (Apple's CI/CD)

### Does it eliminate the need for a local Mac?
**Almost, but not entirely.**
- **Initial setup REQUIRES Xcode** on a Mac (at least once). You need Xcode 15+ to configure the first workflow and connect your project to Xcode Cloud.
- **After initial setup**, you can manage workflows, trigger builds, and view results from the **App Store Connect web dashboard** in any browser (including on Windows).
- Workaround: Use a cloud Mac service (MacinCloud $0.99 trial) for the one-time initial setup.

### Pricing
| Tier | Compute Hours/Month | Price |
|------|---------------------|-------|
| **Included with Apple Developer Program** | 25 hours | **Free** (included in $99/year membership) |
| Tier 2 | 100 hours | $50/month |
| Tier 3 | 250 hours | $100/month |
| Tier 4 | 1,000 hours | $400/month |

The 25 free hours can support ~4 builds per day for a small-to-medium project.

### Can it build, test, and submit to App Store?
**Yes, all of the above:**
- Builds your app on Apple's cloud infrastructure
- Runs unit tests and UI tests
- Deploys to TestFlight for beta testing
- Submits to App Store for review
- Sends notifications on build success/failure
- Handles code signing automatically (managed signing)

### How to set it up from App Store Connect without Xcode?
You cannot do the **initial** setup without Xcode. Here is the practical workaround:

1. **One-time setup** (needs Mac access):
   - Use MacinCloud ($0.99 trial) or a friend's Mac
   - Open your project in Xcode 15+
   - Navigate to Report Navigator > Cloud > Get Started
   - Configure your first workflow
   - This takes ~15-30 minutes

2. **Ongoing management** (no Mac needed):
   - Log into https://appstoreconnect.apple.com from any browser
   - Edit workflows, trigger builds, view logs
   - Manage TestFlight distribution
   - Submit to App Store review

---

## 6. Virtual Mac Options (macOS VM on Windows)

### Is it legal?
**No, it violates Apple's EULA.** Apple's macOS Software License Agreement (Section 2B) states:
> "You may not install or use the Apple Software on any non-Apple-branded product."

- Running macOS in a VM on non-Apple hardware is a **license violation**
- Apple has not sued individual users, but has taken legal action against companies selling Hackintosh systems
- **It is only legal to virtualize macOS on genuine Apple hardware**

### Is it practical?
Despite being against the EULA, it is technically possible but problematic:

| Option | Status on Windows PC |
|--------|---------------------|
| **VMware Workstation** | Can run macOS with patches/workarounds. Performance is mediocre. No official support. |
| **VirtualBox** | Same as above. Worse GPU performance. |
| **UTM** | macOS-only app. Not available for Windows. |
| **Parallels** | macOS-only app. Not available for Windows. |
| **Docker-OSX** | Linux-based Hackintosh in Docker. Technically works but unreliable. |

### Verdict
**Not recommended.** It is both legally questionable and technically unreliable. Cloud Mac services are a much better option at $25-199/month.

---

## 7. Recommended Workflow for Solo Developer on Windows

### The Setup

You are on Windows, have an Apple Developer account ($99/year), and need to write, build, test, and ship an iOS app.

### Architecture: Separate Code Writing from Building

```
[Windows PC]                    [Cloud macOS]
     |                               |
  VS Code + Swift Extension     GitHub Actions macOS runner
  Write Swift code              OR Xcode Cloud
  Run logic unit tests          OR Codemagic
  Git push                           |
     |                          Build .ipa
     +--- GitHub repo ----------Test on Simulator
                                Code sign
                                Upload to TestFlight
                                Submit to App Store
```

### Step-by-Step Recommended Workflow

#### Step 1: Set Up Swift on Windows
1. Install Swift toolchain from https://www.swift.org/install/windows/
2. Install VS Code + Swift Extension (official, by Apple/swiftlang)
3. VS Code provides:
   - Syntax highlighting, code completion via SourceKit-LSP
   - Build tasks via Swift Package Manager
   - Test Explorer integration
   - Debugging support

#### Step 2: Structure Your Project for Maximum Windows Productivity
```
MyApp/
  Package.swift              <-- Swift Package (buildable on Windows)
  Sources/
    MyAppCore/               <-- Business logic, models, networking
      Models/
      Services/
      Utilities/
  Tests/
    MyAppCoreTests/          <-- Unit tests (runnable on Windows)
  MyApp.xcodeproj/           <-- Xcode project (for iOS app, UI layer)
  MyApp/
    Views/                   <-- SwiftUI views (only buildable on macOS)
    App.swift
```

- Keep business logic in a **Swift Package** (buildable and testable on Windows)
- Keep SwiftUI/UIKit code in the Xcode project (only builds on macOS)
- This lets you write and test 50-70% of your code on Windows

#### Step 3: Run Unit Tests on Windows
```bash
# In your Swift Package directory
swift test
```
- Tests for business logic, data models, networking, algorithms all run on Windows
- Both XCTest and Swift Testing (Swift 6+) are supported

#### Step 4: Set Up CI/CD (Choose One)

**Option A: GitHub Actions + Fastlane (RECOMMENDED for most developers)**
- Free tier: ~200 macOS minutes/month (enough for ~10-20 builds)
- Full control over the build pipeline
- Fastlane handles code signing, building, uploading
- See the workflow YAML example in Section 2 above

**Option B: Xcode Cloud (Simplest setup, Apple-native)**
- 25 free compute hours/month
- Apple handles code signing automatically
- Requires one-time Mac access for initial setup
- Managed entirely from App Store Connect web after setup

**Option C: Codemagic (Best for Flutter/React Native, also good for native)**
- 500 free build minutes/month
- Purpose-built for mobile CI/CD
- Handles code signing, building, deployment
- Good documentation for native iOS projects

#### Step 5: Code Signing Setup (One-Time)
1. Create an App Store Connect API Key (from browser):
   - Go to https://appstoreconnect.apple.com
   - Users and Access > Integrations > App Store Connect API
   - Generate a key, download the .p8 file

2. Set up Fastlane Match (needs one-time Mac access or cloud Mac):
   - Create a private Git repo for certificates
   - Run `fastlane match init` and `fastlane match appstore`
   - This generates and stores your certificates and profiles

3. Store secrets in GitHub Actions:
   - ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_BASE64
   - MATCH_GIT_PRIVATE_KEY, MATCH_PASSWORD

#### Step 6: Daily Development Cycle
```
Morning:
  1. Open VS Code on Windows
  2. Write/edit Swift code (business logic, models, services)
  3. Run unit tests locally: swift test
  4. Commit and push to GitHub

When ready to test on device:
  5. Push to main (or create a PR)
  6. GitHub Actions automatically:
     - Builds the iOS app
     - Runs all tests (including UI tests)
     - Uploads to TestFlight
  7. Install TestFlight build on your iPhone
  8. Test the app

When ready to release:
  9. Tag a release on GitHub
  10. GitHub Actions builds and submits to App Store
  11. Manage review from App Store Connect (browser)
```

#### Step 7: Running the iOS Simulator (When Needed)
You **cannot** run the iOS Simulator on Windows. Options:
- **Appetize.io**: Web-based iOS simulator (limited, for demos)
- **Cloud Mac** (MacinCloud): Remote desktop to a Mac with Simulator
- **Physical iPhone**: Use TestFlight builds from your CI/CD
- **BrowserStack/Sauce Labs**: Cloud device testing

### Cost Summary for Solo Developer

| Item | Cost | Notes |
|------|------|-------|
| Apple Developer Program | $99/year | Required |
| GitHub Free Plan | $0 | 200 macOS minutes/month |
| Swift toolchain (Windows) | $0 | Free from swift.org |
| VS Code + Swift Extension | $0 | Free |
| Fastlane | $0 | Open source |
| **One-time Mac access** for setup | $0.99-25 | MacinCloud trial or 1 month |
| **Total ongoing cost** | **~$99/year** | If GitHub free tier suffices |
| If you need more CI minutes | +$4-19/month | GitHub Pro or Team plan |
| If you need Simulator access | +$25/month | MacinCloud managed server |

### Quick Decision Matrix

| Your Situation | Recommended Approach |
|---------------|---------------------|
| Solo dev, budget-conscious | VS Code + GitHub Actions Free + Fastlane |
| Solo dev, want simplicity | VS Code + Xcode Cloud (25 free hours) |
| Small team (2-5 devs) | VS Code + GitHub Actions Pro + Fastlane + MacStadium |
| Flutter/React Native dev | VS Code + Codemagic |
| Enterprise | MacStadium Orka + GitHub Actions Enterprise |
| Just want to try iOS dev | MacinCloud $0.99 trial |

---

## Summary: What You CANNOT Avoid

No matter what workflow you choose, these are hard requirements:

1. **Apple Developer Program** ($99/year) - needed for App Store distribution
2. **macOS environment** for building - must be real Apple hardware (cloud or physical), VMs on non-Apple hardware violate Apple's EULA
3. **One-time Mac access** for initial Xcode Cloud setup or Fastlane Match setup
4. **A way to test on a real device** - TestFlight is the most practical option from Windows

## What You CAN Do Entirely on Windows

1. Write all Swift business logic code
2. Run unit tests for non-UI code
3. Manage your Git repository
4. Trigger CI/CD builds (push to GitHub)
5. Manage App Store Connect (web browser)
6. View build logs and test results
7. Manage TestFlight distribution (web browser)
8. Respond to App Store review feedback (web browser)
