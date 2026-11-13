#!/usr/bin/env python3
"""Build the first original Handyman idle sprite as a CTHG resource.

Requires CairoSVG and Pillow:
    python3 -m pip install -r requirements.txt
"""
from pathlib import Path
import io
import struct

import cairosvg
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "resources" / "source" / "handyman" / "idle.svg"
OUTPUT_DIR = ROOT / "resources" / "custom-graphics" / "build"
OUTPUT = OUTPUT_DIR / "handyman-idle.cthg"

TILE_SIZE = 32
SPRITE_WIDTH = 64
SPRITE_HEIGHT = 80
ANIMATION_NAME = b"gpt_handyman_idle"


def u16(value):
    return struct.pack("<H", value)


def u32(value):
    return struct.pack("<I", value)


def i16(value):
    return struct.pack("<h", value)


def encode_rgba_sprite(image):
    """Encode RGBA pixels using CTHG's 32bpp run-length sprite format."""
    rgba = image.convert("RGBA")
    pixels = list(rgba.getdata())
    encoded = bytearray()
    index = 0

    while index < len(pixels):
        r, g, b, a = pixels[index]
        # CorsixTH's CTHG decoder supports opaque, uniform-alpha and
        # fully-transparent runs. Quantize alpha to 0..255 as stored.
        if a == 0:
            run_type = 2
            run_alpha = None
        elif a == 255:
            run_type = 0
            run_alpha = None
        else:
            run_type = 1
            run_alpha = a

        run = 1
        while index + run < len(pixels) and run < 63:
            nr, ng, nb, na = pixels[index + run]
            if run_type == 2 and na == 0:
                run += 1
            elif run_type == 0 and na == 255:
                run += 1
            elif run_type == 1 and na == run_alpha:
                run += 1
            else:
                break

        encoded.append((run_type << 6) | run)
        if run_type == 1:
            encoded.append(run_alpha)
        if run_type in (0, 1):
            for pr, pg, pb, _ in pixels[index:index + run]:
                encoded.extend((pr, pg, pb))
        index += run

    return bytes(encoded)


def build():
    if not SOURCE.is_file():
        raise SystemExit(f"Missing source artwork: {SOURCE}")

    png_bytes = cairosvg.svg2png(
        url=str(SOURCE),
        output_width=SPRITE_WIDTH,
        output_height=SPRITE_HEIGHT,
    )
    image = Image.open(io.BytesIO(png_bytes)).convert("RGBA")
    if image.size != (SPRITE_WIDTH, SPRITE_HEIGHT):
        raise SystemExit(f"Unexpected raster size: {image.size}")

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    image.save(OUTPUT_DIR / "handyman-idle.png")
    sprite_data = encode_rgba_sprite(image)

    # The sprite is positioned with its bottom centre at the tile origin.
    sprite_block = (
        b"SP" + u16(SPRITE_WIDTH) + u16(SPRITE_HEIGHT)
        + u32(len(sprite_data)) + sprite_data
    )
    element = (
        u32(0) + i16(-(SPRITE_WIDTH // 2)) + i16(-SPRITE_HEIGHT + 4)
        + bytes([0, 0]) + u16(0)
    )
    frame_block = b"FR" + u16(0) + u16(1) + element

    # read_string() uses a one-byte byte length followed by the name.
    name = bytes([len(ANIMATION_NAME)]) + ANIMATION_NAME
    missing = 0xFFFFFFFF
    animation_block = (
        b"CA" + u16(TILE_SIZE) + u32(1) + name
        + u32(0) + u32(missing) + u32(missing) + u32(missing)
    )

    header = (
        b"CTHG" + bytes([1, 2])
        + u32(1) + u32(1) + u32(1) + u32(1) + u32(len(sprite_data))
    )
    OUTPUT.write_bytes(header + sprite_block + frame_block + animation_block)
    print(f"Wrote {OUTPUT} ({OUTPUT.stat().st_size} bytes)")
    print(f"Raster preview: {OUTPUT_DIR / 'handyman-idle.png'}")
    print(f"Sprite data: {SPRITE_WIDTH}x{SPRITE_HEIGHT}, {len(sprite_data)} bytes")


if __name__ == "__main__":
    build()
