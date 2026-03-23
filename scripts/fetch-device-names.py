#!/usr/bin/env python3
"""Generates device-names.json from appledb.dev data.

Only adds new entries — existing ones are never overwritten.

Usage:
    python3 scripts/device-names-skrypt.py
"""

import gzip
import json
import re
from pathlib import Path

import requests

APPLEDB_URL = "https://api.appledb.dev/device/main.json.gz"
OUTPUT = Path(__file__).parent.parent / "tealium/core/devicedata/device-names.json"

# Identifier prefixes that are relevant to this project.
# All other Apple products (AirPods, Beats, accessories...) are ignored.
IDENTIFIER_PREFIXES = (
    "iPhone", "iPod", "iPad",
    "Watch", "AppleTV",
    "Mac", "Macmini", "iMac", "MacBook", "MacPro",
)

# Simulator entries are not in appledb, so we add them manually.
SIMULATOR_ENTRIES = {
    "i386":   {"model_name": "Simulator", "model_variant": "32-bit"},
    "x86_64": {"model_name": "Simulator", "model_variant": "64-bit"},
    "arm64":  {"model_name": "Simulator", "model_variant": "64-bit"},
}

# Order in which device families appear in the output file.
# Must be longest-prefix-first so "MacBookPro" matches before "MacBook" and "Mac".
FAMILY_ORDER = [
    "iPhone", "iPod", "iPad",
    "AppleTV", "Watch",
    "Macmini", "iMac", "iMacPro", "MacPro", "MacBook", "MacBookAir", "MacBookPro", "Mac",
]

# Checked longest-first to avoid "Wi-Fi" matching before "Wi-Fi + Cellular".
CONNECTIVITY_SUFFIXES = [
    "Wi-Fi + Cellular",
    "Wi-Fi",
    "Cellular",
    "CDMA",
    "GSM",
]


def parse_name(name: str) -> tuple[str, str]:
    """Split an appledb device name into (model_name, model_variant).

    appledb encodes variants directly in the name, e.g.:
        "iPhone 7 (CDMA)"               -> ("iPhone 7", "CDMA")
        "iPad Pro 11-inch (M4) Wi-Fi"   -> ("iPad Pro 11-inch (M4)", "Wi-Fi")
        "Apple Watch Series 9 (GPS, 41mm)" -> ("Apple Watch Series 9", "GPS, 41mm")
        "MacBook Pro (14-inch, M3, 2023)"  -> ("MacBook Pro (14-inch, M3, 2023)", "")
        "iPhone 16"                        -> ("iPhone 16", "")
    """
    # 1. Trailing connectivity suffix (longest match wins).
    for suffix in CONNECTIVITY_SUFFIXES:
        if name.endswith(f" {suffix}"):
            return name[: -(len(suffix) + 1)].strip(), suffix

    # 2. Parenthesized variant at the end — but NOT Mac-style names that include
    #    a release year like "(14-inch, M3, 2023)".
    m = re.search(r"\s*\(([^)]+)\)$", name)
    if m:
        content = m.group(1)
        if not re.search(r"\b20\d{2}\b", content):
            return name[: m.start()].strip(), content

    return name, ""


def sort_key(identifier: str) -> tuple:
    """Return a sort key so identifiers are grouped by family and ordered by version."""
    for i, family in enumerate(FAMILY_ORDER):
        if identifier.startswith(family):
            # Extract the numeric part after the prefix, e.g. "4,1" from "iPhone4,1".
            rest = identifier[len(family):]
            m = re.match(r"(\d+),(\d+)", rest)
            if m:
                return (i, int(m.group(1)), int(m.group(2)))
            return (i, 0, 0)
    # Simulators and unknowns go at the end.
    return (len(FAMILY_ORDER), 0, 0)


def fetch_devices() -> list[dict]:
    print(f"Fetching {APPLEDB_URL} ...")
    data = gzip.decompress(requests.get(APPLEDB_URL, timeout=30).content)
    return json.loads(data)


def main() -> None:
    existing: dict[str, dict] = {}
    if OUTPUT.exists():
        with OUTPUT.open(encoding="utf-8") as f:
            existing = json.load(f)

    devices = fetch_devices()

    new_entries: dict[str, dict] = {}
    count_unchanged = 0
    count_would_update = 0

    for device in devices:
        identifiers = device.get("identifier", [])
        name = device.get("name", "")

        if not identifiers or not name:
            continue

        if isinstance(identifiers, str):
            identifiers = [identifiers]

        model_name, model_variant = parse_name(name)
        entry = {"model_name": model_name, "model_variant": model_variant}

        for identifier in identifiers:
            if not any(identifier.startswith(prefix) for prefix in IDENTIFIER_PREFIXES):
                continue

            if identifier in existing:
                if existing[identifier] != entry:
                    count_would_update += 1
                else:
                    count_unchanged += 1
            else:
                new_entries[identifier] = entry

    # Simulator entries: same logic — only add if not already present.
    for identifier, entry in SIMULATOR_ENTRIES.items():
        if identifier in existing:
            if existing[identifier] != entry:
                count_would_update += 1
            else:
                count_unchanged += 1
        else:
            new_entries[identifier] = entry

    merged = {**existing, **new_entries}
    result = dict(sorted(merged.items(), key=lambda kv: sort_key(kv[0])))

    with OUTPUT.open("w", encoding="utf-8") as f:
        json.dump(result, f, indent=2, ensure_ascii=False)
        f.write("\n")

    print(f"New entries added : {len(new_entries)}")
    print(f"Unchanged         : {count_unchanged}")
    print(f"Could be updated  : {count_would_update} (skipped — existing entries are preserved)")
    print(f"Total in file     : {len(result)}")
    print(f"(Entries sorted by device family and version number)")


if __name__ == "__main__":
    main()
