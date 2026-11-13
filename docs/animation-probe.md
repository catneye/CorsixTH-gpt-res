# CTHG animation probe

This is a format/loading smoke test for CorsixTH 0.70.2. It creates a tiny
magenta square as a named animation called `gpt_handyman_probe`. It is not
character artwork.

## Build

From the repository root:

```sh
python3 scripts/build-animation-probe.py
```

The generated file is written to
`resources/custom-graphics/build/handyman-probe.cthg`.

## Loading path confirmed in v0.70.2

1. `Graphics:Graphics()` reads `file_mapping.txt` only when
   `use_new_graphics = true`.
2. `Graphics:loadAnimations()` loads each mapped file using
   `anims:loadCustom(data)`.
3. The animation manager exposes
   `TheApp.anims:getAnimations(32, "gpt_handyman_probe")`.

The custom-animation loader expects the CTHG animation header bytes
`CTHG 01 02`, five little-endian 32-bit counters, then typed blocks.
The probe writes one `SP` sprite block, one `FR` frame block, and one
`CA` named-animation block. The order matters: sprites are needed while
frame bounds are calculated, and frames must exist before the named animation
indices are resolved.

## Important

Do not enable the custom graphics setting until the probe file has been built.
The next step after a successful load is to verify that the named animation is
returned and then temporarily bind it to the Handyman. No AI or task logic
should be changed.
