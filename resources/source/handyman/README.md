# Handyman sprite source set

All cells are original SVG vector artwork based on `resources/source/handyman/idle.svg`.

## Files

- `walk.svg` — 2 rows × 6 frames: north-facing row first, east-facing row second.
- `sweep.svg` — 1 row × 6 frames: sweeping cycle.
- `door.svg` — 1 row × 8 frames: four entering frames followed by four leaving frames.
- `swing-door.svg` — 1 row × 8 frames: four entering frames followed by four leaving frames.
- `idle.svg` — original single-frame idle reference (64 × 80).

Every frame cell is 64 × 80. The SVG sheets are source artwork, not yet converted into CorsixTH CTHG/animation resources. The frame ordering and timing must be wired into the resource build once the target animation import pipeline is finalized.

The game can mirror north/east directional animations for the opposite directions where appropriate.
