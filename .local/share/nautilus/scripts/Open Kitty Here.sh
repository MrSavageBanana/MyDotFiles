#!/bin/bash
# A script to open the kitty terminal in the current Nautilus folder.
# This script uses the path of the current directory.

# 1. Get the current directory's URI from Nautilus
URI="$NAUTILUS_SCRIPT_CURRENT_URI"

# 2. Convert the URI (e.g., file:///home/user/dir) to a plain file path (/home/user/dir)
# This is a robust way to handle file URIs set by Nautilus.
# It strips 'file://' and then URL-decodes the path.
WORKING_DIR=$(echo "$URI" | sed 's/^file:\/\///')
WORKING_DIR=$(printf '%b' "${WORKING_DIR//%/\\x}")

# 3. Use the plain path to launch kitty
# The -d option for kitty sets the initial directory.
kitty --directory "$WORKING_DIR" &
