#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
OUT="$ROOT/dist/bundled-assets"
STAGE="$OUT/staging/Resources"
ARCHIVE="$OUT/Meownitor-Bundled-Assets-v1.zip"

rm -rf "$OUT"
mkdir -p "$STAGE/ElsaHD/runtime" "$STAGE/ko.lproj" "$STAGE/en.lproj" "$STAGE/CatPacks"

count=$(find "$ROOT/Resources/ElsaHD/runtime" -maxdepth 1 -type f -name '*.webp' | wc -l | tr -d ' ')
[ "$count" -eq 15 ] || {
  echo "Elsa runtime has $count strips; expected 15" >&2
  exit 1
}
dimensions=$(identify -format '%wx%h\n' "$ROOT"/Resources/ElsaHD/runtime/*.webp | sort -u)
[ "$dimensions" = "8778x1254" ] || {
  echo "Elsa runtime has invalid dimensions: $dimensions" >&2
  exit 1
}

cp "$ROOT"/Resources/ElsaHD/runtime/*.webp "$STAGE/ElsaHD/runtime/"
for cat_id in K01 K02 K03; do
  source_dir="$ROOT/Resources/Cats/$cat_id/strips"
  count=$(find "$source_dir" -maxdepth 1 -type f -name '*.webp' | wc -l | tr -d ' ')
  [ "$count" -eq 15 ] || {
    echo "$cat_id runtime has $count strips; expected 15" >&2
    exit 1
  }
  dimensions=$(identify -format '%wx%h\n' "$source_dir"/*.webp | sort -u)
  [ "$dimensions" = "8778x1254" ] || {
    echo "$cat_id runtime has invalid dimensions: $dimensions" >&2
    exit 1
  }
  mkdir -p "$STAGE/Cats/$cat_id/strips"
  cp "$source_dir"/*.webp "$STAGE/Cats/$cat_id/strips/"
done
cp "$ROOT/Resources/Meownitor.icns" "$STAGE/Meownitor.icns"
cp "$ROOT/Resources/ko.lproj/InfoPlist.strings" "$STAGE/ko.lproj/InfoPlist.strings"
cp "$ROOT/Resources/en.lproj/InfoPlist.strings" "$STAGE/en.lproj/InfoPlist.strings"
cp "$ROOT/Resources/CatPacks/cat-packs.json" "$STAGE/CatPacks/cat-packs.json"
ditto -c -k --norsrc --noextattr --keepParent "$STAGE" "$ARCHIVE"
shasum -a 256 "$ARCHIVE" | awk '{print $1}' >"$ARCHIVE.sha256"
rm -rf "$OUT/staging"
echo "$OUT"
