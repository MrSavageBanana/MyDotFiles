#!/usr/bin/env bash
VIVALDI_KEY="$1"
PASSTHROUGH_KEY="$2"

ACTIVE_CLASS=$(hyprctl activewindow -j | jq -r '.class')

if [[ "$ACTIVE_CLASS" == "vivaldi-stable" || "$ACTIVE_CLASS" == "com.github.hluk.copyq" ]]; then
    hyprctl dispatch sendshortcut ",$VIVALDI_KEY,"
else
    wtype -M ctrl -P "$PASSTHROUGH_KEY" -m ctrl -p "$PASSTHROUGH_KEY"
fi
