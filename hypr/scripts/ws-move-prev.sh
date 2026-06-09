#!/usr/bin/env bash

current=$(hyprctl activeworkspace -j | jq '.id')
min=$(hyprctl workspaces -j | jq '.[].id' | sort -n | head -1)

if [ "$current" -gt "$min" ]; then
  hyprctl eval "hl.dispatch(hl.dsp.window.move({ workspace = 'm-1' }))"
else
  hyprctl eval "hl.dispatch(hl.dsp.window.move({ workspace = '$min' }))"
fi

