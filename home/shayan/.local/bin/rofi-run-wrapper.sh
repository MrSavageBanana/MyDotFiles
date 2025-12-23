#!/usr/bin/env bash
# ~/.local/bin/rofi-run-wrapper.sh
STATUS_FILE="/tmp/rofi_status"

# Indicate launch started
echo "launching" > "$STATUS_FILE"

# Launch app
"$@" & disown

# Background watcher: wait for new window, then clear status
(
    before=$(hyprctl clients | grep "Window" | wc -l)
    for i in {1..20}; do
        sleep 0.25
        now=$(hyprctl clients | grep "Window" | wc -l)
        if [ "$now" -gt "$before" ]; then
            rm -f "$STATUS_FILE"
            exit 0
        fi
    done
    # fallback: clear status anyway
    rm -f "$STATUS_FILE"
) &

exit 0
