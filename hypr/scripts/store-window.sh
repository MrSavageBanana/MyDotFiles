#!/bin/bash
# created with Claude. Account: Milobowler

# Get current window
current_window=$(hyprctl activewindow -j | jq -r '.address')
current_x=$(hyprctl activewindow -j | jq -r '.at[0]')
current_y=$(hyprctl activewindow -j | jq -r '.at[1]')

# Store to file
echo "$current_window $current_x $current_y" > /tmp/swap-stored-window

echo "Stored window: $current_window at ($current_x, $current_y)" >> /tmp/swap-debug.log

# Optional: Visual feedback with notification
notify-send "Window marked for swap" -t 1000
