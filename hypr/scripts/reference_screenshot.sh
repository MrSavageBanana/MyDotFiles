#!/usr/bin/env bash

# 1. Define the function
wait_for_new_window() {
    local class_name="$1"
    local initial_count="$2"
    local max_attempts="$3"

    for _ in $(seq 1 "$max_attempts"); do
        local current_count
        current_count=$(hyprctl clients -j | grep -c '"class": "'"$class_name"'"')
        
        if (( current_count > initial_count )); then
            return 0 # Success
        fi
        sleep 0.1
    done
    return 1 # Timed out
}

# 2. Get geometry (exit if cancelled)
GEOM=$(slurp) || exit 1

# 3. Capture the baseline window count BEFORE launching anything
BASELINE_COUNT=$(hyprctl clients -j | grep -c '"class": "swappy"')

# 4. Launch grim and swappy in the background
grim -g "$GEOM" - | swappy -f - &

# 5. Call the function. If it succeeds (returns 0), trigger the submap
if wait_for_new_window "swappy" "$BASELINE_COUNT" 1000; then
	hyprctl eval 'hl.dispatch(hl.dsp.submap("movement"))'
fi
