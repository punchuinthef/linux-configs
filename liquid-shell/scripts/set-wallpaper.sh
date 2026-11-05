

#!/usr/bin/env bash
set -euo pipefail

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
CONFIG="$HOME/.config/hypr/hyprpaper.conf"
MONITOR="DP-4"

if [[ $# -ne 1 ]]; then
    printf 'Usage: %s <wallpaper-path>\n' "$0" >&2
    exit 1
fi

wallpaper="$1"

if [[ ! -f "$wallpaper" ]]; then
    printf 'Wallpaper does not exist: %s\n' "$wallpaper" >&2
    exit 1
fi

wallpaper_dir="$(realpath -- "$WALLPAPER_DIR")"
wallpaper="$(realpath -- "$wallpaper")"

case "$wallpaper" in
    "$wallpaper_dir"/*) ;;
    *)
        printf 'Wallpaper is outside the wallpaper directory.\n' >&2
        exit 1
        ;;
esac

case "${wallpaper,,}" in
    *.jpg|*.jpeg|*.png|*.webp) ;;
    *)
        printf 'Unsupported wallpaper format.\n' >&2
        exit 1
        ;;
esac

if [[ ! -f "$CONFIG" ]]; then
    printf 'Hyprpaper configuration not found.\n' >&2
    exit 1
fi

# Update only the DP-4 wallpaper block.
# Preserve all other settings and monitor definitions.
python3 - "$CONFIG" "$MONITOR" "$wallpaper" <<'PY'
import os
import re
import sys
import tempfile

config, monitor, wallpaper = sys.argv[1:]

with open(config, "r", encoding="utf-8") as file:
    original = file.read()

block_pattern = re.compile(
    r"(?m)^wallpaper\s*\{[^{}]*^\}",
    re.MULTILINE
)

monitor_pattern = re.compile(
    r"(?m)^\s*monitor\s*=\s*" + re.escape(monitor) + r"\s*$"
)

path_pattern = re.compile(
    r"(?m)^(\s*path\s*=\s*).*$"
)

matches = [
    match for match in block_pattern.finditer(original)
    if monitor_pattern.search(match.group())
]

if len(matches) != 1:
    sys.exit(
        f"Expected exactly one wallpaper block for {monitor}; "
        f"found {len(matches)}. Configuration unchanged."
    )

match = matches[0]
block = match.group()

if len(path_pattern.findall(block)) != 1:
    sys.exit("Expected exactly one path entry. Configuration unchanged.")

updated_block = path_pattern.sub(
    lambda m: m.group(1) + wallpaper,
    block,
    count=1
)

updated = (
    original[:match.start()]
    + updated_block
    + original[match.end():]
)

directory = os.path.dirname(config)
fd, temporary = tempfile.mkstemp(
    prefix=".hyprpaper-",
    dir=directory,
    text=True
)

try:
    os.fchmod(fd, os.stat(config).st_mode & 0o777)

    with os.fdopen(fd, "w", encoding="utf-8") as file:
        file.write(updated)

    os.replace(temporary, config)
except BaseException:
    if os.path.exists(temporary):
        os.unlink(temporary)
    raise
PY

# Apply the wallpaper immediately.
hyprctl hyprpaper wallpaper "$MONITOR,$wallpaper"

printf 'Wallpaper applied and saved for %s.\n' "$MONITOR"


# Apply the selected wallpaper's saved Liquid Shell theme.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if command -v python3 >/dev/null 2>&1; then
    if python3 "$SCRIPT_DIR/theme-manager.py" "$wallpaper" --apply; then
        printf 'Liquid Shell theme applied successfully.\n'
    else
        printf 'Warning: Liquid Shell theme could not be applied.\n' >&2
    fi
else
    printf 'Warning: Python 3 is not installed.\n' >&2
fi

