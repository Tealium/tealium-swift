#!/usr/bin/env python3
"""Generates device-names.json from appledb.dev data.

Only adds new entries — existing ones are never overwritten.

Usage:
    python3 scripts/fetch-device-names.py
"""

import gzip
import json
import re
from pathlib import Path

import requests

APPLEDB_URL = "https://api.appledb.dev/device/main.json.gz"
OUTPUT = Path(__file__).parent.parent / "tealium/core/devicedata/device-names.json"
PACKAGE_SWIFT = Path(__file__).parent.parent / "Package.swift"

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
    "Macmini", "iMacPro", "iMac", "MacPro", "MacBookAir", "MacBookPro", "MacBook", "Mac",
]

# Checked longest-first to avoid "Wi-Fi" matching before "Wi-Fi + Cellular".
CONNECTIVITY_SUFFIXES = [
    "Wi-Fi + Cellular",
    "Wi-Fi",
    "Cellular",
    "CDMA",
    "GSM",
]

# Oldest device identifier (major, minor) per family for each major OS version.
# Devices with an identifier below this threshold do not support the OS and are excluded.
# Extend this table when Package.swift deployment targets are raised.
_OS_TO_MIN_DEVICE: dict[str, dict[int, dict[str, tuple[int, int]]]] = {
    "iOS": {
        12: {"iPhone": (6, 1), "iPad": (4, 1), "iPod": (7, 1)},  # iPhone 5s / iPad Air / iPod touch 6th gen
        13: {"iPhone": (8, 1), "iPad": (5, 1), "iPod": (9, 1)},  # iPhone 6s / iPad mini 4 / iPod touch 7th gen
        14: {"iPhone": (8, 1), "iPad": (5, 1), "iPod": (9, 1)},
        15: {"iPhone": (8, 1), "iPad": (5, 1), "iPod": (9, 1)},
        16: {"iPhone": (10, 1), "iPad": (6, 11)},                 # iPhone 8 / iPad 5th gen
        17: {"iPhone": (11, 2), "iPad": (7, 5)},                  # iPhone XS / iPad 6th gen
        18: {"iPhone": (11, 2), "iPad": (7, 5)},
    },
    "tvOS": {
        12: {"AppleTV": (6, 2)},   # Apple TV HD is the oldest model supporting tvOS 12+
        13: {"AppleTV": (6, 2)},
        14: {"AppleTV": (6, 2)},
        15: {"AppleTV": (6, 2)},
        16: {"AppleTV": (6, 2)},
        17: {"AppleTV": (6, 2)},
        18: {"AppleTV": (6, 2)},
    },
    "watchOS": {
        4: {"Watch": (1, 1)},   # All Apple Watches
        5: {"Watch": (2, 3)},   # Dropped Series 0 (Watch1,x); Watch2,3 is the lowest >= Series 1
        6: {"Watch": (2, 3)},   # Same minimum as watchOS 5
        7: {"Watch": (3, 1)},   # Dropped Series 1 and 2
        8: {"Watch": (3, 1)},   # Minimum = Series 3
        9: {"Watch": (4, 1)},   # Dropped Series 3
        10: {"Watch": (4, 1)},
        11: {"Watch": (4, 1)},
    },
    # macOS identifiers do not follow a simple numeric progression, so no floor is applied.
}


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


def parse_deployment_targets() -> dict[str, tuple[int, int]]:
    """Parse minimum deployment targets from Package.swift.

    Returns a dict mapping platform name to (major, minor), e.g.
    {"iOS": (12, 0), "tvOS": (12, 0), "watchOS": (4, 0), "macOS": (10, 14)}.
    """
    text = PACKAGE_SWIFT.read_text(encoding="utf-8")
    result: dict[str, tuple[int, int]] = {}
    for m in re.finditer(r'\.(iOS|tvOS|watchOS|macOS)\(\.v(\d+)(?:_(\d+))?\)', text):
        platform = m.group(1)
        major = int(m.group(2))
        minor = int(m.group(3)) if m.group(3) else 0
        result[platform] = (major, minor)
    return result


def build_min_device_floor() -> dict[str, tuple[int, int]]:
    """Derive per-family minimum identifier from Package.swift deployment targets.

    Devices with an identifier below the returned floor do not support the SDK's
    minimum OS and are excluded from the output file.
    """
    targets = parse_deployment_targets()
    floor: dict[str, tuple[int, int]] = {}
    for platform, (major, _) in targets.items():
        entries = _OS_TO_MIN_DEVICE.get(platform, {}).get(major)
        if entries:
            floor.update(entries)
        elif platform != "macOS":
            print(f"Warning: no device floor defined for {platform} {major} — update _OS_TO_MIN_DEVICE.")
    return floor


def is_too_old(identifier: str, floor: dict[str, tuple[int, int]]) -> bool:
    """Return True if identifier predates the minimum supported version for its family."""
    for family in FAMILY_ORDER:
        if identifier.startswith(family):
            rest = identifier[len(family):]
            m = re.match(r"(\d+),(\d+)", rest)
            if m and family in floor:
                return (int(m.group(1)), int(m.group(2))) < floor[family]
            return False
    return False


def fetch_devices() -> list[dict]:
    print(f"Fetching {APPLEDB_URL} ...")
    try:
        response = requests.get(APPLEDB_URL, timeout=30)
        response.raise_for_status()
        data = gzip.decompress(response.content)
        return json.loads(data)
    except requests.RequestException as exc:
        raise RuntimeError(f"Failed to fetch device data from {APPLEDB_URL}: {exc}") from exc
    except (OSError, json.JSONDecodeError) as exc:
        raise RuntimeError(f"Failed to decode device data from {APPLEDB_URL}") from exc


def main() -> None:
    existing: dict[str, dict] = {}
    if OUTPUT.exists():
        with OUTPUT.open(encoding="utf-8") as f:
            existing = json.load(f)

    devices = fetch_devices()
    min_versions = build_min_device_floor()

    new_entries: dict[str, dict] = {}
    count_unchanged = 0
    count_would_update = 0
    count_skipped_old = 0

    for device in devices:
        identifiers = device.get("identifier", [])
        name = device.get("name", "")

        if not identifiers or not name:
            continue

        if "Unreleased" in name:
            continue

        if isinstance(identifiers, str):
            identifiers = [identifiers]

        model_name, model_variant = parse_name(name)
        entry = {"model_name": model_name, "model_variant": model_variant}

        for identifier in identifiers:
            if not any(identifier.startswith(prefix) for prefix in IDENTIFIER_PREFIXES):
                continue

            if is_too_old(identifier, min_versions):
                count_skipped_old += 1
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
    print(f"Skipped (too old) : {count_skipped_old}")
    print(f"Total in file     : {len(result)}")
    print(f"(Entries sorted by device family and version number)")


if __name__ == "__main__":
    main()
