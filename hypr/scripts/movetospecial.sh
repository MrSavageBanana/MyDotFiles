#!/bin/bash
CHOSEN_WORKSPACE="$1"
VISIBLE_WORKSPACE=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true).activeWorkspace.name')
ACTIVEWORKSPACE=$(hyprctl activewindow -j | jq -r '.workspace.name')
if [[ "$VISIBLE_WORKSPACE" == "$ACTIVEWORKSPACE" ]] ; then
	hyprctl dispatch "hl.dsp.window.move({ workspace = 'special:$CHOSEN_WORKSPACE' })"
else
	hyprctl dispatch "hl.dsp.window.move({ workspace = '$VISIBLE_WORKSPACE' })"
fi 
