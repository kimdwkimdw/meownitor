#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
OUT="$ROOT/dist/bundled-assets"
STAGE="$OUT/staging/Resources"
ARCHIVE="$OUT/Meownitor-Bundled-Assets-v1.zip"

rm -rf "$OUT"
mkdir -p "$STAGE/ElsaHD/runtime" "$STAGE/ko.lproj" "$STAGE/en.lproj"

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
cp "$ROOT/Resources/Meownitor.icns" "$STAGE/Meownitor.icns"
cp "$ROOT/Resources/ko.lproj/InfoPlist.strings" "$STAGE/ko.lproj/InfoPlist.strings"
cp "$ROOT/Resources/en.lproj/InfoPlist.strings" "$STAGE/en.lproj/InfoPlist.strings"
ditto -c -k --norsrc --noextattr --keepParent "$STAGE" "$ARCHIVE"
shasum -a 256 "$ARCHIVE" | awk '{print $1}' >"$ARCHIVE.sha256"
rm -rf "$OUT/staging"
echo "$OUT"
