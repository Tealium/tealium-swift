#!/usr/bin/env python3
"""Generates device-names.json from appledb.dev data.

Only adds new entries — existing ones are never overwritten.

Usage:
    python3 scripts/fetch-device-names.py

Exit codes:
    0 — file is already up to date, nothing requires attention.
    1 — new entries were added, or diffs/warnings were found; review the
        output before committing.
"""

# =============================================================================
# OUTPUT FORMAT SPECIFICATION
# =============================================================================
#
# Each entry in device-names.json has two fields:
#
#   model_name    — the human-readable product name, WITHOUT connectivity,
#                   carrier, region, or storage details.
#                   Examples: "iPhone 16 Pro", "iPad Pro 11-inch (M4)",
#                             "Apple Watch Series 10", "MacBook Pro (14-inch, M3, 2023)"
#
#   model_variant — a short string distinguishing variants of the same model,
#                   or "" for single-variant devices (most iPhones and all Macs).
#                   Extracted/normalized from appledb names (appledb uses "Wi-Fi" with
#                   a hyphen; we normalize to "WiFi" via _VARIANT_NORMALIZE).
#                   Common values:
#                     "WiFi"                     — Wi-Fi only iPads / Apple TVs
#                     "WiFi + Cellular"          — iPads with cellular
#                     "WiFi + Ethernet"          — Apple TV 4K 3rd gen and later
#                     "CDMA" / "GSM"             — older carrier-locked iPhones
#                     "41mm" / "45mm" etc.       — Apple Watch GPS-only
#                                                  (appledb: "GPS, 41mm" → "41mm")
#                     "41mm Cellular" etc.       — Apple Watch cellular
#                                                  (appledb: "GPS + Cellular, 41mm" → "41mm Cellular")
#                     "M1 Max" / "M1 Ultra"      — Mac Studio (chip is the only differentiator)
#
# IDENTIFIER FORMAT
#   {FamilyName}{major},{minor}   e.g.  iPhone16,1   Watch6,14   Macmini9,1
#
#   FamilyName — one of the string prefixes in IDENTIFIER_PREFIXES.
#   major      — product generation within the family. Higher = newer.
#                NOT related to iOS/macOS version numbers.
#   minor      — hardware variant within one generation (1-based).
#                Typically 1 = Wi-Fi / GPS-only, 2 = Cellular, higher = region variants.
#
#   Families that use non-standard prefixes in appledb vs. Apple's own naming:
#     appledb "Mac14,2"     → Apple calls it "MacBook Air (M2, 2022)"  (no MacBook prefix)
#     appledb "Macmini9,1"  → "Mac mini (M1, 2020)"  (lowercase 'm' in Macmini)
#
# HOW parse_name() MAPS appledb NAMES TO (model_name, model_variant)
#
#   appledb encodes variants directly in the product name string. The rules below
#   describe what parse_name() expects. If appledb changes its naming convention,
#   the script emits a WARNING instead of silently producing wrong output.
#
#   Rule 1 — CHIP IN PARENS at end of string, connectivity in the base:
#              The string ends with "({chip})" where chip matches [MAS]\d+(Pro|Max|Ultra)?.
#              If a connectivity suffix appears in the base (before the chip parens), it is
#              stripped from model_name and becomes model_variant (normalized via _VARIANT_NORMALIZE).
#              If no connectivity suffix is present, the chip itself becomes model_variant.
#              e.g.  "iPad Pro 11-inch Wi-Fi (M5)"  → ("iPad Pro 11-inch (M5)", "WiFi")
#                    "Mac Studio (M1 Max)"           → ("Mac Studio", "M1 Max")
#
#   Rule 2 — YEAR OR SCREEN SIZE IN PARENS at end of string:
#              Matches \b20\d{2}\b (year) or \d+-inch (screen size) inside the trailing parens.
#              Signals a fully-qualified Mac-style name that should be kept as-is.
#              Screen size alone catches new models that appledb has not yet assigned a year to.
#              e.g.  "MacBook Pro (14-inch, M3, 2023)"  → unchanged, model_variant = ""
#                    "MacBook Air (13-inch, M5)"         → unchanged, model_variant = ""
#
#   Rule 3 — APPLE WATCH VARIANT in parens: optional generation, GPS[+Cellular], size:
#              Regex requires the full word "generation" (not "gen").
#              e.g.  "Apple Watch Series 9 (GPS, 41mm)"                       → ("Apple Watch Series 9", "41mm")
#                    "Apple Watch Series 9 (GPS + Cellular, 45mm)"            → ("Apple Watch Series 9", "45mm Cellular")
#                    "Apple Watch SE (1st generation, GPS, 40mm)"             → ("Apple Watch SE (1st generation)", "40mm")
#                    "Apple Watch SE (2nd generation, GPS + Cellular, 44mm)"  → ("Apple Watch SE (2nd generation)", "44mm Cellular")
#              Format: {size} or {size} Cellular — no "GPS" prefix, no comma, size first.
#              Generation (if present) is promoted into model_name.
#
#   Rule 4 — OTHER PARENS CONTENT at end of string:
#              Treated as model_variant.
#              e.g.  "iPhone 7 (CDMA)"        → ("iPhone 7", "CDMA")
#                    "iPad (2nd generation)"   → ("iPad", "2nd generation")
#
#   Rule 5 — TRAILING CONNECTIVITY SUFFIX (no parens at end of string):
#              The string does not end with ")" so Rules 1-4 are skipped.
#              A known connectivity suffix at the end is stripped and normalized.
#              Inner parens (if any) are preserved in model_name.
#              e.g.  "Apple TV 4K (3rd generation) Wi-Fi + Ethernet"  → ("Apple TV 4K (3rd generation)", "WiFi + Ethernet")
#                    "iPad Pro 11-inch (M4) Wi-Fi"                    → ("iPad Pro 11-inch (M4)", "WiFi")
#
# KNOWN LIMITATIONS (require manual fix if encountered):
#   - Names like "iPad 2 Wi-Fi + 3G (GSM)" — "Wi-Fi + 3G" is not in CONNECTIVITY_SUFFIXES.
#     The script will warn about this; a human must decide the correct model_variant.
#   - Carrier/region specifiers in parens, e.g. "(VZ)", "(TD-LTE)", "(MM)" — the script
#     extracts the carrier as model_variant but connectivity stays in model_name.
#     These are very old devices (pre-iOS 12) and will not appear in the output because
#     they are filtered out by the deployment target check, but the warning is still emitted.
# =============================================================================

import gzip
import json
import re
import sys
import urllib.error
import urllib.request
from pathlib import Path

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
# These must match appledb's spelling exactly; output is normalized via _VARIANT_NORMALIZE.
CONNECTIVITY_SUFFIXES = [
    "Wi-Fi + Cellular",
    "Wi-Fi + Ethernet",
    "Wi-Fi",
    "Cellular",
    "CDMA",
    "GSM",
]

# Normalize appledb connectivity strings to our canonical spelling ("WiFi", not "Wi-Fi").
_VARIANT_NORMALIZE = {
    "Wi-Fi + Cellular": "WiFi + Cellular",
    "Wi-Fi + Ethernet": "WiFi + Ethernet",
    "Wi-Fi": "WiFi",
}

# Matches Apple Watch variant strings from appledb parens:
#   "GPS, 40mm"  /  "GPS + Cellular, 41mm"  /  "1st generation, GPS + Cellular, 44mm"
# Groups: (1) optional generation phrase, (2) connectivity, (3) size
_WATCH_VARIANT_RE = re.compile(
    r"^(?:(\d+(?:st|nd|rd|th) generation),\s*)?"
    r"(GPS(?:\s*\+\s*Cellular)?),\s*"
    r"(\d+mm)$",
    re.IGNORECASE,
)

# Chip names (M-series, A-series, S-series) belong in model_name, not model_variant.
_CHIP_RE = re.compile(r"^[MAS]\d+(\s+(Pro|Max|Ultra))?$", re.IGNORECASE)

# Valid model_variant values for newly parsed entries (not applied to existing entries).
# Anything not matching this pattern is flagged in the FORMAT WARNINGS section.
_VALID_VARIANT_RE = re.compile(
    r"^$"                                    # single-variant (most iPhones, all Macs)
    r"|^WiFi(\s\+\s(Cellular|Ethernet))?$"  # iPad / Apple TV connectivity
    r"|^(CDMA|GSM)$"                         # legacy carrier-locked iPhones
    r"|^\d+mm(\sCellular)?$"                 # Apple Watch size (e.g. "41mm", "45mm Cellular")
    r"|^[MAS]\d+(\s+(Pro|Max|Ultra))?$"      # Mac Studio chip (e.g. "M1 Max", "M2 Ultra")
)

_SEP = "=" * 70


def parse_name(name: str) -> tuple[str, str]:
    """Split an appledb device name into (model_name, model_variant).

    See the OUTPUT FORMAT SPECIFICATION comment above for the full mapping rules.
    Returns (model_name, model_variant); model_variant is "" for single-variant devices.
    """
    m = re.search(r"\s*\(([^)]+)\)$", name)
    if m:
        content = m.group(1)
        base = name[: m.start()]

        # Rule 1 — chip in parens, connectivity suffix may appear before or after.
        if _CHIP_RE.match(content):
            for suffix in CONNECTIVITY_SUFFIXES:
                if base.endswith(f" {suffix}"):
                    base_without_suffix = base[: -(len(suffix) + 1)].strip()
                    return f"{base_without_suffix} ({content})", _VARIANT_NORMALIZE.get(suffix, suffix)
            return base, content

        # Rule 2 — Mac-style name: parens contain a release year ("2023") or a screen size
        #           ("14-inch"). Either signals a fully-qualified Mac name that should be
        #           kept intact.  Screen size check catches new models appledb has not yet
        #           assigned a year to, e.g. "MacBook Air (13-inch, M5)".
        if re.search(r"\b20\d{2}\b", content) or re.search(r"\d+-inch", content):
            return name, ""

        # Rule 3 — Apple Watch variant: normalise to "{size}" or "{size} Cellular".
        wm = _WATCH_VARIANT_RE.match(content)
        if wm:
            generation = wm.group(1)   # e.g. "1st generation", or None
            has_cellular = "Cellular" in wm.group(2)
            size = wm.group(3)         # e.g. "40mm"
            model_name = f"{base} ({generation})" if generation else base
            model_variant = f"{size} Cellular" if has_cellular else size
            return model_name, model_variant

        # Rule 4 — other parens content becomes model_variant.
        return base, content

    # Rule 5 — trailing connectivity suffix with no parenthesized content.
    for suffix in CONNECTIVITY_SUFFIXES:
        if name.endswith(f" {suffix}"):
            return name[: -(len(suffix) + 1)].strip(), _VARIANT_NORMALIZE.get(suffix, suffix)

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
        with urllib.request.urlopen(url, timeout=30) as response:
            return json.loads(gzip.decompress(response.read()))
    except urllib.error.URLError as exc:
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
    # Each tuple: (identifier, current entry in file, entry that appledb would produce).
    updates_skipped: list[tuple[str, dict, dict]] = []
    count_unchanged = 0
    count_skipped_old = 0
    warnings: list[str] = []
    format_warnings: list[str] = []

    for device in devices:
        identifiers = device.get("identifier", [])
        name = device.get("name", "")

        if not identifiers or not name:
            continue

        if "Unreleased" in name:
            continue

        # Skip internal devices (research VMs, store display models, etc.).
        if device.get("internal"):
            continue

        # Skip devices whose primary key doesn't belong to a known family —
        # some chips (e.g. T1 iBridge) reuse Watch identifiers as secondaries.
        device_key = device.get("key", "")
        if not any(device_key.startswith(prefix) for prefix in IDENTIFIER_PREFIXES):
            continue

        if isinstance(identifiers, str):
            identifiers = [identifiers]

        model_name, model_variant = parse_name(name)
        entry = {"model_name": model_name, "model_variant": model_variant}

        # Detect parsing issues now; only emit warnings for devices that actually
        # pass the deployment-target filter and will appear in the output.
        parse_warning: str | None = None
        for suffix in CONNECTIVITY_SUFFIXES:
            if suffix in model_name:
                parse_warning = (
                    f"  appledb : {name!r}\n"
                    f"  parsed  : model_name={model_name!r}\n"
                    f"            model_variant={model_variant!r}\n"
                    f"  problem : '{suffix}' still inside model_name — fix manually in device-names.json"
                )
                break

        warned_for_device = False
        for identifier in identifiers:
            if not any(identifier.startswith(prefix) for prefix in IDENTIFIER_PREFIXES):
                continue

            if identifier not in supported_identifiers:
                count_skipped_old += 1
                continue

            if parse_warning and not warned_for_device:
                warnings.append(f"{identifier}: {parse_warning}")
                warned_for_device = True

            if identifier in existing:
                if existing[identifier] != entry:
                    updates_skipped.append((identifier, existing[identifier], entry))
                else:
                    count_unchanged += 1
            else:
                if not _VALID_VARIANT_RE.match(model_variant):
                    format_warnings.append(
                        f"{identifier}: model_variant={model_variant!r} is not a recognized pattern\n"
                        f"    parsed from appledb name: {name!r}\n"
                        f"    model_name={model_name!r}\n"
                        f"    Verify this is correct and update device-names.json manually if needed."
                    )
                new_entries[identifier] = entry

    # Simulator entries: same logic — only add if not already present.
    for identifier, entry in SIMULATOR_ENTRIES.items():
        if identifier in existing:
            if existing[identifier] != entry:
                updates_skipped.append((identifier, existing[identifier], entry))
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
    print(f"Skipped updates   : {len(updates_skipped)} (existing entries are preserved)")
    print(f"Skipped (too old) : {count_skipped_old}")
    print(f"Total in file     : {len(result)}")
    print(f"(Entries sorted by device family and version number)")

    if new_entries:
        print(f"\n{_SEP}")
        print(f"NEW ENTRIES — {len(new_entries)} item(s) added. Verify before committing.")
        print(_SEP)
        max_id = max(len(k) for k in new_entries)
        for identifier, e in sorted(new_entries.items(), key=lambda kv: sort_key(kv[0])):
            print(f"  {identifier:<{max_id}}  model_name={e['model_name']!r}  model_variant={e['model_variant']!r}")

    if updates_skipped:
        print(f"\n{_SEP}")
        print(f"SKIPPED UPDATES — {len(updates_skipped)} item(s) differ from appledb.")
        print("Existing entries are preserved. Review and decide whether to update manually.")
        print(_SEP)
        for identifier, current, appledb_entry in sorted(updates_skipped, key=lambda t: sort_key(t[0])):
            print(f"\n  {identifier}")
            print(f"    current : model_name={current['model_name']!r}  model_variant={current['model_variant']!r}")
            print(f"    appledb : model_name={appledb_entry['model_name']!r}  model_variant={appledb_entry['model_variant']!r}")

    if format_warnings:
        print(f"\n{_SEP}")
        print(f"FORMAT WARNINGS — {len(format_warnings)} new item(s) have unexpected model_variant values.")
        print("Review and correct in device-names.json before committing.")
        print(_SEP)
        for w in format_warnings:
            print(f"\n  • {w}")

    if warnings:
        print(f"\n{_SEP}")
        print(f"PARSE WARNINGS — {len(warnings)} item(s) could not be parsed automatically.")
        print("Review each entry below and correct device-names.json manually.")
        print(_SEP)
        for w in warnings:
            identifier, body = w.split(": ", 1)
            print(f"\n  [{identifier}]")
            print(body)

    needs_review = bool(warnings or format_warnings or new_entries or updates_skipped)
    if needs_review:
        sys.exit(1)


if __name__ == "__main__":
    main()
