#!/bin/bash
# created with Claude. Account: Milobowler

HISTORY_DIR="/tmp/hypr-window-history"

echo "Swap script started" >> /tmp/swap-debug.log

# Get current workspace
workspace=$(hyprctl activeworkspace -j | jq -r '.id')
HISTORY_FILE="$HISTORY_DIR/workspace-$workspace"

# Check if history exists
if [ ! -f "$HISTORY_FILE" ]; then
    notify-send "No window history" "Focus some windows first" -t 2000
    echo "No history file for workspace $workspace" >> /tmp/swap-debug.log
    exit 1
fi

# Read last two windows
mapfile -t history < "$HISTORY_FILE"

if [ ${#history[@]} -lt 2 ]; then
    notify-send "Not enough windows" "Need at least 2 focused windows" -t 2000
    echo "Only ${#history[@]} windows in history" >> /tmp/swap-debug.log
    exit 1
fi

# Parse first window (most recent)
read window1 x1 y1 <<< "${history[0]}"

# Parse second window (previous)
read window2 x2 y2 <<< "${history[1]}"

echo "Window 1: $window1 at ($x1, $y1)" >> /tmp/swap-debug.log
echo "Window 2: $window2 at ($x2, $y2)" >> /tmp/swap-debug.log

# Calculate direction between them
x_diff=$((x2 - x1))
y_diff=$((y2 - y1))

if [ ${x_diff#-} -gt ${y_diff#-} ]; then
    if [ $x_diff -gt 0 ]; then
        direction="r"
    else
        direction="l"
    fi
else
    if [ $y_diff -gt 0 ]; then
        direction="d"
    else
        direction="u"
    fi
fi

echo "Direction: $direction" >> /tmp/swap-debug.log

# Focus first window and swap
hyprctl dispatch focuswindow address:$window1
sleep 0.05
hyprctl dispatch swapwindow $direction

notify-send "Windows swapped" -t 1000

echo "Swap completed" >> /tmp/swap-debug.log
