#!/bin/bash

# Define where your mirror lives
MIRROR="/home/shayan/.mydotfiles/Backup"

# List the folders you want to copy
folders=("dunst" "hypr" "kitty" "micro/plug" "micro/colorschemes" "rofi" "waybar" "yazi/plugins")

# List individual files you want to copy
files=("micro/bindings.json" "micro/settings.json" "yazi/init.lua" "yazi/keymap.toml" "yazi/package.toml" "yazi/yazi.toml")

echo "Syncing configs to mirror..."

# Sync folders
for folder in "${folders[@]}"; do
    # Get the parent directory
    dir=$(dirname "$folder")
    # Create parent directory structure in mirror
    mkdir -p "$MIRROR/$dir"
    # Sync to preserve the full path
    rsync -avL --delete "$HOME/.config/$folder" "$MIRROR/$dir/"
done

# Sync individual files
for file in "${files[@]}"; do
    # Get the directory part of the file path
    dir=$(dirname "$file")
    # Create the directory in mirror if it doesn't exist
    mkdir -p "$MIRROR/$dir"
    # Copy just that file
    rsync -avL "$HOME/.config/$file" "$MIRROR/$file"
done

echo "Mirror updated! Ready to drag Mirror Folder to GitHub."
