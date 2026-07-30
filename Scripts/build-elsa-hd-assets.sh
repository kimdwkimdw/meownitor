#!/bin/sh
set -eu

: "${PYTHON:?Set PYTHON to the bundled workspace Python executable}"

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
ASSETS="$ROOT/Resources/ElsaHD"
RAW="$ASSETS/raw"
INTERMEDIATE="$ASSETS/intermediate"
WORK="$ASSETS/work"
STRIPS="$ASSETS/strips"
QA="$ASSETS/qa"
REMOVE_KEY="$HOME/.codex/skills/.system/imagegen/scripts/remove_chroma_key.py"
DESPILL="$HOME/.codex/skills/hatch-pet/scripts/despill_chroma_edges.py"
NEUTRALIZE="$ROOT/Scripts/neutralize-magenta-reflection.py"
FRAME_SIZE=1254
KEY="#FC0ADE"

mkdir -p "$WORK" "$STRIPS" "$QA"
rm -f "$WORK"/*.png "$STRIPS"/*.png "$QA"/*.gif \
  "$QA"/chroma-*.json "$QA"/reflection-*.json "$QA/contact-sheet.png"

sequence_count=0
for sequence_dir in "$RAW"/[0-1][0-9]-*; do
  test -d "$sequence_dir" || continue
  sequence=$(basename "$sequence_dir")
  sequence_count=$((sequence_count + 1))

  frame_index=0
  for source in \
    "$sequence_dir/01.png" \
    "$INTERMEDIATE/$sequence/01-02.png" \
    "$sequence_dir/02.png" \
    "$INTERMEDIATE/$sequence/02-03.png" \
    "$sequence_dir/03.png" \
    "$INTERMEDIATE/$sequence/03-04.png" \
    "$sequence_dir/04.png"
  do
    frame_index=$((frame_index + 1))
    frame=$(printf '%02d' "$frame_index")
    matte="$WORK/$sequence-$frame-matte.png"
    normalized="$WORK/$sequence-$frame.png"
    test -f "$source"
    "$PYTHON" "$REMOVE_KEY" \
      --input "$source" \
      --out "$matte" \
      --auto-key border \
      --soft-matte \
      --transparent-threshold 12 \
      --opaque-threshold 220 \
      --force
    magick "$matte" \
      \( "$matte" -alpha extract \
        \( "$source" -alpha off -fuzz 20% -transparent "$KEY" \
          -alpha extract -threshold 0 -morphology Erode Disk:2 \) \
        -compose Lighten -composite \) \
      -alpha off -compose CopyOpacity -composite "$normalized"
  done

  row_pre="$WORK/$sequence-row-pre.png"
  row_despilled="$WORK/$sequence-row-despilled.png"
  strip="$STRIPS/$sequence.png"
  magick \
    "$WORK/$sequence-01.png" \
    "$WORK/$sequence-02.png" \
    "$WORK/$sequence-03.png" \
    "$WORK/$sequence-04.png" \
    "$WORK/$sequence-05.png" \
    "$WORK/$sequence-06.png" \
    "$WORK/$sequence-07.png" \
    +append "$row_pre"
  "$PYTHON" "$DESPILL" "$row_pre" \
    --output "$row_despilled" \
    --chroma-key "$KEY" \
    --edge-radius 12 \
    --spill-tolerance 0.08 \
    --minimum-saturation 0.05 \
    --json-out "$QA/chroma-$sequence.json"
  "$PYTHON" "$NEUTRALIZE" "$row_despilled" \
    --output "$strip" \
    --json-out "$QA/reflection-$sequence.json"
done

test "$sequence_count" -eq 15
jq -s '{ok: all(.[]; .ok), reports: .}' \
  "$QA"/chroma-[0-1][0-9]-*.json > "$QA/chroma-despill.json"
jq -e '.ok == true' "$QA/chroma-despill.json" >/dev/null
jq -s '{ok: all(.[]; .ok), reports: .}' \
  "$QA"/reflection-[0-1][0-9]-*.json > "$QA/reflection-neutralization.json"
jq -e '.ok == true' "$QA/reflection-neutralization.json" >/dev/null

for sequence_dir in "$RAW"/[0-1][0-9]-*; do
  test -d "$sequence_dir" || continue
  sequence=$(basename "$sequence_dir")
  strip="$STRIPS/$sequence.png"

  for frame in 0 1 2 3 4 5 6; do
    x=$((frame * FRAME_SIZE))
    magick "$strip" \
      -crop "${FRAME_SIZE}x${FRAME_SIZE}+$x+0" \
      +repage \
      -background "#202124" \
      -alpha background \
      -resize 384x384 \
      "$WORK/$sequence-preview-$frame.png"
  done
  magick -delay 12 \
    "$WORK/$sequence-preview-0.png" \
    "$WORK/$sequence-preview-1.png" \
    "$WORK/$sequence-preview-2.png" \
    "$WORK/$sequence-preview-3.png" \
    "$WORK/$sequence-preview-4.png" \
    "$WORK/$sequence-preview-5.png" \
    "$WORK/$sequence-preview-6.png" \
    -loop 0 "$QA/$sequence.gif"
done

magick montage "$STRIPS"/[0-1][0-9]-*.png \
  -thumbnail 1024x256 \
  -tile 1x15 \
  -geometry +8+8 \
  -background "#202124" \
  "$QA/contact-sheet.png"

test "$(find "$STRIPS" -type f -name '*.png' | wc -l | tr -d ' ')" -eq 15
test "$(magick identify -format '%wx%h\n' "$STRIPS"/*.png | sort -u)" = "8778x1254"
echo "$STRIPS"
