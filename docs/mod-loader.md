# External Lua mods

Target: CorsixTH 0.70.2 (Linux AppImage, type 2).

## Design

The patched AppImage contains only the generic loader and extension points.
Actual mod packages stay outside the AppImage, under the user's CorsixTH
configuration directory:

```text
~/.config/CorsixTH/
└── mods/
    ├── enabled.txt
    └── hello/
        ├── mod.lua
        └── init.lua
```

On Linux, the configuration directory follows CorsixTH's existing rules:
`XDG_CONFIG_HOME/CorsixTH`, or `~/.config/CorsixTH` when the environment
variable is unset. The `config.path.txt` override is respected because the
loader uses the path exported by `config_finder.lua`.

Put one enabled package ID per line in `mods/enabled.txt`. Blank lines and
lines beginning with `#` are ignored. Package IDs may contain letters,
digits, underscores and hyphens.

A package has a `mod.lua` manifest returning a table with `id`, optional
`name`, optional `version`, and optional `entry` (default: `init.lua`).
The entry file must return an initializer function receiving the mod API.

## Hook API

```lua
return function(api)
  api.hooks.register("humanoid.animations", function(animations)
    -- Modify the supplied animation table if needed.
  end, 0) -- optional priority; higher values run first
end
```

Handlers run in descending priority order; equal priorities preserve
registration order. A failing handler is logged and does not prevent later
handlers from running. A mod initialization failure does not prevent other
enabled mods from loading. `api.hooks.unregister(token)` removes a handler.

Mods execute as Lua code inside the game process. They are trusted code, not
sandboxed plugins. Only enable packages whose source you trust.

## Build the patched AppImage

Requirements: `bash`, `python3`, `patch`, `unsquashfs`, `mksquashfs`.

From the repository root:

```bash
bash scripts/build-modloader-appimage.sh \
  ~/game/CorsixTH/CorsixTH-v0.70.2-x86_64.AppImage
```

The script never overwrites the source AppImage. By default it creates a
separate `*-ModLoader.AppImage` next to the source. It verifies the embedded
CorsixTH version and refuses to apply patches if expected source context
does not match.

## Install the test package

```bash
bash scripts/install-test-mod.sh
```

This copies the example package to the default Linux config directory and
adds `hello` to `enabled.txt` without deleting other enabled package IDs.
For a non-default `config.path.txt` location, copy `examples/mods/hello`
manually into that configuration directory's `mods/` folder and add
`hello` to `enabled.txt`.

Launch the patched AppImage from a terminal. The log should contain messages
from the test package and its `humanoid.animations` hook.
