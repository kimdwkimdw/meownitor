#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
BASE_URL=${MEOWNITOR_ASSET_URL:-https://github.com/kimdwkimdw/meownitor/releases/download/bundled-assets-v1}
ARCHIVE_NAME=Meownitor-Bundled-Assets-v1.zip
TEMP=$(mktemp -d "${TMPDIR:-/tmp}/meownitor-assets.XXXXXX")
trap 'rm -rf "$TEMP"' EXIT

curl --fail --location --silent --show-error \
  "$BASE_URL/$ARCHIVE_NAME" -o "$TEMP/$ARCHIVE_NAME"
curl --fail --location --silent --show-error \
  "$BASE_URL/$ARCHIVE_NAME.sha256" -o "$TEMP/$ARCHIVE_NAME.sha256"
expected=$(tr -d '[:space:]' <"$TEMP/$ARCHIVE_NAME.sha256")
actual=$(shasum -a 256 "$TEMP/$ARCHIVE_NAME" | awk '{print $1}')
[ "$expected" = "$actual" ] || {
  echo "bundled asset checksum mismatch" >&2
  exit 1
}

ditto -x -k "$TEMP/$ARCHIVE_NAME" "$TEMP/unpacked"
source="$TEMP/unpacked/Resources"
[ -f "$source/Meownitor.icns" ] || {
  echo "bundled asset archive is invalid" >&2
  exit 1
}
count=$(find "$source/ElsaHD/runtime" -maxdepth 1 -type f -name '*.webp' | wc -l | tr -d ' ')
[ "$count" -eq 15 ] || {
  echo "bundled asset archive has $count Elsa strips; expected 15" >&2
  exit 1
}

mkdir -p "$ROOT/Resources"
ditto "$source" "$ROOT/Resources"
echo "$ROOT/Resources"
