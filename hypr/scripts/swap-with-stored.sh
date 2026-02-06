#!/bin/bash
# created with Claude. Account: Milobowler

echo "Swap script started" >> /tmp/swap-debug.log

# Check if we have a stored window
if [ ! -f /tmp/swap-stored-window ]; then
    notify-send "No window stored" "Mark a window first" -t 2000
    echo "No stored window found" >> /tmp/swap-debug.log
    exit 1
fi

# Read stored window
read start_window start_x start_y < /tmp/swap-stored-window

# Get current window
end_window=$(hyprctl activewindow -j | jq -r '.address')
end_x=$(hyprctl activewindow -j | jq -r '.at[0]')
end_y=$(hyprctl activewindow -j | jq -r '.at[1]')

echo "Start window: $start_window at ($start_x, $start_y)" >> /tmp/swap-debug.log
echo "End window: $end_window at ($end_x, $end_y)" >> /tmp/swap-debug.log

# If we're on a different window
if [ "$start_window" != "$end_window" ] && [ -n "$end_window" ] && [ "$end_window" != "null" ]; then
    echo "Attempting swap..." >> /tmp/swap-debug.log
    
    # Calculate direction
    x_diff=$((end_x - start_x))
    y_diff=$((end_y - start_y))
    
    # Determine primary direction
    if [ ${x_diff#-} -gt ${y_diff#-} ]; then
        # Horizontal movement is larger
        if [ $x_diff -gt 0 ]; then
            direction="r"
        else
            direction="l"
        fi
    else
        # Vertical movement is larger
        if [ $y_diff -gt 0 ]; then
            direction="d"
        else
            direction="u"
        fi
    fi
    
    echo "Direction: $direction" >> /tmp/swap-debug.log
    
    # Focus the original window first
    hyprctl dispatch focuswindow address:$start_window
    sleep 0.05
    # Then swap in the calculated direction
    hyprctl dispatch swapwindow $direction
    
    # Clean up stored window
    rm /tmp/swap-stored-window
    
    notify-send "Windows swapped" -t 1000
else
    echo "Same window, no swap needed" >> /tmp/swap-debug.log
    notify-send "Cannot swap" "Same window selected" -t 2000
fi

echo "Script finished" >> /tmp/swap-debug.log
