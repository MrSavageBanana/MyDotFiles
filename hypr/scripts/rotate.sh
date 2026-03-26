#!/bin/bash
sash=$(hyprctl monitors | sed --quiet '12p' | sed -e 's/transform: //g' | sed -e 's/	//g') 

if [[ $sash == 0 ]]; then
	hyprctl keyword monitor "eDP-1,1920x1080@60,0x0,1,transform,2"
elif [[ $sash == 2 ]]; then
  	hyprctl keyword monitor "eDP-1,1920x1080@60,0x0,1,transform,0"
else
  	hyprctl keyword monitor "eDP-1,1920x1080@60,0x0,1,transform,0"
fi
