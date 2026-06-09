#!/usr/bin/env bash

current=$(hyprctl activeworkspace -j | jq '.id')
max=$(hyprctl workspaces -j | jq '.[].id' | sort -n | tail -1)

if [ "$current" -lt "$max" ]; then
  hyprctl eval "hl.dispatch(hl.dsp.window.move({ workspace = 'm+1' }))"
else
  hyprctl eval "hl.dispatch(hl.dsp.window.move({ workspace = $((max + 1)) }))"
fi

