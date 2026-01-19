#!/usr/bin/env bash

current=$(hyprctl activeworkspace -j | jq '.id')
max=$(hyprctl workspaces -j | jq '.[].id' | sort -n | tail -1)

if [ "$current" -lt "$max" ]; then
  hyprctl dispatch workspace m+1
else
  hyprctl dispatch workspace $((max + 1))
fi

