#!/usr/bin/env bash

current=$(hyprctl activeworkspace -j | jq '.id')
max=$(hyprctl workspaces -j | jq '.[].id' | sort -n | tail -1)

if [ "$current" -lt "$max" ]; then
  hyprctl dispatch movetoworkspace m+1
else
  hyprctl dispatch movetoworkspace $((max + 1))
fi

