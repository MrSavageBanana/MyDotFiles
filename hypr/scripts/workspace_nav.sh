#!/bin/bash
# Usage: workspace_nav.sh [prev|next|prev_occ|next_occ]

direction="$1"
current=$(hyprctl activeworkspace -j | jq '.id')

case "$direction" in
    prev)
        [[ "$current" -gt 1 ]] && hyprctl dispatch workspace "$((current - 1))"
        ;;
    next)
        hyprctl dispatch workspace "$((current + 1))"
        ;;
    prev_occ)
        target=$(hyprctl workspaces -j | jq --argjson cur "$current" '
            [.[] | select(.name | contains("-") | not) | .id]
            | map(select(. < $cur))
            | max // empty
        ')
        [[ -n "$target" && "$target" != "null" ]] && hyprctl dispatch workspace "$target"
        ;;
    next_occ)
        target=$(hyprctl workspaces -j | jq --argjson cur "$current" '
            [.[] | select(.name | contains("-") | not) | .id]
            | map(select(. > $cur))
            | min // empty
        ')
        [[ -n "$target" && "$target" != "null" ]] && hyprctl dispatch workspace "$target"
        ;;
esac
