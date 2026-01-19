#!/usr/bin/env bash

current=$(hyprctl activeworkspace -j | jq '.id')
min=$(hyprctl workspaces -j | jq '.[].id' | sort -n | head -1)

if [ "$current" -gt "$min" ]; then
  hyprctl dispatch workspace m-1
else
  hyprctl dispatch workspace "$min"
fi

