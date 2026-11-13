# CorsixTH GPT resources

This repository contains **our original replacement resources, tooling and documentation** for CorsixTH 0.70.2.

## Important distinction

CorsixTH is an engine reimplementation; it does not include the original Theme Hospital game data. To start a playable hospital, the engine needs either:

- the original Theme Hospital data from a copy you own; or
- the official free Theme Hospital demo data.

Do not commit original game assets or demo archives to this repository. They are downloaded/extracted locally and are excluded by `.gitignore`.

## Get the free demo data (Linux)

Requirements: `curl` and `unzip`.

```bash
sudo apt install curl unzip
./scripts/fetch-demo.sh
```

By default, the script extracts the data into:

```
local-data/theme-hospital-demo/
```

It searches for the directory containing `DATA/` and `LEVELS/`, then copies its contents into that destination. In CorsixTH, select **that directory itself** when asked for the Theme Hospital data location.

You can choose another destination:

```bash
./scripts/fetch-demo.sh /absolute/path/to/theme-hospital-demo
```

The demo is limited to one level and lacks most management screens. It is sufficient for an initial test of the game and our resource-loading changes.

## Planned repository layout

- `scripts/` — repeatable local setup and validation tools.
- `docs/` — notes on CorsixTH's resource formats and loading pipeline.
- `resources/custom-graphics/` — our original graphics and animation source assets.
- `patches/` — optional Lua patches used for controlled experiments.

The custom graphics directory will contain only assets created by us. We will not copy Theme Hospital sprites into it.

## Current target

- CorsixTH: 0.70.2
- First milestone: launch the demo, then load one minimal custom animation resource.
- Main character target: a completely original Handyman design. Gameplay logic and task priorities remain unchanged.
