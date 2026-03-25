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

APPLEDB_DEVICE_URL = "https://api.appledb.dev/device/main.json.gz"
APPLEDB_OS_URL = "https://api.appledb.dev/ios/{os_str}/main.json.gz"
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


def _fetch_gz(url: str) -> list[dict]:
    try:
        response = requests.get(url, timeout=30)
        response.raise_for_status()
        return json.loads(gzip.decompress(response.content))
    except requests.RequestException as exc:
        raise RuntimeError(f"Failed to fetch {url}: {exc}") from exc
    except (OSError, json.JSONDecodeError) as exc:
        raise RuntimeError(f"Failed to decode data from {url}") from exc


def build_supported_identifiers(
    deployment_targets: dict[str, tuple[int, int]],
    key_to_identifiers: dict[str, list[str]],
) -> set[str]:
    """Return all device identifiers that appear in OS builds at or above the deployment targets.

    appledb OS builds carry a deviceMap listing every device key that supports that release.
    A device is considered supported if it appears in any non-beta build of the minimum OS
    version or later, meaning it can run at least the SDK's minimum deployment target.
    """
    supported: set[str] = set()
    for platform, (major, minor) in deployment_targets.items():
        print(f"Fetching {platform} build list ...")
        builds = _fetch_gz(APPLEDB_OS_URL.format(os_str=platform))
        for build in builds:
            if build.get("internal") or build.get("beta") or build.get("rc"):
                continue
            version = build.get("version", "")
            parts = version.split(".")
            try:
                v = (int(parts[0]), int(parts[1]) if len(parts) > 1 else 0)
            except ValueError:
                continue
            if v < (major, minor):
                continue
            for key in build.get("deviceMap", []):
                identifiers = key_to_identifiers.get(key)
                if identifiers:
                    supported.update(identifiers)
    return supported


def fetch_devices() -> list[dict]:
    print(f"Fetching {APPLEDB_DEVICE_URL} ...")
    return _fetch_gz(APPLEDB_DEVICE_URL)


def main() -> None:
    existing: dict[str, dict] = {}
    if OUTPUT.exists():
        with OUTPUT.open(encoding="utf-8") as f:
            existing = json.load(f)

    devices = fetch_devices()

    # Build key→identifiers mapping so OS build deviceMaps can be resolved to real identifiers.
    # macOS devices use variant keys like "MacBookAir6,1-2013" that differ from their identifier.
    key_to_identifiers: dict[str, list[str]] = {}
    for device in devices:
        key = device.get("key")
        if not key:
            continue
        identifiers = device.get("identifier", [])
        if isinstance(identifiers, str):
            identifiers = [identifiers]
        if identifiers:
            key_to_identifiers[key] = identifiers

    deployment_targets = parse_deployment_targets()
    supported_identifiers = build_supported_identifiers(deployment_targets, key_to_identifiers)

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

            if identifier not in supported_identifiers:
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
