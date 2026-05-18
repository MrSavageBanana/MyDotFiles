-- created with Claude. Account: Milobowler
-- See https://wiki.hypr.land/Configuring/Basics/Binds/
--     https://wiki.hypr.land/Configuring/Basics/Dispatchers/
--
-- OLD FLAG → NEW OPTION TABLE:
--   bind   (no flags)   → hl.bind(key, dsp)
--   binde  (repeat)     → hl.bind(key, dsp, { repeating = true })
--   bindr  (release)    → hl.bind(key, dsp, { release = true })
--   bindo  (long press) → hl.bind(key, dsp, { long_press = true })
--   bindol (LP+locked)  → hl.bind(key, dsp, { long_press = true, locked = true })
--   bindl  (locked)     → hl.bind(key, dsp, { locked = true })
--   bindm  (mouse)      → hl.bind(key, dsp, { mouse = true })
--
-- NOTE: Dispatchers marked "--TODO" use hyprctl as a safe fallback because
--       their exact hl.dsp.* name wasn't confirmed in the 0.55 docs at time
--       of writing. Replace them with native dispatchers if/when you find them.

local mainMod = "SUPER"

-- ─── Basic Actions ─────────────────────────────────────────────────────────

-- Open kitty (repeat = hold to keep spawning)
hl.bind(mainMod .. " + ESCAPE", hl.dsp.exec_cmd("kitty --single-instance"), { repeating = true })
hl.bind(mainMod .. " + Z",      hl.dsp.exec_cmd("kitty --single-instance"), { repeating = true })

-- Quick-access terminal (kitten)
hl.bind(mainMod .. " + SHIFT + ESCAPE", hl.dsp.exec_cmd("kitten quick_access_terminal"))

-- Popup terminal / VP script
hl.bind(mainMod .. " + A",
    hl.dsp.exec_cmd("kitty --class=popup_term -e bash /home/shayan/.local/bin/VP"))

-- Close / force-kill window
-- Short press → close; long press → force kill
hl.bind(mainMod .. " + Q", hl.dsp.window.kill(),  { long_press = true })
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + C", hl.dsp.window.kill(),  { long_press = true, locked = true })

-- Exit Hyprland (long press)
hl.bind(mainMod .. " + M", hl.dsp.exit(), { long_press = true })

-- Fullscreen: short press = fake fullscreen (mode 1), long press = real fullscreen
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = 1 }))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen(),              { long_press = true })

-- Rofi launcher
hl.bind(mainMod .. " + SPACE",
    hl.dsp.exec_cmd("bash /home/shayan/.config/rofi/launchers/type-7/launcher.sh"))

-- Pseudotile toggle (SUPER+G)
-- TODO: verify hl.dsp.window.pseudo() exists, or keep hyprctl fallback
hl.bind(mainMod .. " + G",
    hl.dsp.exec_cmd("hyprctl dispatch pseudo active"))

-- Pin (release) / togglefloating (long press) on SUPER+T
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("hyprctl dispatch pin"),   { release = true })   -- TODO: hl.dsp.window.pin()?
hl.bind(mainMod .. " + T", hl.dsp.window.float({ action = "toggle" }), { long_press = true })

-- Waybar: short press (release) = SIGUSR1 reload; long press = full reload
hl.bind(mainMod .. " + B",
    hl.dsp.exec_cmd("killall -SIGUSR1 waybar"), { release = true })
hl.bind(mainMod .. " + B",
    hl.dsp.exec_cmd("~/.config/ml4w/scripts/reload-waybar.sh"), { long_press = true })

-- Clipboard (CopyQ)
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("copyq toggle"))
hl.bind(mainMod .. " + SHIFT + V",
    hl.dsp.exec_cmd("kdeconnect-cli --send-clipboard -n Shayans-Desktop"))

-- Screen rotate
hl.bind(mainMod .. " + SHIFT + R",
    hl.dsp.exec_cmd("/home/shayan/.config/hypr/scripts/rotate.sh"))

-- Send right-arrow shortcut (Vivaldi tab nav etc.), repeating
hl.bind(mainMod .. " + TAB",
    hl.dsp.exec_cmd("hyprctl dispatch sendshortcut ',right,'"), { repeating = true })

-- ─── Audio / Brightness / Hardware Keys ────────────────────────────────────

hl.bind("XF86AudioRaiseVolume",
    hl.dsp.exec_cmd("wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%+"))
hl.bind("XF86AudioLowerVolume",
    hl.dsp.exec_cmd("wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%-"))
hl.bind("XF86MonBrightnessUp",
    hl.dsp.exec_cmd("brightnessctl set 10%+"))
hl.bind("XF86MonBrightnessDown",
    hl.dsp.exec_cmd("brightnessctl set 10%-"))
hl.bind("XF86AudioMute",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
hl.bind("XF86AudioMicMute",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))
hl.bind("XF86WLAN",
    hl.dsp.exec_cmd("nmcli radio wifi toggle"))
hl.bind("XF86Refresh",
    hl.dsp.exec_cmd("xdotool key F5"))

-- ─── Vim-style Navigation ──────────────────────────────────────────────────

-- Workspace prev/next (SUPER + h/l)
hl.bind(mainMod .. " + H",
    hl.dsp.exec_cmd("~/.config/hypr/scripts/workspace_nav.sh prev"), { repeating = true })
hl.bind(mainMod .. " + L",
    hl.dsp.exec_cmd("~/.config/hypr/scripts/workspace_nav.sh next"), { repeating = true })

-- Move window to prev/next workspace (SUPER + SHIFT + h/l)
hl.bind(mainMod .. " + SHIFT + H",
    hl.dsp.exec_cmd("~/.config/hypr/scripts/ws-move-prev.sh"), { repeating = true })
hl.bind(mainMod .. " + SHIFT + L",
    hl.dsp.exec_cmd("~/.config/hypr/scripts/ws-move-next.sh"), { repeating = true })

-- Move focus (SUPER + ALT + hjkl) -- TODO: replace with hl.dsp.window.focus_direction() if available
hl.bind(mainMod .. " + ALT + H",
    hl.dsp.exec_cmd("hyprctl dispatch movefocus l"), { repeating = true })
hl.bind(mainMod .. " + ALT + J",
    hl.dsp.exec_cmd("hyprctl dispatch movefocus d"), { repeating = true })
hl.bind(mainMod .. " + ALT + K",
    hl.dsp.exec_cmd("hyprctl dispatch movefocus u"), { repeating = true })
hl.bind(mainMod .. " + ALT + L",
    hl.dsp.exec_cmd("hyprctl dispatch movefocus r"), { repeating = true })

-- Move window (SUPER + CTRL + hjkl) -- TODO: replace with hl.dsp.window.move({ direction = }) if available
hl.bind(mainMod .. " + CTRL + H",
    hl.dsp.exec_cmd("hyprctl dispatch movewindow l"), { repeating = true })
hl.bind(mainMod .. " + CTRL + J",
    hl.dsp.exec_cmd("hyprctl dispatch movewindow d"), { repeating = true })
hl.bind(mainMod .. " + CTRL + K",
    hl.dsp.exec_cmd("hyprctl dispatch movewindow u"), { repeating = true })
hl.bind(mainMod .. " + CTRL + L",
    hl.dsp.exec_cmd("hyprctl dispatch movewindow r"), { repeating = true })

-- Vimviva passthrough (CTRL + J/K — passes to Vivaldi/CopyQ, or forwards as CTRL in other apps)
hl.bind("CTRL + J",
    hl.dsp.exec_cmd("~/.config/hypr/scripts/vimviva.sh Down Control_L j"), { repeating = true })
hl.bind("CTRL + K",
    hl.dsp.exec_cmd("~/.config/hypr/scripts/vimviva.sh Up Control_L k"),   { repeating = true })

-- ─── Resize Submap ─────────────────────────────────────────────────────────

hl.bind(mainMod .. " + R", hl.dsp.submap("resize"))

hl.define_submap("resize", function()
    hl.bind("H", hl.dsp.window.resize({ x = -20, y = 0,  relative = true }), { repeating = true })
    hl.bind("L", hl.dsp.window.resize({ x = 20,  y = 0,  relative = true }), { repeating = true })
    hl.bind("K", hl.dsp.window.resize({ x = 0,   y = -20, relative = true }), { repeating = true })
    hl.bind("J", hl.dsp.window.resize({ x = 0,   y = 20,  relative = true }), { repeating = true })
    -- Exit submap
    hl.bind("escape",         hl.dsp.submap("reset"))
    hl.bind(mainMod .. " + R", hl.dsp.submap("reset"))
end)

-- ─── Special Workspaces ────────────────────────────────────────────────────

hl.bind(mainMod .. " + S",
    hl.dsp.exec_cmd("~/.config/hypr/scripts/gotospecial.sh extra"))
hl.bind(mainMod .. " + D",
    hl.dsp.exec_cmd("~/.config/hypr/scripts/gotospecial.sh dashboard"))
hl.bind(mainMod .. " + SHIFT + D",
    hl.dsp.exec_cmd("~/.config/hypr/scripts/movetospecial.sh special:dashboard"))
hl.bind(mainMod .. " + SHIFT + S",
    hl.dsp.exec_cmd("~/.config/hypr/scripts/movetospecial.sh special:extra"))

-- ─── Workspace Switching (1-10) ────────────────────────────────────────────

for i = 1, 9 do
    hl.bind(mainMod .. " + " .. i, hl.dsp.workspace.change(i))
    hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mainMod .. " + 0", hl.dsp.workspace.change(10))
hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))

-- ─── Numpad Workspace Switching ────────────────────────────────────────────

local numpad_keys = {
    "KP_End", "KP_Down", "KP_Next", "KP_Left", "KP_Begin",
    "KP_Right", "KP_Home", "KP_Up", "KP_Prior", "KP_Insert",
}
for i, key in ipairs(numpad_keys) do
    hl.bind(mainMod .. " + " .. key, hl.dsp.workspace.change(i))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- ─── Move / Resize Windows with Mouse ─────────────────────────────────────

-- SUPER + CTRL + LMB = drag to move window
-- TODO: verify mouse bind syntax — check wiki for hl.bind mouse options
hl.bind(mainMod .. " + CTRL", hl.dsp.exec_cmd("hyprctl dispatch movewindow"), { mouse = true })

-- ─── Screenshots ───────────────────────────────────────────────────────────

-- SUPER + W: hold = OCR, release = screenshot (handled by the bash script)
hl.bind(mainMod .. " + W",
    hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot_handler.sh hold"),    { long_press = true })
hl.bind(mainMod .. " + W",
    hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot_handler.sh release"), { release = true })

-- SUPER + SHIFT + W: capture region → swappy
hl.bind(mainMod .. " + SHIFT + W",
    hl.dsp.exec_cmd('grim -g "$(slurp)" - | swappy -f -'))

-- ─── Vivaldi Tab Bar ───────────────────────────────────────────────────────

-- SUPER+X: focus tab bar then open context menu
hl.bind(mainMod .. " + X",
    hl.dsp.exec_cmd('hyprctl dispatch sendshortcut "CTRL ALT SHIFT,I,activewindow" && hyprctl dispatch sendshortcut "SHIFT,F10,activewindow"'))

-- SUPER+SHIFT+X: context menu only
hl.bind(mainMod .. " + SHIFT + X",
    hl.dsp.exec_cmd('hyprctl dispatch sendshortcut "SHIFT,F10,activewindow"'))
