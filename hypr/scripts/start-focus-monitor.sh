#!/bin/bash
# created with Claude. Account: Milobowler

# Kill any existing monitor
pkill -f window-focus-monitor.sh

# Start new monitor in background
~/.config/hypr/scripts/window-focus-monitor.sh &

echo "Focus monitor started with PID $!"
