#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
OUT="$ROOT/dist/cat-packs"
REPOSITORY=${CAT_PACK_REPOSITORY:-kimdwkimdw/meownitor}
TAG=${CAT_PACK_TAG:-cat-packs-v1}

if [ "$#" -eq 0 ]; then
  echo "usage: $0 K01 [K02 ...]" >&2
  exit 2
fi

rm -rf "$OUT"
mkdir -p "$OUT/staging"
MANIFEST="$OUT/cat-packs.json"
printf '{\n  "version": 1,\n  "packs": [\n' >"$MANIFEST"
separator=

for cat_id in "$@"; do
  case "$cat_id" in
    K[0-9][0-9] | U[0-9][0-9]) ;;
    *)
      echo "invalid cat id: $cat_id" >&2
      exit 2
      ;;
  esac

  source_dir="$ROOT/Resources/Cats/$cat_id/strips"
  [ -d "$source_dir" ] || {
    echo "missing strips: $cat_id" >&2
    exit 1
  }
  count=$(find "$source_dir" -maxdepth 1 -type f -name '*.webp' | wc -l | tr -d ' ')
  [ "$count" -eq 15 ] || {
    echo "$cat_id has $count strips; expected 15" >&2
    exit 1
  }
  dimensions=$(identify -format '%wx%h\n' "$source_dir"/*.webp | sort -u)
  [ "$dimensions" = "8778x1254" ] || {
    echo "$cat_id has invalid strip dimensions: $dimensions" >&2
    exit 1
  }
  raw_count=$(find "$ROOT/Resources/Cats/$cat_id/raw" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
  intermediate_count=$(find "$ROOT/Resources/Cats/$cat_id/intermediate" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
  chroma_count=$(find "$ROOT/Resources/Cats/$cat_id/qa" -maxdepth 1 -type f -name 'chroma-*.json' ! -name 'chroma-despill.json' | wc -l | tr -d ' ')
  reflection_count=$(find "$ROOT/Resources/Cats/$cat_id/qa" -maxdepth 1 -type f -name 'reflection-*.json' ! -name 'reflection-neutralization.json' | wc -l | tr -d ' ')
  [ "$raw_count" -eq 15 ] && [ "$intermediate_count" -eq 15 ] \
    && [ "$chroma_count" -eq 15 ] && [ "$reflection_count" -eq 15 ] || {
    echo "$cat_id has incomplete production evidence: raw=$raw_count intermediate=$intermediate_count chroma=$chroma_count reflection=$reflection_count" >&2
    exit 1
  }

  stage="$OUT/staging/$cat_id/strips"
  mkdir -p "$stage"
  cp "$source_dir"/*.webp "$stage/"
  archive_name="Meownitor-Cat-$cat_id-v1.zip"
  archive="$OUT/$archive_name"
  ditto -c -k --norsrc --noextattr --keepParent "$OUT/staging/$cat_id" "$archive"
  digest=$(shasum -a 256 "$archive" | awk '{print $1}')
  bytes=$(stat -f '%z' "$archive")
  url="https://github.com/$REPOSITORY/releases/download/$TAG/$archive_name"

  [ -z "$separator" ] || printf ',\n' >>"$MANIFEST"
  printf '    {"id":"%s","version":1,"bytes":%s,"sha256":"%s","url":"%s"}' \
    "$cat_id" "$bytes" "$digest" "$url" >>"$MANIFEST"
  separator=written
done

printf '\n  ]\n}\n' >>"$MANIFEST"
python3 -m json.tool "$MANIFEST" >/dev/null
rm -rf "$OUT/staging"
echo "$OUT"
