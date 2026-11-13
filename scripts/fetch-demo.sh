#!/usr/bin/env bash
set -euo pipefail

# Download the official free Theme Hospital demo and unpack it locally.
# The game data is intentionally excluded from Git.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="${1:-"$ROOT/local-data/theme-hospital-demo"}"
URL="https://th.corsix.org/Demo.zip"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

command -v curl >/dev/null || { echo "curl is required" >&2; exit 1; }
command -v unzip >/dev/null || { echo "unzip is required" >&2; exit 1; }

mkdir -p "$DEST"
echo "Downloading Theme Hospital demo..."
curl -fL --retry 3 "$URL" -o "$TMP/Demo.zip"

echo "Extracting demo..."
unzip -q "$TMP/Demo.zip" -d "$TMP/extracted"

# CorsixTH expects the directory containing DATA, QDATA, LEVELS, etc.
DATA_ROOT=""
while IFS= read -r -d '' candidate; do
  if [[ -d "$candidate/DATA" && -d "$candidate/LEVELS" ]]; then
    DATA_ROOT="$candidate"
    break
  fi
done < <(find "$TMP/extracted" -type d -print0)

if [[ -z "$DATA_ROOT" ]]; then
  echo "Could not find a directory containing DATA/ and LEVELS/ in the archive." >&2
  echo "Archive contents are in $TMP/extracted (temporary; inspect the script if needed)." >&2
  exit 1
fi

# Keep a clean target; never overwrite an existing data directory silently.
if [[ -n "$(find "$DEST" -mindepth 1 -maxdepth 1 -print -quit)" ]]; then
  echo "Destination is not empty: $DEST" >&2
  echo "Choose another destination or move the existing files first." >&2
  exit 1
fi

cp -a "$DATA_ROOT"/. "$DEST"/
echo
echo "Demo data installed locally at:"
echo "  $DEST"
echo
echo "In CorsixTH, select this directory when asked for the Theme Hospital data."
