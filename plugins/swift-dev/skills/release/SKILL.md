---
name: release
description: |
  macOS app release conventions for shipping a Developer-ID-signed, notarized
  SwiftUI app via GitHub Actions and a Homebrew cask hosted in the same repo.
  Covers two-workflow CI/release layout, signing, notarization, stapling,
  signed DMG creation, pinned cask SHAs, and CI-driven cask bumps.
  Use when setting up release automation for a macOS app, configuring signing
  and notarization, authoring a Homebrew cask, or diagnosing notarization and
  stapling failures.
allowed-tools: Read, Write, Edit, Bash
---

# macOS App Release Conventions

House playbook for shipping a Developer-ID-signed, notarized macOS SwiftUI app via GitHub Actions and a Homebrew cask in the same repo. Derived from `macos-name-tag-app`, with two deliberate improvements: **pinned cask SHAs** and **CI-driven cask bumps**.

## Scope

Covers:
- Two-workflow GitHub Actions layout (CI on push, release on tag)
- Developer ID signing + notarization + stapling
- Signed DMG with `Applications` symlink
- Homebrew cask hosted in the same repo, with a CI step that rewrites the cask on every release
- Required secrets and first-time setup
- Failure modes and their fixes

Not covered:
- Sparkle auto-updates (brew handles updates)
- Mac App Store distribution (different signing, different sandbox story)
- `homebrew-cask` upstream submission (pinning SHAs keeps this door open; this file doesn't walk through it)

## Repo layout

```
<repo-root>/
├── <AppName>.xcodeproj/
├── <AppName>/                       # Swift sources
├── <AppName>Tests/                  # Swift Testing
├── Casks/
│   └── <app-slug>.rb                # Homebrew cask, bumped by CI on release
├── .github/workflows/
│   ├── build.yml                    # CI on push/PR to main
│   └── release.yml                  # Release on v* tag
└── README.md                        # Install instructions
```

One repo, one app, one cask. No separate tap repo.

## Versioning

- Git tags drive versions: `v1.2.3` → `MARKETING_VERSION=1.2.3`.
- `Info.plist` `CFBundleShortVersionString` is overridden from the tag via `MARKETING_VERSION=` on the `xcodebuild` command line. Don't commit version bumps into `Info.plist` — the tag is the source of truth.
- `CFBundleVersion` (build number) can stay at `1` if you don't need monotonic build numbers. If you do, use `GITHUB_RUN_NUMBER` in the build command.

## Required GitHub secrets

Five secrets, created once:

| Secret | How to get it |
|---|---|
| `CERTIFICATE_P12` | Export your "Developer ID Application" cert + private key from Keychain Access as `.p12`. Run `base64 -i cert.p12 \| pbcopy` and paste. |
| `CERTIFICATE_PASSWORD` | The passphrase you set when exporting the `.p12`. |
| `APPLE_TEAM_ID` | 10-char Team ID from developer.apple.com → Account → Membership. |
| `APPLE_ID` | The Apple ID (email) associated with the developer account. |
| `APP_SPECIFIC_PASSWORD` | appleid.apple.com → Sign-In & Security → App-Specific Passwords. Generate one, label it "GitHub Actions notarytool". |

Put all five in `Settings → Secrets and variables → Actions → Repository secrets`.

## `.github/workflows/build.yml` — CI

Triggers on push/PR to `main`. Unsigned debug build + tests. Fast. Needs no secrets.

```yaml
name: Build & Test

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build-and-test:
    runs-on: macos-15
    steps:
      - uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_16.2.app

      - name: Build
        run: |
          xcodebuild \
            -project <AppName>.xcodeproj \
            -scheme <AppName> \
            -configuration Debug \
            -derivedDataPath build \
            CODE_SIGN_IDENTITY="-" \
            CODE_SIGNING_REQUIRED=NO \
            build

      - name: Run Tests
        run: |
          xcodebuild \
            -project <AppName>.xcodeproj \
            -scheme <AppName> \
            -configuration Debug \
            -derivedDataPath build \
            CODE_SIGN_IDENTITY="-" \
            CODE_SIGNING_REQUIRED=NO \
            test

      - name: Verify app bundle
        run: |
          APP_PATH="build/Build/Products/Debug/<AppName>.app"
          test -d "$APP_PATH" || { echo "App bundle not found"; exit 1; }
```

## `.github/workflows/release.yml` — Release

Triggers on `v*` tags. Signs, notarizes, staples, builds DMG, creates GitHub Release, **then rewrites the cask and pushes it back to main**.

Order matters: release is published *before* the cask commit. If the cask commit fails, brew users stay on the prior version; they never see a broken cask pointing at a missing asset.

```yaml
name: Release

on:
  push:
    tags:
      - "v*"

permissions:
  contents: write

jobs:
  release:
    runs-on: macos-15
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0          # needed to push the cask bump

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_16.2.app

      - name: Extract version from tag
        id: version
        run: echo "version=${GITHUB_REF_NAME#v}" >> "$GITHUB_OUTPUT"

      - name: Install signing certificate
        env:
          CERTIFICATE_P12: ${{ secrets.CERTIFICATE_P12 }}
          CERTIFICATE_PASSWORD: ${{ secrets.CERTIFICATE_PASSWORD }}
        run: |
          KEYCHAIN_PATH=$RUNNER_TEMP/signing.keychain-db
          KEYCHAIN_PASSWORD=$(openssl rand -base64 32)
          security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
          security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
          security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
          CERT_PATH=$RUNNER_TEMP/certificate.p12
          echo "$CERTIFICATE_P12" | base64 --decode > "$CERT_PATH"
          security import "$CERT_PATH" \
            -P "$CERTIFICATE_PASSWORD" \
            -A -t cert -f pkcs12 -k "$KEYCHAIN_PATH"
          security list-keychains -d user -s "$KEYCHAIN_PATH" login.keychain-db
          security set-key-partition-list -S apple-tool:,apple: -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
          security find-identity -v -p codesigning "$KEYCHAIN_PATH"

      - name: Build Release
        env:
          APPLE_TEAM_ID: ${{ secrets.APPLE_TEAM_ID }}
        run: |
          xcodebuild \
            -project <AppName>.xcodeproj \
            -scheme <AppName> \
            -configuration Release \
            -derivedDataPath build \
            CODE_SIGN_IDENTITY="Developer ID Application" \
            CODE_SIGNING_REQUIRED=YES \
            CODE_SIGN_STYLE=Manual \
            DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
            ENABLE_HARDENED_RUNTIME=YES \
            CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
            OTHER_CODE_SIGN_FLAGS="--timestamp --options runtime" \
            MARKETING_VERSION=${{ steps.version.outputs.version }} \
            build

      - name: Notarize app
        env:
          APPLE_ID: ${{ secrets.APPLE_ID }}
          APP_SPECIFIC_PASSWORD: ${{ secrets.APP_SPECIFIC_PASSWORD }}
          APPLE_TEAM_ID: ${{ secrets.APPLE_TEAM_ID }}
        run: |
          APP_PATH="build/Build/Products/Release/<AppName>.app"
          ditto -c -k --keepParent "$APP_PATH" <AppName>.zip

          SUBMISSION_ID=$(xcrun notarytool submit <AppName>.zip \
            --apple-id "$APPLE_ID" \
            --password "$APP_SPECIFIC_PASSWORD" \
            --team-id "$APPLE_TEAM_ID" \
            --wait \
            --output-format json | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])")

          STATUS=$(xcrun notarytool info "$SUBMISSION_ID" \
            --apple-id "$APPLE_ID" \
            --password "$APP_SPECIFIC_PASSWORD" \
            --team-id "$APPLE_TEAM_ID" \
            --output-format json | python3 -c "import sys,json; print(json.load(sys.stdin)['status'])")

          if [ "$STATUS" != "Accepted" ]; then
            echo "::error::Notarization failed with status: $STATUS"
            xcrun notarytool log "$SUBMISSION_ID" \
              --apple-id "$APPLE_ID" \
              --password "$APP_SPECIFIC_PASSWORD" \
              --team-id "$APPLE_TEAM_ID"
            exit 1
          fi

          xcrun stapler staple "$APP_PATH"

      - name: Create DMG
        id: dmg
        run: |
          APP_PATH="build/Build/Products/Release/<AppName>.app"
          VERSION=${{ steps.version.outputs.version }}
          DMG_NAME="<AppName>-${VERSION}.dmg"

          mkdir -p dmg_contents
          cp -R "$APP_PATH" dmg_contents/
          ln -s /Applications dmg_contents/Applications

          hdiutil create \
            -volname "<AppName>" \
            -srcfolder dmg_contents \
            -ov -format UDZO \
            "$DMG_NAME"

          codesign --force --sign "Developer ID Application" --timestamp "$DMG_NAME"

          DMG_SHA=$(shasum -a 256 "$DMG_NAME" | awk '{print $1}')
          echo "dmg_name=$DMG_NAME" >> "$GITHUB_OUTPUT"
          echo "dmg_sha=$DMG_SHA" >> "$GITHUB_OUTPUT"

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          files: ${{ steps.dmg.outputs.dmg_name }}
          generate_release_notes: true
          draft: false
          prerelease: false

      - name: Update cask with pinned SHA
        env:
          VERSION: ${{ steps.version.outputs.version }}
          DMG_SHA: ${{ steps.dmg.outputs.dmg_sha }}
          CASK_PATH: Casks/<app-slug>.rb
        run: |
          # Replace version and sha256 lines in the cask.
          # These regexes target a fixed shape: `version "..."` and `sha256 "..."`.
          sed -i.bak -E "s/^(\s*version) \"[^\"]*\"/\1 \"${VERSION}\"/" "$CASK_PATH"
          sed -i.bak -E "s/^(\s*sha256) \"[^\"]*\"/\1 \"${DMG_SHA}\"/" "$CASK_PATH"
          rm -f "${CASK_PATH}.bak"

          git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
          git config user.name  "github-actions[bot]"
          git add "$CASK_PATH"
          git commit -m "chore(cask): bump <app-slug> to v${VERSION}"
          # Push to the branch main points at. The tag was created from main.
          git push origin HEAD:main

      - name: Cleanup keychain
        if: always()
        run: |
          security delete-keychain "$RUNNER_TEMP/signing.keychain-db" 2>/dev/null || true
```

## `Casks/<app-slug>.rb` — initial seed

The first version of this file is committed by hand; CI rewrites `version` and `sha256` on every release.

```ruby
cask "<app-slug>" do
  version "0.0.0"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"

  url "https://github.com/<owner>/<repo>/releases/download/v#{version}/<AppName>-#{version}.dmg"
  name "<AppName>"
  desc "<one-line description>"
  homepage "https://github.com/<owner>/<repo>"

  depends_on macos: ">= :sonoma"        # match LSMinimumSystemVersion

  app "<AppName>.app"

  zap trash: [
    "~/Library/Preferences/<reverse-dns-bundle-id>.plist",
  ]
end
```

The `0.0.0` / zeros are placeholders. The first tagged release rewrites them. If you prefer the cask to be installable before any release exists, don't commit the cask until after the first successful release.

## README install block

```
brew tap <owner>/<repo> https://github.com/<owner>/<repo>
brew install --cask <app-slug>
```

No `--no-quarantine` flag — the app is notarized and stapled from v1.

## Info.plist requirements

- `LSUIElement = YES` (menu-bar only, no Dock icon)
- `LSMinimumSystemVersion` matches `depends_on macos:` in the cask
- Any TCC usage description strings the app needs (`NSScreenCaptureUsageDescription`, `NSMicrophoneUsageDescription`, etc.)
- `CFBundleIdentifier` is reverse-DNS and **must match the `zap trash:` path** in the cask

## Failure modes

| Symptom | Diagnosis | Fix |
|---|---|---|
| `notarytool` status `Invalid` | Unsigned binary inside the bundle, missing hardened runtime, missing timestamp | Workflow fetches the log automatically. Re-check `ENABLE_HARDENED_RUNTIME=YES` and `--timestamp --options runtime`. |
| Notarization succeeds, stapler fails | App path is a symlink, or the app was re-signed after submission | Don't edit the `.app` between notarize and staple. |
| `brew install` shows "damaged and can't be opened" | App isn't stapled, or the DMG itself isn't signed | `xcrun stapler validate <AppName>.app` locally; ensure the `codesign` step on the DMG ran. |
| Cask push step fails with 403 | Branch protection blocking `GITHUB_TOKEN`, or `permissions: contents: write` missing | Add `permissions: contents: write` at workflow root; if branch protection is on, allow the actions bot or use a PAT. |
| `brew upgrade --cask` doesn't see a new version | Prior cask used `version :latest` + `sha256 :no_check` | Once-off: bump manually, then let CI take over. |
| First release works but second one's cask commit pushed to the wrong branch | Tag was cut from a non-`main` branch | Always tag from `main`. Or change the push target to `HEAD:${{ github.event.repository.default_branch }}`. |

## Why pinned SHAs + CI rewrite

- **Integrity.** Anyone (including GitHub itself) replacing the release asset is caught at install time. `sha256 :no_check` skips this.
- **Correct `brew outdated`.** Brew compares `version` strings; `:latest` breaks this.
- **Upstream-friendly.** `homebrew-cask` (the main tap) requires pinned SHAs. Keeps that door open.
- **Still zero-maintenance for you.** CI does the bump — the human cost is identical to `:no_check`.

The one cost: one extra CI step and a bot commit on `main` per release. Worth it.

## First-release checklist

1. All five GitHub secrets populated.
2. `Casks/<app-slug>.rb` committed with placeholder version/SHA.
3. `Info.plist` has `LSUIElement`, `LSMinimumSystemVersion`, and any usage-description keys.
4. Cask `zap trash:` path matches `CFBundleIdentifier`.
5. Tag `v1.0.0` → workflow runs → release appears → cask commit lands on `main`.
6. On a clean Mac: `brew tap <owner>/<repo> https://github.com/<owner>/<repo> && brew install --cask <app-slug>`. App launches; Gatekeeper is silent.
7. `brew uninstall --zap --cask <app-slug>` removes the prefs file.

If step 6 shows a Gatekeeper warning, the DMG or app isn't stapled. Don't ship until that's clean.
