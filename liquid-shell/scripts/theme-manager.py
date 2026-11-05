#!/usr/bin/env python3

import os
import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image
import shutil
import subprocess
import tempfile
import re

CACHE_DIR = Path.home() / ".cache" / "liquid-shell" / "palettes"
CONFIG_DIR = Path.home() / ".config" / "liquid-shell"
PREFERENCES_FILE = CONFIG_DIR / "wallpaper-themes.json"
PROJECT_DIR = Path(__file__).resolve().parent.parent
ACTIVE_PALETTE = PROJECT_DIR / "theme" / "MatugenColors.qml"

MATUGEN_TEMPLATE = (
    Path.home() / ".config/matugen/templates/liquid-shell.qml"
)

REQUIRED_COLORS = (
    "primary",
    "surface",
    "surfaceContainer",
    "surfaceText",
    "surfaceTextVariant",
    "outline",
)

VALID_MODES = {"auto", "light", "dark"}


def wallpaper_hash(path: Path) -> str:
    """Generate a SHA-256 hash for a wallpaper."""
    digest = hashlib.sha256()

    with path.open("rb") as file:
        for chunk in iter(lambda: file.read(1024 * 1024), b""):
            digest.update(chunk)

    return digest.hexdigest()

def detect_theme(wallpaper: Path) -> str:
    """Determine a suitable theme from wallpaper brightness."""

    with Image.open(wallpaper) as image:
        # Convert to RGB and shrink for faster analysis.
        image = image.convert("RGB")
        image.thumbnail((100, 100))

        # Calculate average perceived brightness.
        pixels = list(image.get_flattened_data())
        total_brightness = sum(
            0.2126 * r + 0.7152 * g + 0.0722 * b
            for r, g, b in pixels
        )

        average_brightness = total_brightness / len(pixels)

    return "light" if average_brightness >= 128 else "dark"

def load_preferences() -> dict:
    """Load saved wallpaper theme preferences."""
    if not PREFERENCES_FILE.exists():
        return {}

    with PREFERENCES_FILE.open("r", encoding="utf-8") as file:
        return json.load(file)


def save_preferences(preferences: dict) -> None:
    """Save wallpaper theme preferences."""
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)

    with PREFERENCES_FILE.open("w", encoding="utf-8") as file:
        json.dump(preferences, file, indent=4)


def get_mode(wallpaper: Path) -> str:
    """Retrieve the preferred theme mode for a wallpaper."""
    key = wallpaper_hash(wallpaper)
    preferences = load_preferences()

    return preferences.get(key, "auto")

def resolve_mode(wallpaper: Path) -> str:
    """Resolve auto mode while respecting manual overrides."""

    mode = get_mode(wallpaper)

    if mode == "auto":
        return detect_theme(wallpaper)

    return mode


def palette_path(wallpaper: Path, mode: str) -> Path:
    """Return the cache location for a wallpaper and theme mode."""
    return CACHE_DIR / f"{wallpaper_hash(wallpaper)}-{mode}.qml"


def validate_palette(path: Path) -> None:
    """Verify that Matugen generated a usable QML palette."""

    if not path.is_file():
        raise RuntimeError("Matugen did not generate a palette.")

    content = path.read_text(encoding="utf-8")

    if "pragma Singleton" not in content:
        raise RuntimeError("Generated palette is missing its singleton declaration.")

    for color in REQUIRED_COLORS:
        pattern = (
            r'\breadonly\s+property\s+color\s+'
            + re.escape(color)
            + r'\s*:\s*"#[0-9a-fA-F]{6}(?:[0-9a-fA-F]{2})?"'
        )

        if not re.search(pattern, content):
            raise RuntimeError(
                f"Generated palette contains an invalid or missing color: {color}"
            )



def generate_palette(wallpaper: Path, mode: str) -> Path:
    """Generate a Matugen palette without modifying the active theme."""

    if shutil.which("matugen") is None:
        raise RuntimeError("Matugen is not installed.")

    if not MATUGEN_TEMPLATE.is_file():
        raise RuntimeError(
            f"Matugen template not found: {MATUGEN_TEMPLATE}"
        )

    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    cached = palette_path(wallpaper, mode)

    if cached.exists():
        validate_palette(cached)
        print("Using cached palette.")
        return cached

    print(f"Generating {mode} palette with Matugen...")

    with tempfile.TemporaryDirectory(prefix="liquid-shell-") as directory:
        temporary_dir = Path(directory)
        generated = temporary_dir / "MatugenColors.qml"
        config = temporary_dir / "config.toml"

        # Generate into a temporary directory, not the active QML file.
        config.write_text(
            '[config]\n'
            'reload_apps = false\n\n'
            '[templates.liquid_shell]\n'
            f'input_path = "{MATUGEN_TEMPLATE}"\n'
            f'output_path = "{generated}"\n',
            encoding="utf-8",
        )

        subprocess.run(
            [
                "matugen",
                "--config",
                str(config),
                "image",
                str(wallpaper),
                "--mode",
                mode,
                "--source-color-index",
                "0",
            ],
            check=True,
        )

        validate_palette(generated)

        # Cache only successfully generated and validated palettes.
        shutil.copy2(generated, cached)

    print("Palette generated and cached successfully.")
    return cached


def atomic_apply(source: Path, destination: Path) -> None:
    """Atomically replace the active palette with a cached palette."""

    # Avoid unnecessary writes if the palette is already active.
    if destination.exists() and source.read_bytes() == destination.read_bytes():
        print("Palette is already active.")
        return

    temporary_path = None

    try:
        # Create a temporary file beside the destination.
        with tempfile.NamedTemporaryFile(
            mode="wb",
            dir=destination.parent,
            prefix=".matugen-",
            suffix=".qml",
            delete=False,
        ) as temporary:
            temporary_path = Path(temporary.name)

            with source.open("rb") as palette:
                shutil.copyfileobj(palette, temporary)

            # Flush the completed palette to disk.
            temporary.flush()
            os.fsync(temporary.fileno())

        # Replace the active palette in one atomic operation.
        os.replace(temporary_path, destination)
        os.utime(destination, None)
    finally:
        # Clean up if anything failed before replacement.
        if temporary_path is not None:
            temporary_path.unlink(missing_ok=True)



def apply_palette(wallpaper: Path) -> None:
    """Apply the appropriate palette for a wallpaper."""

    mode = resolve_mode(wallpaper)
    cached = generate_palette(wallpaper, mode)

    validate_palette(cached)
    atomic_apply(cached, ACTIVE_PALETTE)

    print(f"Applied {mode} palette.")


def set_mode(wallpaper: Path, mode: str) -> None:
    """Save a theme mode for a specific wallpaper."""
    if mode not in VALID_MODES:
        raise ValueError(f"Invalid mode: {mode}")

    key = wallpaper_hash(wallpaper)
    preferences = load_preferences()

    preferences[key] = mode
    save_preferences(preferences)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Liquid Shell wallpaper theme manager"
    )

    parser.add_argument(
        "wallpaper",
        type=Path,
        help="Path to the wallpaper image"
    )

    parser.add_argument(
        "--mode",
        choices=sorted(VALID_MODES),
        help="Set the wallpaper's preferred theme mode"
    )

    parser.add_argument(
    "--apply",
    action="store_true",
    help="Generate or restore the wallpaper's Matugen palette"
)
    args = parser.parse_args()

    wallpaper = args.wallpaper.expanduser().resolve()

    if not wallpaper.is_file():
        parser.error(f"Wallpaper not found: {wallpaper}")

    CACHE_DIR.mkdir(parents=True, exist_ok=True)

    if args.mode:
        set_mode(wallpaper, args.mode)
        print(f"Saved theme mode: {args.mode}")

    print(f"Wallpaper: {wallpaper.name}")
    print(f"SHA-256: {wallpaper_hash(wallpaper)}")
    print(f"Theme preference: {get_mode(wallpaper)}")
    print(f"Resolved theme: {resolve_mode(wallpaper)}")
    if args.apply:
        apply_palette(wallpaper)

if __name__ == "__main__":
    main()

