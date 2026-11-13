# Custom graphics workspace

Original artwork and generated CorsixTH resources for the Handyman replacement.

- `source/handyman/idle.svg` — editable source drawing for the first idle pose.
- `build/handyman-idle.png` — raster preview produced by the build script.
- `build/handyman-idle.cthg` — CTHG resource loaded by CorsixTH.

Install the build dependencies from the repository root:

```bash
python3 -m pip install -r requirements.txt
python3 scripts/build-animation-probe.py
```

The current resource contains one static frame named `gpt_handyman_idle`.
It is a format and artwork integration step; the Handyman's Lua animation
selection still needs to be redirected to this named animation before the
sprite will appear on the in-game character.

Do not commit extracted Theme Hospital graphics or game data here.
