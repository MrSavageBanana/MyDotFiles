-- created with Claude. Account: Milobowler
-- See https://wiki.hypr.land/Configuring/Gestures/
-- NOTE: The gesture API changed in 0.55. The old "gesture = N, direction, action"
--       format maps to hl.gesture({}). The 4-finger movefocus gestures below use
--       exec_cmd as a safe fallback — check the wiki for a native dispatcher form.

-- 3-finger horizontal swipe = switch workspaces
hl.gesture({ fingers = 3, direction = "vertical", mods = "SUPER", scale = 10, action = "workspace" })
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 4, direction = "vertical", action = "fullscreen" })

-- 4-finger directional swipes = move focus
-- hl.gesture({ fingers = 4, direction = "left",  action = hl.dsp.exec_cmd("hyprctl dispatch movefocus l") })
-- hl.gesture({ fingers = 4, direction = "right", action = hl.dsp.exec_cmd("hyprctl dispatch movefocus r") })
-- hl.gesture({ fingers = 4, direction = "up",    action = hl.dsp.exec_cmd("hyprctl dispatch movefocus u") })
-- hl.gesture({ fingers = 4, direction = "down",  action = hl.dsp.exec_cmd("hyprctl dispatch movefocus d") })
