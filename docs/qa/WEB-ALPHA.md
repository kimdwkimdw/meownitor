# Web alpha validation

Release: `v0.3.0-alpha.1` · 2026-09-05 KST

## Verified locally

- English, Korean, and Japanese page copy, accessible labels, and all 21 cat names/breeds are complete. URL and stored-language precedence, invalid-language fallback, catalog membership, release links, and asset budgets pass `node Scripts/check-web.mjs`.
- Web previews total 1.82 MiB. Full production artwork is excluded from Git and the website.
- `swift test`: 17 tests, 0 failures, including the four bundled cats’ 60 strips, all seven frames, visible pixels, and transparent corners.
- Universal release build: `x86_64 arm64`. Strict ad-hoc codesign validation passes.
- All 17 optional packs pass the production-evidence and strip-dimension gates. U03’s four extra experimental source directories are retained and excluded from the packs.

## Publication verification

Release asset round-trip, clean-checkout bootstrap, GitHub Actions, and served Pages content are pending until publication. Add measured results here after those checks finish.

## Limits

The Mac app has no Developer ID signature or notarization. Native app UI is Korean/English; the website adds Japanese. Intel compilation does not establish runtime testing on Intel hardware. Browser interaction/visual QA and a full native UI installation cycle have not been performed in this release task. The local installed app and existing user cat downloads are left untouched.
