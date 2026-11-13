#!/usr/bin/env python3
"""Build a tiny, self-contained CTHG named-animation probe for CorsixTH 0.70.2.

The generated animation is deliberately a small magenta square. It is a format
smoke-test only; it is not intended to be used as character artwork.
"""
from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "resources" / "custom-graphics" / "build" / "handyman-probe.cthg"


def u16(value):
    return struct.pack("<H", value)


def u32(value):
    return struct.pack("<I", value)


def i16(value):
    return struct.pack("<h", value)


def encode_opaque_sprite(width, height, rgb):
    """Encode one run of opaque RGB pixels using the CTHG 32bpp sprite format."""
    count = width * height
    if count < 1:
        raise ValueError("probe sprite must contain at least one pixel")
    r, g, b = rgb
    # The low six bits store the literal run length (1..63), not length - 1.
    # Split larger sprites into multiple opaque runs.
    encoded = bytearray()
    while count:
        run = min(count, 63)
        encoded.append(run)  # type 00: opaque RGB pixels
        encoded.extend(bytes([r, g, b]) * run)
        count -= run
    return bytes(encoded)


def build():
    width = height = 8
    sprite_data = encode_opaque_sprite(width, height, (255, 0, 255))

    # SP blocks must precede FR blocks because frame bounds are calculated
    # immediately while the frame is loaded. FR blocks must precede CA blocks
    # because CA first-frame indices are validated against already-loaded frames.
    sprite_block = (
        b"SP" + u16(width) + u16(height) + u32(len(sprite_data)) + sprite_data
    )

    # One element references sprite 0, positioned around the tile centre.
    element = (
        u32(0) + i16(-4) + i16(-4) +
        bytes([0, 0]) + u16(0)
    )
    frame_block = b"FR" + u16(0) + u16(1) + element

    # memory_reader::read_string() stores a one-byte length followed by raw bytes.
    animation_name = b"gpt_handyman_probe"
    name = bytes([len(animation_name)]) + animation_name
    missing = 0xFFFFFFFF
    animation_block = (
        b"CA" + u16(32) + u32(1) + name +
        u32(0) + u32(missing) + u32(missing) + u32(missing)
    )

    # load_custom_animations() expects CTHG version bytes 1, 2, followed by
    # five little-endian counters: animations, frames, elements, sprites,
    # and sprite-data bytes (the last counter is currently informational).
    header = (
        b"CTHG" + bytes([1, 2]) +
        u32(1) + u32(1) + u32(1) + u32(1) + u32(len(sprite_data))
    )
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_bytes(header + sprite_block + frame_block + animation_block)
    print(f"Wrote {OUTPUT} ({OUTPUT.stat().st_size} bytes)")


if __name__ == "__main__":
    build()
