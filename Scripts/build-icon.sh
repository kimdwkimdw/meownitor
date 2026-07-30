#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
SOURCE="$ROOT/Resources/AppIconCandidates/09-behind-monitor.png"
OUTPUT="$ROOT/Resources/Meownitor.icns"
TEMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/MeownitorIcon.XXXXXX")
ICONSET="$TEMP_ROOT/Meownitor.iconset"
ROUNDTRIP="$TEMP_ROOT/Roundtrip.iconset"
trap 'rm -rf "$TEMP_ROOT"' EXIT

swift "$ROOT/Scripts/validate-app-icon.swift" "$SOURCE"
mkdir "$ICONSET"

make_icon() {
  sips -z "$2" "$2" "$SOURCE" --out "$ICONSET/$1" >/dev/null
}

make_icon icon_16x16.png 16
make_icon icon_16x16@2x.png 32
make_icon icon_32x32.png 32
make_icon icon_32x32@2x.png 64
make_icon icon_128x128.png 128
make_icon icon_128x128@2x.png 256
make_icon icon_256x256.png 256
make_icon icon_256x256@2x.png 512
make_icon icon_512x512.png 512
make_icon icon_512x512@2x.png 1024

swift "$ROOT/Scripts/validate-app-icon.swift" --allow-small "$ICONSET"/*.png
iconutil -c icns "$ICONSET" -o "$OUTPUT"
iconutil -c iconset "$OUTPUT" -o "$ROUNDTRIP"
swift "$ROOT/Scripts/validate-app-icon.swift" --allow-small "$ROUNDTRIP"/*.png
