#!/bin/bash
# SPECIAL="$1"
# VISIBLE_WORKSPACE=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true).activeWorkspace.name')
# ACTIVEWORKSPACE=$(hyprctl activewindow -j | jq -r '.workspace.name')
# DOES_SPECIAL_EXIST=$(hyprctl workspaces | grep "special:$SPECIAL")
# 
# if [[ -z "$DOES_SPECIAL_EXIST" ]]; then # special does not exist
#     hyprctl eval "hl.dispatch(hl.dsp.focus({ workspace = '$VISIBLE_WORKSPACE' }))"
#     notify-send "$SPECIAL does not exist" --urgency low --expire-time 1500
# elif [[ "$ACTIVEWORKSPACE" == "special:$SPECIAL" ]]; then 
#     hyprctl eval "hl.dispatch(hl.dsp.focus({ workspace = $VISIBLE_WORKSPACE ; }))"
#     echo "active workspace is special workspace"
# else
#     hyprctl eval "hl.dispatch(hl.dsp.focus({ workspace = 'special:$SPECIAL' }))"
#     notify-send "special exists and active workspace isn't special"
# fi
#!/bin/bash
SPECIAL="$1"
VISIBLE_WORKSPACE=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true).activeWorkspace.name')
ACTIVEWORKSPACE=$(hyprctl activewindow -j | jq -r '.workspace.name')
DOES_SPECIAL_EXIST=$(hyprctl workspaces | grep "special:$SPECIAL")

if [[ -z "$DOES_SPECIAL_EXIST" ]]; then
    hyprctl dispatch "hl.dsp.focus({ workspace = '$VISIBLE_WORKSPACE' })"
    notify-send "$SPECIAL does not exist" --urgency low --expire-time 1500
elif [[ "$ACTIVEWORKSPACE" == "special:$SPECIAL" ]]; then
    # On the special, focus the regular workspace to hide it
    hyprctl dispatch "hl.dsp.workspace.toggle_special('$SPECIAL')"
    # notify-send "active workspace is special workspace"
else
    # Special exists but isn't active, focus it
    hyprctl dispatch "hl.dsp.focus({ workspace = 'special:$SPECIAL' })"
    # notify-send "special exists and active workspace isn't special"
fi
