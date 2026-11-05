#!/usr/bin/env python3
"""Update Liquid Shell's local emoji database from Unicode's emoji-test.txt.

Only emojis.json in the XDG data directory is replaced. User customizations
are never read, written, or deleted.
"""

import argparse
import json
import os
from pathlib import Path
import re
import sys
import tempfile
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

SOURCE = "https://www.unicode.org/Public/emoji/latest/emoji-test.txt"
VERSION_RE = re.compile(r"^#\s*Version:\s*([\w.\-]+)", re.MULTILINE)
ENTRY_RE = re.compile(
    r"^([0-9A-F ]+)\s*;\s*fully-qualified\s*#\s*\S+\s+E[0-9.]+\s+(.+)$"
)


def data_directory() -> Path:
    base = os.environ.get("XDG_DATA_HOME")
    if base:
        root = Path(base).expanduser()
        if not root.is_absolute():
            raise ValueError("XDG_DATA_HOME must be an absolute path")
    else:
        root = Path.home() / ".local" / "share"
    return root / "liquid-shell" / "emoji"


def download() -> str:
    request = Request(SOURCE, headers={"User-Agent": "LiquidShellEmojiUpdater/1.0"})
    with urlopen(request, timeout=30) as response:
        content = response.read(5_000_001)
    if len(content) > 5_000_000:
        raise ValueError("Unicode response exceeded 5 MB; refusing to import")
    return content.decode("utf-8-sig")


def parse(text: str) -> dict:
    match = VERSION_RE.search(text)
    if not match:
        raise ValueError("Missing Unicode version header")

    group = None
    subgroup = None
    entries = []
    seen = set()
    for line in text.splitlines():
        if line.startswith("# group: "):
            group = line.removeprefix("# group: ").strip()
        elif line.startswith("# subgroup: "):
            subgroup = line.removeprefix("# subgroup: ").strip()
        else:
            found = ENTRY_RE.match(line)
            if not found:
                continue
            if not group or not subgroup:
                raise ValueError("Emoji entry appeared before its group/subgroup")
            codepoints = found.group(1).split()
            emoji = "".join(chr(int(cp, 16)) for cp in codepoints)
            if emoji in seen:
                raise ValueError(f"Duplicate emoji entry: {emoji!r}")
            seen.add(emoji)
            entries.append({
                "emoji": emoji,
                "name": found.group(2).strip(),
                "group": group,
                "subgroup": subgroup,
                "codepoints": [f"U+{cp}" for cp in codepoints],
            })

    # A tiny or malformed download must never replace an existing database.
    if len(entries) < 1000 or len(entries) > 10000:
        raise ValueError(f"Unexpected number of emojis: {len(entries)}")
    return {"unicode_version": match.group(1), "source": SOURCE, "emojis": entries}


def atomic_write(destination: Path, payload: dict) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    # Same-directory temp file makes os.replace atomic on a local filesystem.
    fd, temp_name = tempfile.mkstemp(prefix=".emojis-", suffix=".tmp", dir=destination.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as output:
            json.dump(payload, output, ensure_ascii=False, indent=2)
            output.write("\n")
            output.flush()
            os.fsync(output.fileno())
        os.chmod(temp_name, 0o644)
        os.replace(temp_name, destination)
    finally:
        if os.path.exists(temp_name):
            os.unlink(temp_name)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true", help="Validate and report without writing files")
    args = parser.parse_args()
    try:
        destination = data_directory() / "emojis.json"
        print(f"Downloading {SOURCE}")
        payload = parse(download())
        print(f"Unicode version: {payload['unicode_version']}")
        print(f"Fully-qualified emoji entries: {len(payload['emojis'])}")
        print(f"Destination: {destination}")
        if args.dry_run:
            print("Dry run successful. No files changed.")
        else:
            atomic_write(destination, payload)
            print("Database updated successfully. Customizations were not touched.")
        return 0
    except (ValueError, OSError, UnicodeError, HTTPError, URLError) as error:
        print(f"Update failed; existing database unchanged: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
