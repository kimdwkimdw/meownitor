#!/usr/bin/env python3

import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("input")
    parser.add_argument("--output", required=True)
    parser.add_argument("--json-out")
    parser.add_argument("--edge-radius", type=int, default=48)
    args = parser.parse_args()

    with Image.open(args.input) as opened:
        image = opened.convert("RGBA")

    pixels = np.asarray(image, dtype=np.uint8).copy()
    radius = args.edge_radius
    transparent = np.pad(
        pixels[:, :, 3] == 0,
        ((radius, radius), (radius, radius)),
        constant_values=True,
    )
    integral = np.pad(transparent, ((1, 0), (1, 0))).cumsum(0).cumsum(1)
    width = radius * 2 + 1
    edge = (
        integral[width:, width:]
        - integral[:-width, width:]
        - integral[width:, :-width]
        + integral[:-width, :-width]
    ) > 0
    red = pixels[:, :, 0].astype(np.int16)
    green = pixels[:, :, 1].astype(np.int16)
    blue = pixels[:, :, 2].astype(np.int16)
    mask = (
        (pixels[:, :, 3] > 0)
        & edge
        & (red - green > 8)
        & (blue - green >= -3)
    )
    neutral = np.maximum.reduce((red, green, blue)).astype(np.uint8)
    pixels[:, :, 0][mask] = neutral[mask]
    pixels[:, :, 1][mask] = neutral[mask]
    pixels[:, :, 2][mask] = neutral[mask]
    changed = int(np.count_nonzero(mask))
    image = Image.fromarray(pixels, "RGBA")
    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    image.save(output_path)

    if args.json_out:
        Path(args.json_out).write_text(
            json.dumps(
                {
                    "ok": True,
                    "algorithm": "edge-local-magenta-reflection-neutralization",
                    "changed_pixels": changed,
                    "alpha_preserved": True,
                },
                indent=2,
            )
            + "\n"
        )


if __name__ == "__main__":
    main()
