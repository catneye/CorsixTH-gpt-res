# Handyman sprite source set

All cells are original SVG vector artwork based on the Handyman character design.

## Files

- `idle.svg` — single-frame front-facing idle pose (64 × 80; retained as source artwork).
- `idle-back.svg` — simplified single-frame back-facing idle pose (64 × 80).
- `idle-east.svg` — separate single-frame east-facing idle pose (64 × 80).
- `walk.svg` — 2 rows × 6 frames: front-facing row first, east-facing row second.
- `walk-back.svg` — 1 row × 6 frames: simplified back-facing walk cycle.
- `sweep.svg` — 1 row × 6 frames: sweeping cycle.
- `door.svg` — 1 row × 8 frames: four entering frames followed by four leaving frames.
- `swing-door.svg` — 1 row × 8 frames: four entering frames followed by four leaving frames.

Every frame cell is 64 × 80. The SVG sheets are source artwork; `resources/build-handyman-animations.py` converts them into the CorsixTH CTHG resource at `resources/custom-graphics/build/handyman.cthg`.

The north-facing idle and walk animations use the simplified back-view artwork. East-facing animations use the existing profile artwork. The front-facing idle and walk artwork is retained in the source sheets for later visual refinement.
