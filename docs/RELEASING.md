# Releases and GitHub Pages

The artwork catalog uses `v0.3.0-alpha.1`; the current Mac app uses `v0.3.0-alpha.3` (see app-only updates below). Release assets are immutable: the older `bundled-assets-v1` and `cat-packs-v1` releases remain unchanged for older clients. The `v1` in each ZIP filename is its asset format version.

## Prepare the curated artifacts

On the asset-production Mac, with ImageMagick, Node.js 22+, and the existing verified `Resources/` tree:

```sh
./Scripts/build-cat-packs.sh K04 K05 K06 K07 K08 K09 K10 U01 U02 U03 U04 U05 U06 U07 U08 U09 U10
cp dist/cat-packs/cat-packs.json Resources/CatPacks/cat-packs.json
./Scripts/build-bundled-assets.sh
node Scripts/build-web-assets.mjs
node Scripts/check-web.mjs
swift test
./Scripts/build-app.sh --arch arm64 --arch x86_64
codesign --verify --deep --strict .build/Meownitor.app
lipo -archs .build/Meownitor.app/Contents/MacOS/Meownitor
```

The pack builder verifies all 15 production sequences by name. Extra experimental source folders may remain locally; they are never packaged. A clean source checkout can bootstrap the four bundled cats. Regenerating all web previews also requires the optional cats under `Resources/Cats/<ID>/strips` and their pack manifest; normal website validation and deployment need neither full-size assets nor ImageMagick.

Package only these files in `dist/web-alpha/`:

```sh
mkdir -p dist/web-alpha
cp dist/cat-packs/*.zip dist/cat-packs/cat-packs.json dist/web-alpha/
cp dist/bundled-assets/*.zip dist/bundled-assets/*.sha256 dist/web-alpha/
ditto -c -k --norsrc --noextattr --keepParent .build/Meownitor.app dist/web-alpha/Meownitor-macOS-universal.zip
(cd web && zip -q -r ../dist/web-alpha/Meownitor-Web-Alpha.zip . -x '*.DS_Store')
(cd dist/web-alpha && shasum -a 256 *.zip cat-packs.json *.sha256 > SHA256SUMS.txt)
```

Do not upload `Resources/` wholesale, raw/intermediate/QA images, development logs, or staging directories. The release should have 23 assets: 17 cat ZIPs, one bundled ZIP and its checksum, one app ZIP, one website ZIP, the catalog, and the checksum manifest.

## Publish

Review and commit the source to a `codex/` branch first. Push that branch, then create a draft prerelease targeting its exact commit and upload the prepared artifacts. Validate draft asset sizes and hashes before publishing. Publish with `--prerelease --latest=false`; the release tag points to the source being shipped. Do not rewrite older releases.

The `Release` tag workflow rebuilds and tests the source. If the release already exists, it does not replace published artifacts. Once verified, fast-forward `main` to the same commit. Configure the repository’s Pages source as **GitHub Actions**; the `Pages` workflow checks and deploys only `web/`.

After publishing, independently download the public assets, verify `SHA256SUMS.txt`, bootstrap from a clean checkout, and check both the deployed page and its linked assets. Update [WEB-ALPHA.md](qa/WEB-ALPHA.md) with actual results.

## Signing and future releases

The current app has an ad-hoc signature, not a Developer ID signature or Apple notarization. Describe it as experimental on the page and in the release. A supported public Mac release still needs Developer ID signing, notarization, and Gatekeeper testing.

For a new asset release, update the tag in `web/content.mjs`, the HTML fallback links, `CatPackStore.remoteCatalogURL`, the bootstrap URL, pack-builder default, and catalog fixtures; regenerate the website catalog and run the checks. The download URL allowlist follows the app’s catalog URL. Keep previous release assets available for older apps.

## App-only updates

`v0.3.0-alpha.2` is an app-only update (bundle build 11). Publish the universal app ZIP and its `SHA256SUMS.txt`; the unchanged artwork and catalog remain at `v0.3.0-alpha.1`. `web/content.mjs` tracks `appReleaseTag` separately from the asset `releaseTag`. Update the app download fallback and README together. Use the same draft, exact-commit, public-download verification, and main fast-forward procedure above. The 23-file `check-release.mjs` gate applies to full asset releases, not app-only updates.

## Homebrew

After verifying a public app release, update `Casks/meownitor.rb` in [kimdwkimdw/homebrew-tap](https://github.com/kimdwkimdw/homebrew-tap) with the release version and the universal ZIP SHA-256. Run `brew style --cask kimdwkimdw/tap/meownitor` and `brew audit --cask kimdwkimdw/tap/meownitor`, then push and verify the tap installation/removal CI. Keep the app ZIP immutable; do not bypass quarantine or notarization checks in the cask.

`v0.3.0-alpha.3` (bundle build 12) adds a floating drag-and-drop Input Monitoring guide. Publish and verify it using the same app-only procedure, then update the Homebrew cask version and SHA-256.
