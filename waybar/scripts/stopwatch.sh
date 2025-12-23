#!/bin/bash
# Waybar Stopwatch Module
# Save as: ~/.config/waybar/scripts/stopwatch.sh

STOPWATCH_FILE="/tmp/waybar-stopwatch"

case "$1" in
    "start")
        # Check if stopwatch is running
        if [ -f "$STOPWATCH_FILE" ]; then
            # Calculate elapsed time
            start_time=$(cat "$STOPWATCH_FILE")
            current_time=$(date +%s.%N)
            elapsed=$(echo "$current_time - $start_time" | bc)
            
            # Convert to hours, minutes, seconds
            hours=$(echo "$elapsed / 3600" | bc)
            minutes=$(echo "($elapsed % 3600) / 60" | bc)
            seconds=$(echo "$elapsed % 60" | bc)
            
            # Format output
            if [ "$hours" -gt 0 ]; then
                time_str=$(printf "%02d:%02d:%02d" "$hours" "$minutes" "$seconds")
            elif [ "$minutes" -gt 0 ]; then
                time_str=$(printf "%02d:%02d" "$minutes" "$seconds")
            else
                time_str=$(printf "%02d" "$seconds")
            fi
            
            echo "{\"text\":\"󱦟 $time_str\"}"
        else
            # Stopwatch not running
            echo '{"text":"󰚭 00"}'
        fi
        ;;
        
    "toggle"|"restart")
        # Toggle stopwatch on/off
        if [ -f "$STOPWATCH_FILE" ]; then
            rm "$STOPWATCH_FILE"
            echo '{"text":"󰚭 00"}'
        else
            date +%s.%N > "$STOPWATCH_FILE"
            echo '{"text":"󱦟 00"}'
        fi
        ;;
        
    "reset")
        # Reset stopwatch
        rm -f "$STOPWATCH_FILE"
        echo '{"text":"󰚭 00"}'
        ;;
        
    *)
        echo '{"text":"ERROR"}'
        ;;
esac
