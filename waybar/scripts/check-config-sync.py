#!/usr/bin/env python3
# created with Claude. Account: Milobowler

import os
import json
import hashlib
import re
import argparse
import subprocess
from pathlib import Path
from collections import defaultdict
from xml.sax.saxutils import escape as xml_escape

CONFIG_DIR = Path.home() / ".config"
MIRROR_DIR = Path.home() / ".mydotfiles" / "Backup"
SYNC_SCRIPT = Path.home() / ".mydotfiles" / "sync_dots.sh"

# Color used for the app/folder header lines in the tooltip (Pango markup).
# Waybar tooltips render Pango markup, so this shows up as an actual color.
APP_HEADER_COLOR = "#1AE5CC"

def get_display_text():
    """Run hyprctl command to get the number of selected clients"""
    cmd = "hyprctl clients -j | jq '[.[] | select(.tags[]? == \"selected\")] | length'"
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        if result.returncode == 0:
            count = int(result.stdout.strip())
            return " | " if count == 0 else str(count)
    except Exception:
        pass
    return " | "


def parse_bash_array(script_content, array_name):
    """Parse a bash array from the sync script"""
    # Match the array declaration across multiple lines
    pattern = rf"{array_name}=\((.*?)\)"
    match = re.search(pattern, script_content, re.DOTALL)

    if not match:
        return []

    array_content = match.group(1)
    # Extract quoted strings
    items = re.findall(r'"([^"]+)"', array_content)
    return items


def get_watched_config():
    """Read folders and files from the sync script"""
    try:
        with open(SYNC_SCRIPT, "r") as f:
            content = f.read()

        folders = parse_bash_array(content, "folders")
        files = parse_bash_array(content, "files")

        return folders, files
    except Exception as e:
        print(
            json.dumps(
                {
                    "text": get_display_text(),
                    "tooltip": f"Error reading sync script: {e}",
                    "class": "error",
                }
            )
        )
        exit(1)


def get_file_hash(filepath):
    """Get MD5 hash of a file"""
    try:
        with open(filepath, "rb") as f:
            return hashlib.md5(f.read()).hexdigest()
    except:
        return None


def get_all_files_in_folder(folder_path):
    """Recursively get all files in a folder"""
    all_files = []
    try:
        for root, dirs, files_list in os.walk(folder_path):
            for file in files_list:
                all_files.append(Path(root) / file)
    except:
        pass
    return all_files


def get_all_watched_files(folders, files):
    """Get all files being watched (from config dir)"""
    watched = []

    # Get all files in watched folders
    for folder in folders:
        config_folder = CONFIG_DIR / folder
        config_files = get_all_files_in_folder(config_folder)
        for config_file in config_files:
            rel_path = config_file.relative_to(CONFIG_DIR)
            watched.append(str(rel_path))

    # Add individual files
    for file in files:
        watched.append(file)

    return watched


def find_mismatched_files(folders, files):
    """Find all files that don't match between config and mirror"""
    mismatched = []

    # Check folders
    for folder in folders:
        config_folder = CONFIG_DIR / folder
        mirror_folder = MIRROR_DIR / folder

        config_files = get_all_files_in_folder(config_folder)

        for config_file in config_files:
            rel_path = config_file.relative_to(CONFIG_DIR)
            mirror_file = MIRROR_DIR / rel_path

            config_hash = get_file_hash(config_file)
            mirror_hash = get_file_hash(mirror_file)

            if config_hash != mirror_hash:
                mismatched.append(str(rel_path))

    # Check individual files
    for file in files:
        config_file = CONFIG_DIR / file
        mirror_file = MIRROR_DIR / file

        config_hash = get_file_hash(config_file)
        mirror_hash = get_file_hash(mirror_file)

        if config_hash != mirror_hash:
            mismatched.append(file)

    return mismatched


def simplify_path(path, all_paths):
    """Find the shortest unique suffix for a given path"""
    parts = path.split("/")

    # Try each depth from shortest to longest
    for depth in range(1, len(parts) + 1):
        candidate = "/".join(parts[-depth:])

        # Check if this candidate matches any other path
        matches = [p for p in all_paths if p.endswith(candidate) and p != path]

        if not matches:
            return candidate

    # Fallback to full path
    return path


def build_ordered_entries(mismatched_paths, all_paths):
    """Return mismatched files grouped by app and sorted exactly the way they
    appear in the tooltip: apps alphabetically, then files alphabetically by
    their simplified display name within each app.

    Returns a list of (app, simple_path, full_path) tuples, in display order.
    full_path is the path relative to CONFIG_DIR, so it can be used to build
    both the config and mirror file locations for diffing.
    """
    simplified = [(path, simplify_path(path, all_paths)) for path in mismatched_paths]

    grouped = defaultdict(list)
    for full_path, simple_path in simplified:
        app = full_path.split("/")[0].capitalize()
        grouped[app].append((simple_path, full_path))

    entries = []
    for app in sorted(grouped.keys()):
        for simple_path, full_path in sorted(grouped[app]):
            entries.append((app, simple_path, full_path))

    return entries


def format_tooltip(entries):
    """Format tooltip with app grouping, using the pre-ordered entries."""
    lines = []
    current_app = None

    for app, simple_path, _full_path in entries:
        if app != current_app:
            # App name on its own line, colored via Pango markup
            # (escape in case an app/folder name ever contains &, <, >)
            safe_app = xml_escape(app)
            lines.append(f"<span foreground='{APP_HEADER_COLOR}'><b>{safe_app} -</b></span>")
            current_app = app

        lines.append(xml_escape(simple_path))

    return "\n".join(lines)


def run_diffs(entries):
    """Run `kitten diff <mirror> <config>` for each mismatched file, in the
    same order they're listed in the tooltip. Waits for each kitten diff to
    be closed before moving on to the next one."""
    if not entries:
        print("No mismatched files to diff.")
        return

    total = len(entries)
    for i, (app, simple_path, full_path) in enumerate(entries, start=1):
        config_file = CONFIG_DIR / full_path
        mirror_file = MIRROR_DIR / full_path

        print(f"[{i}/{total}] {app}: {simple_path}")

        if not config_file.exists():
            print(f"  skipping — missing from config: {config_file}")
            continue
        if not mirror_file.exists():
            print(f"  skipping — missing from mirror: {mirror_file}")
            continue

        try:
            subprocess.run(["kitten", "diff", str(mirror_file), str(config_file)])
        except FileNotFoundError:
            print("  'kitten' command not found — is kitty installed and on PATH?")
            return


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--diff",
        action="store_true",
        help="Run `kitten diff` for each mismatched file, in tooltip order, "
        "instead of printing the waybar JSON.",
    )
    args = parser.parse_args()

    folders, files = get_watched_config()
    all_watched = get_all_watched_files(folders, files)
    mismatched = find_mismatched_files(folders, files)
    entries = build_ordered_entries(mismatched, all_watched)

    if args.diff:
        run_diffs(entries)
        return

    display_text = get_display_text()

    if mismatched:
        tooltip = format_tooltip(entries)
        output = {"text": display_text, "tooltip": tooltip, "class": "out-of-sync"}
    else:
        output = {"text": display_text, "class": "in-sync"}

    print(json.dumps(output))


if __name__ == "__main__":
    main()
