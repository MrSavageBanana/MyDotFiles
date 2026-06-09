#!/usr/bin/env bash
VIVALDI_KEY="$1"
PASSTHROUGH_MOD="$2"
PASSTHROUGH_KEY="$3"

ACTIVE_CLASS=$(hyprctl activewindow -j | jq -r '.class')

if [[ "$ACTIVE_CLASS" == "vivaldi-stable" || "$ACTIVE_CLASS" == "com.github.hluk.copyq" || "$ACTIVE_CLASS" == "firefox" || "$ACTIVE_CLASS" == "org.gnome.Meld" ]]; then
    hyprctl eval "hl.dispatch(hl.dsp.send_shortcut({ mods = 'NONE', key = '$VIVALDI_KEY' }))"
else
    hyprctl eval "hl.dispatch(hl.dsp.send_shortcut({ mods = '$PASSTHROUGH_MOD', key = '$PASSTHROUGH_KEY' }))"
fi

