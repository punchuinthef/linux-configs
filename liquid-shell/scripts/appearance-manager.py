#!/usr/bin/env python3

import argparse
import importlib.util
import re
from pathlib import Path


# Configuration
HYPRPAPER_CONFIG = Path.home() / ".config/hypr/hyprpaper.conf"
THEME_MANAGER = Path(__file__).resolve().parent / "theme-manager.py"

DEFAULT_MONITOR = "DP-4"
VALID_MODES = ("light", "dark", "auto")


def get_wallpaper(monitor: str) -> Path:
    """Find the wallpaper configured for a specific monitor."""

    if not HYPRPAPER_CONFIG.is_file():
        raise RuntimeError("Hyprpaper configuration not found.")

    config = HYPRPAPER_CONFIG.read_text(encoding="utf-8")

    # Ignore commented-out lines, including disabled monitor blocks.
    active_lines = [
        line for line in config.splitlines()
        if not line.lstrip().startswith("#")
    ]

    config = "\n".join(active_lines)

    # Locate active wallpaper blocks.
    blocks = re.findall(
        r"(?m)^wallpaper\s*\{([^{}]*)^\}",
        config,
    )

    matches = []

    for block in blocks:
        monitor_match = re.search(
            r"(?m)^\s*monitor\s*=\s*(.*?)\s*$",
            block,
        )

        path_match = re.search(
            r"(?m)^\s*path\s*=\s*(.*?)\s*$",
            block,
        )

        if not monitor_match or not path_match:
            continue

        if monitor_match.group(1) == monitor:
            matches.append(path_match.group(1))

    if len(matches) != 1:
        raise RuntimeError(
            f"Expected one wallpaper for {monitor}, "
            f"found {len(matches)}."
        )

    wallpaper = Path(matches[0]).expanduser().resolve()

    if not wallpaper.is_file():
        raise RuntimeError(f"Wallpaper not found: {wallpaper}")

    return wallpaper


def load_theme_manager():
    """Import the existing theme manager without duplicating its logic."""

    spec = importlib.util.spec_from_file_location(
        "liquid_theme_manager",
        THEME_MANAGER,
    )

    if spec is None or spec.loader is None:
        raise RuntimeError("Could not load theme-manager.py")

    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)

    return module


def main():
    parser = argparse.ArgumentParser(
        description="Liquid Shell appearance controls"
    )

    parser.add_argument(
        "--monitor",
        default=DEFAULT_MONITOR,
        help="Monitor to inspect (default: DP-4)",
    )

    parser.add_argument(
        "--mode",
        choices=VALID_MODES,
        help="Set the wallpaper's preferred appearance mode",
    )

    args = parser.parse_args()

    wallpaper = get_wallpaper(args.monitor)
    theme_manager = load_theme_manager()

    if args.mode:
        theme_manager.set_mode(wallpaper, args.mode)
        theme_manager.apply_palette(wallpaper)

    print(f"Monitor: {args.monitor}")
    print(f"Wallpaper: {wallpaper.name}")
    print(f"Preference: {theme_manager.get_mode(wallpaper)}")
    print(f"Resolved: {theme_manager.resolve_mode(wallpaper)}")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        raise SystemExit(f"Appearance manager error: {error}")

