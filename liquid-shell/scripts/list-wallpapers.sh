
#!/usr/bin/env bash

set -euo pipefail

# Directory containing our wallpapers
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"

# Make sure the directory exists
if [[ ! -d "$WALLPAPER_DIR" ]]; then
    printf 'Error: Wallpaper directory not found: %s\n' "$WALLPAPER_DIR" >&2
    exit 1
fi

# Recursively discover supported image files
find "$WALLPAPER_DIR" \
    -type f \
    \( -iname '*.jpg' \
    -o -iname '*.jpeg' \
    -o -iname '*.png' \
    -o -iname '*.webp' \) \
    -print0 |
    sort -z |
    while IFS= read -r -d '' wallpaper; do
        printf '%s\n' "$wallpaper"
    done

