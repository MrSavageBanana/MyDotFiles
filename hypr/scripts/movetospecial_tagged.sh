#!/bin/bash
# created with Claude. Account: Milobowler
#
# movetospecial_tagged.sh <workspace>
#
# Selection-aware move-to-special with toggle. Reads native Hyprland tags
# directly via hyprctl — no hyprsel daemon required.
#
# Batch path  (one or more windows are tagged "selected"):
#   Move every tagged window to special:<workspace>. Active window is included
#   if it is tagged; the toggle check is skipped entirely for batch ops.
#
# Single path  (no tagged windows):
#   Toggle the active window exactly like the original movetospecial.sh:
#     - Active window is on the visible workspace  →  send to special:<workspace>
#     - Active window is elsewhere (already in special)  →  pull back to visible

CHOSEN_WORKSPACE="$1"
VISIBLE_WORKSPACE=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true).activeWorkspace.name')

# Collect addresses of all windows that carry the "selected" tag.
# hyprctl clients -j returns addresses as "0x<hex>"; we prepend "address:" for dispatch.
TAGGED_ADDRS=$(hyprctl clients -j | jq -r \
    '.[] | select((.tags // []) | any(. == "selected")) | .address')

if [[ -n "$TAGGED_ADDRS" ]]; then
    # ── Batch path ────────────────────────────────────────────────────────────
    while IFS= read -r addr; do
        hyprctl dispatch \
            "hl.dsp.window.move({ workspace = 'special:$CHOSEN_WORKSPACE', window = 'address:$addr' })"
    done <<< "$TAGGED_ADDRS"
else
    # ── Single / toggle path ──────────────────────────────────────────────────
    ACTIVE_WORKSPACE=$(hyprctl activewindow -j | jq -r '.workspace.name')
    if [[ "$VISIBLE_WORKSPACE" == "$ACTIVE_WORKSPACE" ]]; then
        hyprctl dispatch "hl.dsp.window.move({ workspace = 'special:$CHOSEN_WORKSPACE' })"
    else
        hyprctl dispatch "hl.dsp.window.move({ workspace = '$VISIBLE_WORKSPACE' })"
    fi
fi
