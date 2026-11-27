# Handyman sprite source set

All cells are original SVG vector artwork based on the Handyman character design.

## Files

- `idle.svg` — single-frame north-facing idle pose (64 × 80).
- `idle-east.svg` — separate single-frame east-facing idle pose (64 × 80).
- `walk.svg` — 2 rows × 6 frames: north-facing row first, east-facing row second.
- `sweep.svg` — 1 row × 6 frames: sweeping cycle.
- `door.svg` — 1 row × 8 frames: four entering frames followed by four leaving frames.
- `swing-door.svg` — 1 row × 8 frames: four entering frames followed by four leaving frames.

Every frame cell is 64 × 80. The SVG sheets are source artwork; `resources/build-handyman-animations.py` converts them into the CorsixTH CTHG resource at `resources/custom-graphics/build/handyman.cthg`.

The idle poses are separate directional drawings rather than reusing the same frontal frame for both directions. The game can mirror north/east directional animations for the opposite directions where appropriate.
