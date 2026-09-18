# Web alpha validation

Release: `v0.3.0-alpha.1` · 2026-09-05 KST

## Verified locally

- English, Korean, and Japanese page copy, accessible labels, and all 21 cat names/breeds are complete. URL and stored-language precedence, invalid-language fallback, catalog membership, release links, and asset budgets pass `node Scripts/check-web.mjs`.
- Web previews total 1.82 MiB. Full production artwork is excluded from Git and the website.
- `swift test`: 17 tests, 0 failures, including the four bundled cats’ 60 strips, all seven frames, visible pixels, and transparent corners.
- Universal release build: `x86_64 arm64`. Strict ad-hoc codesign validation passes.
- All 17 optional packs pass the production-evidence and strip-dimension gates. U03’s four extra experimental source directories are retained and excluded from the packs.

## Publication verification

- [Public prerelease](https://github.com/kimdwkimdw/meownitor/releases/tag/v0.3.0-alpha.1) published at 2026-09-05 20:05:48 KST, targeting `2ebeded2e9d6103c05ae43dcad0e949b1df8859c`.
- Exactly 23 curated assets, 419,653,464 bytes in total. GitHub’s uploaded sizes and SHA-256 digests match local files. All 23 files were downloaded again; `node Scripts/check-release.mjs` passed every checksum, archive member, embedded catalog, and website-content comparison.
- All 23 public download URLs return HTTP 200 without authentication.
- Clean checkout of the release tag restored 60 bundled strips, the icon, localized metadata, and the 17-pack catalog using the public bootstrap URL. Website checks passed with no source changes.
- `MEOWNITOR_RELEASE_SMOKE=1 swift test --filter CatProfileTests.testPublishedCatInstallAndRemoval`: passed in 2.4 seconds. The app fetched its public 17-pack catalog, downloaded K04, validated and installed all 15 strips in temporary storage, and removed it successfully.
- [Pages workflow](https://github.com/kimdwkimdw/meownitor/actions/runs/33962424958): passed. The 48 served page/module/style/image files match local and release bytes. Public URL: [Meownitor](https://kimdwkimdw.github.io/meownitor/).
- Served `index.html` SHA-256: `fcdbbc1353998c1281f4e72ce63425ea5dc383e0c37d1bf48eeac5b31780d799`.
- [Native Build workflow](https://github.com/kimdwkimdw/meownitor/actions/runs/33962424953): passed in 3m50s, including public bootstrap, the Swift suite, and app packaging.
- [Release workflow](https://github.com/kimdwkimdw/meownitor/actions/runs/33962405342): passed in 4m11s, including a clean universal build and strict codesign verification. Published artifacts were preserved.
- The default CI suite discovers 18 tests: 17 pass and the opt-in public installation test is skipped. That installation test was run separately and passed as recorded above.

The release commit was made without a Git signature because local GPG required interactive passphrase entry. Repository and global signing settings were preserved. This is separate from the app’s verified ad-hoc code signature.

## Limits

The Mac app has no Developer ID signature or notarization. Native app UI is Korean/English; the website adds Japanese. Intel compilation does not establish runtime testing on Intel hardware. Browser interaction/visual QA and a full native UI installation cycle have not been performed in this release task. The local installed app and existing user cat downloads are left untouched.

## App update v0.3.0-alpha.2 · 2026-09-19 KST

- Source: `058329cbaed7d9cd29017e9d06a7664a0cbd3f7f`, bundle build 11. Adds persistent dismissal of the Input Monitoring notice; regular dismissal remains temporary.
- `swift test`: 18 passed, 1 opt-in network test skipped. The skipped public cat installation/removal test was run separately with `MEOWNITOR_RELEASE_SMOKE=1` and passed.
- `node Scripts/check-web.mjs`, universal `x86_64 arm64` build, and strict codesign validation passed. The unchanged catalog and artwork still use alpha.1.
- Installed the new app after backing up the old app. Native UI exposed the Korean “다시 보지 않기” button; clicking it saved `hideInputMonitoringNotice = 1`, which remained set after process relaunch. Unit coverage verifies that ordinary dismissal does not suppress future notices and that suppression survives a new defaults/controller instance.
- Downloaded the draft and public ZIP independently: checksums passed, draft bytes matched local bytes, public app signature passed, and the public executable matched the installed executable.
- Clean source archive bootstrap passed. The deployed website serves alpha.2 app/checksum links and preserves alpha.1 artwork links.
- Git commit signing used the existing one-command unsigned fallback because GPG failed with `No such file or directory`; global signing settings were unchanged. The app remains ad-hoc signed and unnotarized. Intel runtime testing was not performed.
- [Build](https://github.com/kimdwkimdw/meownitor/actions/runs/35402878234), [Release](https://github.com/kimdwkimdw/meownitor/actions/runs/35402872072), and [Pages](https://github.com/kimdwkimdw/meownitor/actions/runs/35402878237) workflows all passed for the release commit.
