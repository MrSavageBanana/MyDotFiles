#!/bin/bash
SPECIAL="$1"
VISIBLE_WORKSPACE=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true).activeWorkspace.name')
ACTIVEWORKSPACE=$(hyprctl activewindow -j | jq -r '.workspace.name')
DOES_SPECIAL_EXIST=$(hyprctl workspaces | grep "special:$SPECIAL")

echo "$VISIBLE_WORKSPACE"
echo "$ACTIVEWORKSPACE"
echo "$DOES_SPECIAL_EXIST"

if [[ -z "$DOES_SPECIAL_EXIST" ]]; then # special does not exist
    hyprctl dispatch workspace "$VISIBLE_WORKSPACE"
    notify-send "$SPECIAL does not exist" --urgency low --expire-time 1500
elif [[ "$ACTIVEWORKSPACE" == "special:$SPECIAL" ]]; then 
    hyprctl dispatch workspace "$VISIBLE_WORKSPACE"
    hyprctl dispatch togglespecialworkspace "$SPECIAL"
    echo "active workspace is special workspace"
else
    hyprctl dispatch workspace "special:$SPECIAL"
    "special exists and active workspace isn't special"
fi
