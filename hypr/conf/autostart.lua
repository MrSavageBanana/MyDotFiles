-- created with Claude. Account: Milobowler
-- Autostart applications — runs once at session start, not on config reload.

hl.on("hyprland.start", function()
    hl.dispatch(hl.dsp.exec_cmd("waybar"))
    hl.dispatch(hl.dsp.exec_cmd("hyprpaper"))
    hl.dispatch(hl.dsp.exec_cmd("dunst"))
    hl.dispatch(hl.dsp.exec_cmd("kitty"))

    -- Special dashboard workspace (silent = no focus steal)
    hl.dispatch(hl.dsp.exec_cmd(
        "[workspace special:dashboard silent] kitty --session /home/shayan/.config/kitty/sessions/dhsajfhadsfh.kitty-session"
    ))

    hl.dispatch(hl.dsp.exec_cmd("copyq"))
    hl.dispatch(hl.dsp.exec_cmd("/home/shayan/.config/waybar/scripts/waybar_timer serve"))
    hl.dispatch(hl.dsp.exec_cmd("/home/shayan/.config/hypr/scripts/window-focus-monitor.sh"))
    hl.dispatch(hl.dsp.exec_cmd(
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
    ))
    hl.dispatch(hl.dsp.exec_cmd("python3 /home/shayan/Downloads/VivaldiCSS/hypr_pos.py"))
end)
