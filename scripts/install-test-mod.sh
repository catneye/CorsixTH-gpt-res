#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_ROOT="${XDG_CONFIG_HOME:-$HOME/.config}/CorsixTH"
MODS_DIR="$CONFIG_ROOT/mods"
ENABLED_FILE="$MODS_DIR/enabled.txt"

mkdir -p "$MODS_DIR"
rm -rf "$MODS_DIR/hello"
cp -a "$REPO_ROOT/examples/mods/hello" "$MODS_DIR/hello"
touch "$ENABLED_FILE"

if ! grep -Fxq 'hello' "$ENABLED_FILE"; then
  printf '\nhello\n' >> "$ENABLED_FILE"
fi

printf 'Installed test mod into %s\n' "$MODS_DIR/hello"
printf 'Enabled package list: %s\n' "$ENABLED_FILE"
