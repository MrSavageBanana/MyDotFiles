#!/usr/bin/env python3
# created with Claude. Account: Milobowler

import os
import json
import hashlib
import re
from pathlib import Path
from collections import defaultdict

CONFIG_DIR = Path.home() / ".config"
MIRROR_DIR = Path.home() / ".mydotfiles" / "Backup"
SYNC_SCRIPT = Path.home() / ".mydotfiles" / "sync_dots.sh"

def parse_bash_array(script_content, array_name):
    """Parse a bash array from the sync script"""
    # Match the array declaration across multiple lines
    pattern = rf'{array_name}=\((.*?)\)'
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
        with open(SYNC_SCRIPT, 'r') as f:
            content = f.read()
        
        folders = parse_bash_array(content, 'folders')
        files = parse_bash_array(content, 'files')
        
        return folders, files
    except Exception as e:
        print(json.dumps({"text": " | ", "tooltip": f"Error reading sync script: {e}", "class": "error"}))
        exit(1)

def get_file_hash(filepath):
    """Get MD5 hash of a file"""
    try:
        with open(filepath, 'rb') as f:
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
    parts = path.split('/')
    
    # Try each depth from shortest to longest
    for depth in range(1, len(parts) + 1):
        candidate = '/'.join(parts[-depth:])
        
        # Check if this candidate matches any other path
        matches = [p for p in all_paths if p.endswith(candidate) and p != path]
        
        if not matches:
            return candidate
    
    # Fallback to full path
    return path

def format_tooltip(mismatched_paths, all_paths):
    """Format tooltip with app grouping"""
    # Simplify paths
    simplified = []
    for path in mismatched_paths:
        simplified.append((path, simplify_path(path, all_paths)))
    
    # Group by top-level folder (app)
    grouped = defaultdict(list)
    for full_path, simple_path in simplified:
        app = full_path.split('/')[0].capitalize()
        grouped[app].append(simple_path)
    
    # Format output
    lines = []
    for app in sorted(grouped.keys()):
        files = sorted(grouped[app])
        # App name on its own line
        lines.append(f"{app} -")
        # All files below it
        for file in files:
            lines.append(file)
    
    return '\n'.join(lines)

def main():
    folders, files = get_watched_config()
    all_watched = get_all_watched_files(folders, files)
    mismatched = find_mismatched_files(folders, files)
    
    if mismatched:
        tooltip = format_tooltip(mismatched, all_watched)
        
        output = {
            "text": " | ",
            "tooltip": tooltip,
            "class": "out-of-sync"
        }
    else:
        output = {
            "text": " | ",
            "class": "in-sync"
        }
    
    print(json.dumps(output))

if __name__ == "__main__":
    main()
