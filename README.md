# Meownitor · 목펴라냥

A small cat. A gentler workday. A native macOS menu bar companion that reminds you to sit up and take a break.

**[English](https://kimdwkimdw.github.io/meownitor/?lang=en) · [한국어](https://kimdwkimdw.github.io/meownitor/?lang=ko) · [日本語](https://kimdwkimdw.github.io/meownitor/?lang=ja)**

[Visit the website](https://kimdwkimdw.github.io/meownitor/) · [Download the alpha](https://github.com/kimdwkimdw/meownitor/releases/tag/v0.3.0-alpha.1) · [Report a problem](https://github.com/kimdwkimdw/meownitor/issues)

## What it does

- **MacBook:** a cat appears after 25 active minutes using the built-in screen and keyboard. Connecting an external display or using an external keyboard resets the timer.
- **iMac:** a small break reminder every 30–60 minutes. Other desktop Macs do not show reminders.
- Snooze for 30 minutes, one hour, or two; press Escape twice to dismiss. Cat overlays stay on the built-in display.
- No camera, account, or saved keystrokes. Optional Input Monitoring permission distinguishes external keyboards; without it, display detection still works. Asset downloads connect to GitHub.

The website supports **English, Korean, and Japanese**. The native app currently supports **English and Korean**.

## Download only what you want

All full-size runtime assets are distributed through the [v0.3.0-alpha.1 release](https://github.com/kimdwkimdw/meownitor/releases/tag/v0.3.0-alpha.1), outside Git history.

| Download | Contents |
| --- | --- |
| `Meownitor-macOS-universal.zip` | macOS 13+ app for Apple silicon and Intel, with Elsa, Hodu, Cheese, and Mochi |
| `Meownitor-Cat-<ID>-v1.zip` | One optional cat: K04–K10 or U01–U10. Choose it on the website or install from the app’s Settings |
| `Meownitor-Bundled-Assets-v1.zip` | The four bundled cats, app icon, localized metadata, and download catalog for source builds |
| `Meownitor-Web-Alpha.zip` | The standalone static website; serve with any HTTP server |
| `cat-packs.json` / `SHA256SUMS.txt` | Pack URLs, sizes, and SHA-256 integrity checks |

Each optional cat has 15 WebP animation strips, seven frames per strip, at `8778×1254`. The app validates the checksum and file structure before installing to `~/Library/Application Support/Meownitor/Cats/<ID>/`. Bundled cats cannot be removed; optional cats can be removed in Settings.

**Alpha status:** the Mac app is ad-hoc signed and has not been notarized by Apple. macOS may block opening it. This release is for early testing; Developer ID signing and notarization remain future work. Existing `bundled-assets-v1` and `cat-packs-v1` releases are retained for older versions.

## Develop

macOS 13+, Swift 5.10+, and Node.js 22+ for website checks. The website has no package install or build step.

```sh
./Scripts/bootstrap-bundled-assets.sh
swift test
./Scripts/build-app.sh --arch arm64 --arch x86_64
codesign --verify --deep --strict .build/Meownitor.app

node Scripts/check-web.mjs
python3 -m http.server 8767 --bind 127.0.0.1 --directory web
```

Open `http://127.0.0.1:8767/`. Language links use `?lang=en`, `?lang=ko`, and `?lang=ja`. The first visit follows the browser language; an explicit choice is remembered locally. Reduced-motion preferences disable the preview animation.

GitHub Actions validates `web/` and deploys it to Pages on `main`. Only optimized web previews are tracked. `Resources/`, `dist/`, source artwork, intermediate frames, and local QA files stay out of Git.

## Project guide

- [Behavior](docs/BEHAVIOR.md) · [Architecture](docs/ARCHITECTURE.md)
- [Asset contract](docs/ASSETS.md) · [Cat catalog](docs/CAT-CANDIDATES.md)
- [Release procedure](docs/RELEASING.md) · [QA](docs/QA.md)
- [Alpha validation](docs/qa/WEB-ALPHA.md) · [Roadmap](docs/PLAN.md)
