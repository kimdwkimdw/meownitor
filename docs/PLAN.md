# Meownitor alpha roadmap

## Current release scope

- Three-language single-page website: English, Korean, Japanese.
- Four bundled cats: Elsa, Hodu (K01), Cheese (K02), Mochi (K03).
- Seventeen optional, individually downloadable packs: K04–K10, U01–U10.
- macOS 13+ universal app for Apple silicon and Intel, ad-hoc signed for alpha testing.
- Curated, checksummed artifacts in `v0.3.0-alpha.1`; previous asset releases preserved.
- GitHub Pages deployment from `web/` through GitHub Actions.

See [the release procedure](RELEASING.md) and [measured alpha validation](qa/WEB-ALPHA.md) for publication status and evidence.

## Completed implementation

- [x] Four-cat bundle, protected from optional-pack download/removal.
- [x] Production-evidence validation for every shipped animation sequence.
- [x] English/Korean/Japanese website, preview gallery, language preference, reduced-motion support, and individual download links.
- [x] Website checks and Pages workflow.
- [x] Universal app build and strict ad-hoc signature validation.

## Follow-up beyond the web alpha

- [ ] Developer ID signing and Apple notarization.
- [ ] Native app Japanese localization.
- [ ] Runtime testing on physical Intel hardware.
- [ ] Full native UI install/select/relaunch/remove acceptance cycle.

Keep raw artwork, experimental source frames, local QA evidence, and user-installed cats intact. Publish only validated runtime files and small web previews. Treat compilation, integrity checks, UI behavior, and public deployment as distinct evidence.
