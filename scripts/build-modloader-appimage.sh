#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 ORIGINAL.AppImage [OUTPUT.AppImage]" >&2
  exit 2
}

[[ $# -ge 1 && $# -le 2 ]] || usage
SOURCE="$(realpath "$1")"
[[ -f "$SOURCE" ]] || { echo "AppImage not found: $SOURCE" >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PATCH_DIR="$REPO_ROOT/patches/corsixth-0.70.2"

if [[ $# -eq 2 ]]; then
  OUTPUT="$(realpath -m "$2")"
else
  OUTPUT="${SOURCE%.AppImage}-ModLoader.AppImage"
fi

[[ "$OUTPUT" != "$SOURCE" ]] || {
  echo "Refusing to overwrite the original AppImage." >&2
  exit 1
}
[[ ! -e "$OUTPUT" ]] || {
  echo "Output already exists; move it away first: $OUTPUT" >&2
  exit 1
}

for tool in unsquashfs mksquashfs patch python3; do
  command -v "$tool" >/dev/null || {
    echo "Required tool not found: $tool" >&2
    exit 1
  }
done

OFFSET="$("$SOURCE" --appimage-offset 2>/dev/null | tail -n 1 | tr -cd '0-9')"
[[ "$OFFSET" =~ ^[0-9]+$ ]] || {
  echo "Could not obtain the SquashFS offset from the AppImage runtime." >&2
  exit 1
}

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
APPDIR="$WORK/AppDir"

echo "Extracting original AppImage (SquashFS offset: $OFFSET)..."
unsquashfs -no-progress -d "$APPDIR" "$SOURCE" >/dev/null

APP_LUA="$APPDIR/usr/share/corsix-th/Lua"
[[ -f "$APP_LUA/app.lua" && -f "$APP_LUA/config_finder.lua" && -f "$APP_LUA/entities/humanoid.lua" ]] || {
  echo "Unexpected AppDir layout; expected CorsixTH Lua sources were not found." >&2
  exit 1
}

grep -Fq 'local SAVEGAME_VERSION = 255 -- 0.70.2' "$APP_LUA/app.lua" || {
  echo "This is not the expected CorsixTH 0.70.2 source. No files were changed." >&2
  exit 1
}

echo "Checking version-specific patches..."
for patch_file in config_finder.lua.patch app.lua.patch humanoid.lua.patch; do
  patch --dry-run --silent -d "$APPDIR/usr/share/corsix-th" -p1 < "$PATCH_DIR/$patch_file"
done

for patch_file in config_finder.lua.patch app.lua.patch humanoid.lua.patch; do
  patch --batch --forward --silent -d "$APPDIR/usr/share/corsix-th" -p1 < "$PATCH_DIR/$patch_file"
done

install -m 0644 "$PATCH_DIR/mod_hooks.lua" "$APP_LUA/mod_hooks.lua"
install -m 0644 "$PATCH_DIR/mod_loader.lua" "$APP_LUA/mod_loader.lua"

echo "Building new SquashFS payload..."
mksquashfs "$APPDIR" "$WORK/payload.squashfs" -noappend -comp xz -all-root -no-progress >/dev/null

echo "Reusing the original AppImage runtime..."
head -c "$OFFSET" "$SOURCE" > "$OUTPUT"
cat "$WORK/payload.squashfs" >> "$OUTPUT"
chmod 0755 "$OUTPUT"

NEW_OFFSET="$("$OUTPUT" --appimage-offset 2>/dev/null | tail -n 1 | tr -cd '0-9')"
[[ "$NEW_OFFSET" == "$OFFSET" ]] || {
  rm -f "$OUTPUT"
  echo "Repacked AppImage runtime did not report the expected offset." >&2
  exit 1
}

echo "Created: $OUTPUT"
echo "Original left untouched: $SOURCE"
