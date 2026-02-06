#!/bin/bash
# created with Claude. Account: Milobowler

# Directory to store window history per workspace
HISTORY_DIR="/tmp/hypr-window-history"
mkdir -p "$HISTORY_DIR"

echo "Window focus monitor started at $(date)" >> /tmp/focus-monitor.log

last_window_global=""

# Poll every 0.2 seconds instead of using socket
while true; do
    # Get current workspace
    workspace=$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id')
    
    # Get current window info
    window_address=$(hyprctl activewindow -j 2>/dev/null | jq -r '.address')
    window_x=$(hyprctl activewindow -j 2>/dev/null | jq -r '.at[0]')
    window_y=$(hyprctl activewindow -j 2>/dev/null | jq -r '.at[1]')
    
    # Skip if no valid window
    if [ "$window_address" = "null" ] || [ -z "$window_address" ]; then
        sleep 0.2
        continue
    fi
    
    # Only process if window changed
    if [ "$window_address" != "$last_window_global" ]; then
        HISTORY_FILE="$HISTORY_DIR/workspace-$workspace"
        
        # Read existing history
        if [ -f "$HISTORY_FILE" ]; then
            mapfile -t history < "$HISTORY_FILE"
            last_window=$(echo "${history[0]}" | cut -d' ' -f1)
        else
            last_window=""
        fi
        
        # Only record if different from last window in this workspace
        if [ "$window_address" != "$last_window" ]; then
            new_entry="$window_address $window_x $window_y"
            
            # Write new history
            echo "$new_entry" > "$HISTORY_FILE"
            
            # Add previous window as second line
            if [ -n "$last_window" ]; then
                echo "${history[0]}" >> "$HISTORY_FILE"
            fi
            
            echo "$(date +%T) Workspace $workspace: $window_address" >> /tmp/focus-monitor.log
        fi
        
        last_window_global="$window_address"
    fi
    
    sleep 0.2
done
