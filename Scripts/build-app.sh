#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
APP="$ROOT/.build/Meownitor.app"
if [ -f "$ROOT/Resources/AppIconCandidates/09-behind-monitor.png" ]; then
  "$ROOT/Scripts/build-icon.sh"
elif [ ! -f "$ROOT/Resources/Meownitor.icns" ]; then
  echo "missing release assets; run Scripts/bootstrap-bundled-assets.sh" >&2
  exit 1
fi
swift build -c release --package-path "$ROOT"
BIN_DIR=$(swift build -c release --package-path "$ROOT" --show-bin-path)

rm -rf "$APP"
mkdir -p \
  "$APP/Contents/MacOS" \
  "$APP/Contents/Resources/ElsaHD" \
  "$APP/Contents/Resources/ko.lproj" \
  "$APP/Contents/Resources/en.lproj"
cp "$BIN_DIR/Meownitor" "$APP/Contents/MacOS/Meownitor"
cp "$ROOT/Info.plist" "$APP/Contents/Info.plist"
cp "$ROOT/Resources/Meownitor.icns" "$APP/Contents/Resources/Meownitor.icns"
cp "$ROOT/Resources/ko.lproj/InfoPlist.strings" \
  "$APP/Contents/Resources/ko.lproj/InfoPlist.strings"
cp "$ROOT/Resources/en.lproj/InfoPlist.strings" \
  "$APP/Contents/Resources/en.lproj/InfoPlist.strings"
cp "$ROOT"/Resources/ElsaHD/runtime/*.webp "$APP/Contents/Resources/ElsaHD/"
if [ -f "$ROOT/Resources/CatPacks/cat-packs.json" ]; then
  cp "$ROOT/Resources/CatPacks/cat-packs.json" "$APP/Contents/Resources/"
fi
codesign --force --deep --sign - "$APP"

echo "$APP"
