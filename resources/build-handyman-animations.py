#!/usr/bin/env python3
"""Build all original Handyman SVG sheets into one CorsixTH CTHG resource.

Run from the repository root:
    python3 resources/build-handyman-animations.py
Requires CairoSVG and Pillow (already listed in requirements.txt).
"""
from pathlib import Path
import io
import re
import struct

import cairosvg
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "resources" / "source" / "handyman"
OUTPUT_DIR = ROOT / "resources" / "custom-graphics" / "build"
OUTPUT = OUTPUT_DIR / "handyman.cthg"

TILE_SIZE = 32
CELL_W = 64
CELL_H = 80
SPRITE_X = -(CELL_W // 2)
SPRITE_Y = -CELL_H + 4
MISSING = 0xFFFFFFFF


def u16(value):
    return struct.pack("<H", value)


def u32(value):
    return struct.pack("<I", value)


def i16(value):
    return struct.pack("<h", value)


def encode_rgba_sprite(image):
    """Encode RGBA pixels using CTHG's 32bpp run-length sprite format."""
    pixels = list(image.convert("RGBA").getdata())
    encoded = bytearray()
    index = 0

    while index < len(pixels):
        _, _, _, alpha = pixels[index]
        if alpha == 0:
            run_type, run_alpha = 2, None
        elif alpha == 255:
            run_type, run_alpha = 0, None
        else:
            run_type, run_alpha = 1, alpha

        run = 1
        while index + run < len(pixels) and run < 63:
            next_alpha = pixels[index + run][3]
            if run_type == 2 and next_alpha == 0:
                run += 1
            elif run_type == 0 and next_alpha == 255:
                run += 1
            elif run_type == 1 and next_alpha == run_alpha:
                run += 1
            else:
                break

        encoded.append((run_type << 6) | run)
        if run_type == 1:
            encoded.append(run_alpha)
        if run_type in (0, 1):
            for red, green, blue, _ in pixels[index:index + run]:
                encoded.extend((red, green, blue))
        index += run

    return bytes(encoded)


def rasterize_sheet(path):
    """Rasterize an SVG at its declared pixel dimensions."""
    svg = path.read_text(encoding="utf-8")
    match = re.search(r'<svg\b[^>]*\bwidth="(\d+)"[^>]*\bheight="(\d+)"', svg)
    if not match:
        raise SystemExit(f"Cannot read integer SVG dimensions: {path}")
    width, height = map(int, match.groups())
    png = cairosvg.svg2png(
        url=str(path), output_width=width, output_height=height
    )
    image = Image.open(io.BytesIO(png)).convert("RGBA")
    if image.size != (width, height):
        raise SystemExit(f"Unexpected raster size in {path}: {image.size}")
    if width % CELL_W or height % CELL_H:
        raise SystemExit(f"Sheet dimensions are not multiples of 64x80: {path}")
    return image


def cells(path):
    sheet = rasterize_sheet(path)
    result = []
    for top in range(0, sheet.height, CELL_H):
        for left in range(0, sheet.width, CELL_W):
            result.append(sheet.crop((left, top, left + CELL_W, top + CELL_H)))
    return result


def make_frame(sprite_index):
    element = (
        u32(sprite_index)
        + i16(SPRITE_X)
        + i16(SPRITE_Y)
        + bytes((0, 0))
        + u16(0)
    )
    return b"FR" + u16(0) + u16(1) + element


def make_animation(name, frame_indices, directions=("all",)):
    """Create one CA block with the cycle assigned to selected directions."""
    if not frame_indices:
        raise ValueError(f"Animation {name} has no frames")
    first = frame_indices[0]
    if directions == ("north",):
        starts = (first, MISSING, MISSING, MISSING)
    elif directions == ("east",):
        starts = (MISSING, first, MISSING, MISSING)
    elif directions == ("north-east",):
        starts = (first, first, MISSING, MISSING)
    else:
        starts = (first, first, first, first)
    encoded_name = name.encode("ascii")
    if len(encoded_name) > 255:
        raise ValueError(f"Animation name is too long: {name}")
    return (
        b"CA" + u16(TILE_SIZE) + u32(len(frame_indices))
        + bytes((len(encoded_name),)) + encoded_name
        + b"".join(u32(value) for value in starts)
    )


def build():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    source_specs = [
        ("idle-front", "idle.svg", 1),
        ("idle-back", "idle-back.svg", 1),
        ("idle-east", "idle-east.svg", 1),
        ("walk", "walk.svg", 12),
        ("walk-back", "walk-back.svg", 6),
        ("sweep", "sweep.svg", 6),
    ("repair-cardio", "repair-cardio.svg", 6),
    ("repair-cardio-finish", "repair-cardio-finish.svg", 4),
        ("door", "door.svg", 8),
        ("swing-door", "swing-door.svg", 8),
    ]

    sprite_images = []
    source_ranges = {}

    for name, filename, expected_count in source_specs:
        frames = cells(SOURCE_DIR / filename)
        if len(frames) != expected_count:
            raise SystemExit(
                f"{filename}: expected {expected_count} cells, got {len(frames)}"
            )
        start = len(sprite_images)
        sprite_images.extend(frames)
        source_ranges[name] = list(range(start, start + len(frames)))

    # Create one contact sheet to inspect all source frames after rasterization.
    columns = 7
    rows = (len(sprite_images) + columns - 1) // columns
    preview = Image.new("RGBA", (CELL_W * columns, CELL_H * rows), (0, 0, 0, 0))
    for index, frame in enumerate(sprite_images):
        x = (index % columns) * CELL_W
        y = (index // columns) * CELL_H
        preview.alpha_composite(frame, (x, y))
    preview.save(OUTPUT_DIR / "handyman-all-frames.png")

    animations = []
    animations.append((
        "gpt_handyman_idle_north", source_ranges["idle-back"], ("north",)
    ))
    animations.append((
        "gpt_handyman_idle_east", source_ranges["idle-east"], ("east",)
    ))

    walk = source_ranges["walk"]
    walk_back = source_ranges["walk-back"]
    animations.append(("gpt_handyman_walk_north", walk_back, ("north",)))
    animations.append(("gpt_handyman_walk_east", walk[6:12], ("east",)))

    animations.append((
        "gpt_handyman_sweep", source_ranges["sweep"], ("north-east",)
    ))
    animations.append((
        "gpt_handyman_repair_cardio", source_ranges["repair-cardio"], ("all",)
    ))
    animations.append((
        "gpt_handyman_repair_cardio_finish", source_ranges["repair-cardio-finish"], ("all",)
    ))

    door = source_ranges["door"]
    animations.append(("gpt_handyman_door_enter", door[:4], ("all",)))
    animations.append(("gpt_handyman_door_leave", door[4:], ("all",)))

    swing = source_ranges["swing-door"]
    animations.append(("gpt_handyman_swing_enter", swing[:4], ("all",)))
    animations.append(("gpt_handyman_swing_leave", swing[4:], ("all",)))

    sprite_blocks = []
    sprite_data_total = 0
    for image in sprite_images:
        data = encode_rgba_sprite(image)
        sprite_data_total += len(data)
        sprite_blocks.append(
            b"SP" + u16(CELL_W) + u16(CELL_H) + u32(len(data)) + data
        )

    frame_blocks = [make_frame(index) for index in range(len(sprite_images))]
    animation_blocks = [
        make_animation(name, indices, dirs)
        for name, indices, dirs in animations
    ]

    header = (
        b"CTHG" + bytes((1, 2))
        + u32(len(animation_blocks))
        + u32(len(frame_blocks))
        + u32(len(frame_blocks))
        + u32(len(sprite_blocks))
        + u32(sprite_data_total)
    )
    OUTPUT.write_bytes(
        header + b"".join(sprite_blocks)
        + b"".join(frame_blocks) + b"".join(animation_blocks)
    )

    print(f"Wrote {OUTPUT} ({OUTPUT.stat().st_size} bytes)")
    print(f"Sprites/frames: {len(sprite_blocks)}")
    print(f"Animations: {len(animation_blocks)}")
    print(f"Preview: {OUTPUT_DIR / 'handyman-all-frames.png'}")
    for name, indices, _ in animations:
        print(f"  {name}: {len(indices)} frames, first={indices[0]}")


if __name__ == "__main__":
    build()
