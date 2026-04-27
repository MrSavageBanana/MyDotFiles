#!/usr/bin/env bash
VIVALDI_KEY="$1"
PASSTHROUGH_MOD="$2"
PASSTHROUGH_KEY="$3"

ACTIVE_CLASS=$(hyprctl activewindow -j | jq -r '.class')

if [[ "$ACTIVE_CLASS" == "vivaldi-stable" || "$ACTIVE_CLASS" == "com.github.hluk.copyq" || "$ACTIVE_CLASS" == "firefox" ]]; then
    hyprctl dispatch sendshortcut ",$VIVALDI_KEY,"
else
    hyprctl dispatch sendshortcut "$PASSTHROUGH_MOD,$PASSTHROUGH_KEY,"
fi

