#!/bin/bash
sash=$(hyprctl monitors | sed --quiet '12p' | sed -e 's/transform: //g' | sed -e 's/	//g') 

if [[ $sash == 0 ]]; then
	hyprctl eval 'hl.monitor({ output = "eDP-1", mode = "1920x1080@60", position = "0x0", transform = 2})'
elif [[ $sash == 2 ]]; then
	hyprctl eval 'hl.monitor({ output = "eDP-1", mode = "1920x1080@60", position = "0x0", transform = 0})'
else
	hyprctl eval 'hl.monitor({ output = "eDP-1", mode = "1920x1080@60", position = "0x0", transform = 0})'
fi
