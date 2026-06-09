-- ============================================================================
-- Hyprland Lua binds (Hyprland 0.55+)
-- FAST
-- Requires on PATH: hyprctl, jq, bash (jq is only used by the selection helpers).
-- ============================================================================
local mainMod = "SUPER"
-- ============================================================================
-- HARDWARE KEYS
-- ============================================================================

hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%+"),
	{ repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%-"),
	{ repeating = true }
)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 10%+"), { repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 10%-"), { repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))
hl.bind("XF86WLAN", hl.dsp.exec_cmd("nmcli radio wifi toggle"))
hl.bind("XF86Refresh", hl.dsp.exec_cmd("xdotool key F5"))

-- ============================================================================
-- LAUNCHERS & SHELL HELPERS
-- ============================================================================

-- Kitty (single instance)
hl.bind(mainMod .. " + ESCAPE", hl.dsp.exec_cmd("kitty --single-instance"))

-- Rofi
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("bash ~/.config/rofi/launchers/type-7/launcher.sh"))

-- CopyQ
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("copyq toggle"))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("kdeconnect-cli --send-clipboard -n Shayans-Desktop"))

-- Popup terminal / Vivaldi-profile picker script (VP)
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("kitty --class=popup_term -e bash ~/.local/bin/VP"))

-- Waybar: tap = SIGUSR1 reload; hold = full reload
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("killall -SIGUSR1 waybar"), { release = true })
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("/home/shayan/.config/hypr/scripts/reload-waybar.sh"), { long_press = true })

-- Screen rotate
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("~/.config/hypr/scripts/rotate.sh"))

-- Screenshot: tap = screenshot, hold = OCR
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot_handler.sh hold"), { long_press = true })
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot_handler.sh release"), { release = true })

-- Region screenshot to swappy
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd([[grim -g "$(slurp)" - | swappy -f -]]))

-- Vivaldi vim-style passthrough
hl.bind("CTRL + J", hl.dsp.exec_cmd("~/.config/hypr/scripts/vimviva.sh Down Control_L j"), { repeating = true })
hl.bind("CTRL + K", hl.dsp.exec_cmd("~/.config/hypr/scripts/vimviva.sh Up   Control_L k"), { repeating = true })

-- Vivaldi: focus tab bar, then open tab context menu
hl.bind(
	mainMod .. " + X",
	hl.dsp.exec_cmd(
		[[hyprctl eval 'hl.dispatch(hl.dsp.send_shortcut({ mods = "CTRL ALT SHIFT", key = "I" }))' && hyprctl eval 'hl.dispatch(hl.dsp.send_shortcut({ mods = "SHIFT", key = "F10" }))']]
	)
)
-- Just context menu
hl.bind(
	mainMod .. " + SHIFT + X",
	hl.dsp.exec_cmd([[hyprctl eval 'hl.dispatch(hl.dsp.send_shortcut({ mods = "SHIFT", key = "F10" }))']])
)

-- Exit Hyprland (long press, so it can't be accidental)
hl.bind(mainMod .. " + N", hl.dsp.exit(), { long_press = true })

-- ============================================================================
-- WINDOW ACTIONS  (selection-aware)
-- ============================================================================

-- Close
-- hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("hyprsel action 'hl.dsp.window.close({ window = \"{}\" })'"))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("hyprsel action 'hl.dsp.window.close(\"{}\")'"))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("hyprsel action 'hl.dsp.window.close(\"{}\")'"))

-- Kill (long press, locked)
-- hl.bind(
-- 	mainMod .. " + C",
-- 	hl.dsp.exec_cmd("hyprsel action 'hl.dsp.window.kill({ window = \"{}\" })'"),
-- 	{ long_press = true, locked = true }
-- )
hl.bind(
	mainMod .. " + C",
	hl.dsp.exec_cmd("hyprsel action 'hl.dsp.window.kill(\"{}\")'"),
	{ long_press = true, locked = true }
)

-- Kill (long press)
hl.bind(
	mainMod .. " + Q",
	--hl.dsp.exec_cmd("hyprsel action 'hl.dsp.window.kill({ window = \"{}\" })'"),
	hl.dsp.exec_cmd("hyprsel action 'hl.dsp.window.kill(\"{}\")'"),
	{ long_press = true, locked = true }
)

-- Fullscreen maximize (mode = "maximized")
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "maximized" }))

-- Real fullscreen (long press)
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }), { long_press = true })

-- Swap with the next window in the layout.
-- (Not selection-aware: swapping a *group* of windows pairwise doesn't have
-- a meaningful interpretation.)
hl.bind(mainMod .. " + S", hl.dsp.window.swap({ next = true }))

-- ============================================================================
-- WORKSPACE NAVIGATION  (focus only - not selection-aware)
-- ============================================================================

-- Top-level: exact (relative across all workspaces, incl. empty)
hl.bind(mainMod .. " + L", hl.dsp.focus({ workspace = "r+1" }), { repeating = true })
hl.bind(mainMod .. " + H", hl.dsp.focus({ workspace = "r-1" }), { repeating = true })

-- ============================================================================
-- MOVE WINDOW TO ANOTHER WORKSPACE  (selection-aware)
-- ============================================================================

hl.bind(mainMod .. " + SHIFT + L", hl.dsp.exec_cmd("/home/shayan/.config/hypr/scripts/ws-move-next.sh"))
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.exec_cmd("/home/shayan/.config/hypr/scripts/ws-move-prev.sh"))

-- ============================================================================
-- RESIZE SUBMAP  (selection-aware)
-- ============================================================================
-- SUPER+R -> resize root. From there:
--   W -> Increase submap (HJKL grow on respective axis)
--   E -> Decrease submap (HJKL shrink on respective axis)
-- Escape returns one level; SUPER+R exits entirely.

hl.bind(mainMod .. " + R", hl.dsp.submap("resize"))

hl.define_submap("resize", function()
	hl.bind("W", hl.dsp.submap("Increase_size"))
	hl.bind("E", hl.dsp.submap("Decrease_size"))
	hl.bind("Escape", hl.dsp.submap("reset"))
end)

hl.define_submap("Increase_size", function()
	hl.bind(
		"H",
		hl.dsp.exec_cmd("hyprsel action 'hl.dsp.window.resize({ x = -20, y = 0, window = \"{}\",  relative = true })'"),
		{ repeating = true }
	)
	hl.bind(
		"L",
		hl.dsp.exec_cmd("hyprsel action 'hl.dsp.window.resize({ x = 20, y = 0, window = \"{}\", relative = true })'"),
		{ repeating = true }
	)
	hl.bind(
		"K",
		hl.dsp.exec_cmd("hyprsel action 'hl.dsp.window.resize({ x = 0, y = 20, window = \"{}\", relative = true })'"),
		{ repeating = true }
	)
	hl.bind(
		"J",
		hl.dsp.exec_cmd("hyprsel action 'hl.dsp.window.resize({ x = 0, y = -20, window = \"{}\", relative = true })'"),
		{ repeating = true }
	)
	hl.bind("Escape", hl.dsp.submap("resize"))
end)

hl.define_submap("Decrease_size", function()
	hl.bind(
		"H",
		hl.dsp.exec_cmd("hyprsel action 'hl.dsp.window.resize({ x = 20, y = 0, window = \"{}\", relative = true  })'"),
		{ repeating = true }
	)
	hl.bind(
		"L",
		hl.dsp.exec_cmd("hyprsel action 'hl.dsp.window.resize({ x = -20, y = 0, window = \"{}\", relative = true })'"),
		{ repeating = true }
	)
	hl.bind(
		"K",
		hl.dsp.exec_cmd("hyprsel action 'hl.dsp.window.resize({ x = 0, y = -20, window = \"{}\", relative = true })'"),
		{ repeating = true }
	)
	hl.bind(
		"J",
		hl.dsp.exec_cmd("hyprsel action 'hl.dsp.window.resize({ x = 0, y = 20, window = \"{}\", relative = true })'"),
		{ repeating = true }
	)
	hl.bind("Escape", hl.dsp.submap("resize"))
end)

-- ============================================================================
-- GROUP SUBMAP  (not selection-aware; groups are about the active window)
-- ============================================================================
-- SUPER+G ->
--   A -> create / toggle group
--   S -> lock active group (then exit submap)
--   D -> deny active window from being grouped
--   F -> next window in group

hl.bind(mainMod .. " + G", hl.dsp.submap("grouping"))

hl.define_submap("grouping", function()
	hl.bind("A", hl.dsp.group.toggle({}))
	hl.bind("S", function()
		hl.dispatch(hl.dsp.group.lock_active({}))
		hl.dispatch(hl.dsp.submap("reset"))
	end)
	hl.bind("D", hl.dsp.window.deny_from_group({}))
	hl.bind("F", hl.dsp.group.next({}))
	hl.bind("Escape", hl.dsp.submap("reset"))
end)

-- ============================================================================
-- NAVIGATION SUBMAP  (focus only; never selection-aware)
-- ============================================================================
-- SUPER+ALT ->
--   S -> special workspace: extra
--   D -> special workspace: dashboard
--   F -> enter focus submap (HJKL directional focus)
--   H/L -> workspace m-1 / m+1 (only existing workspaces on this monitor)
--   1-9, 0 -> workspace 1-9, 10

hl.bind(mainMod .. " + Alt_L", hl.dsp.submap("navigation"))

hl.define_submap("navigation", function()
	hl.bind("S", function()
		hl.dispatch(hl.dsp.exec_cmd("~/.config/hypr/scripts/gotospecial.sh extra"))
		hl.dispatch(hl.dsp.submap("reset"))
	end)
	hl.bind("D", function()
		hl.dispatch(hl.dsp.exec_cmd("~/.config/hypr/scripts/gotospecial.sh dashboard"))
		hl.dispatch(hl.dsp.submap("reset"))
	end)
	hl.bind("F", hl.dsp.submap("focus"))
	hl.bind("L", hl.dsp.focus({ workspace = "m+1" }), { repeating = true })
	hl.bind("H", hl.dsp.focus({ workspace = "m-1" }), { repeating = true })
	for i = 1, 9 do
		local n = i
		hl.bind(tostring(n), function()
			hl.dispatch(hl.dsp.focus({ workspace = n }))
			hl.dispatch(hl.dsp.submap("reset"))
		end)
	end
	hl.bind("0", function()
		hl.dispatch(hl.dsp.focus({ workspace = 10 }))
		hl.dispatch(hl.dsp.submap("reset"))
	end)
	hl.bind("Escape", hl.dsp.submap("reset"))
	hl.bind(mainMod .. " + ALT", hl.dsp.submap("reset"))
end)

hl.define_submap("focus", function()
	hl.bind("H", hl.dsp.focus({ direction = "l" }), { repeating = true })
	hl.bind("J", hl.dsp.focus({ direction = "d" }), { repeating = true })
	hl.bind("K", hl.dsp.focus({ direction = "u" }), { repeating = true })
	hl.bind("L", hl.dsp.focus({ direction = "r" }), { repeating = true })
	hl.bind("Escape", hl.dsp.submap("navigation"))
end)

-- ============================================================================
-- MOVEMENT SUBMAP  (selection-aware where it makes sense)
-- ============================================================================
-- SUPER+Z ->
--   S -> move window(s) to special:extra
--   D -> move window(s) to special:dashboard
--   H/L -> move to relative workspace on this monitor
--   1-9, 0 -> move to workspace N
--   I -> move into adjacent group (rightward)
--   O -> move out of group

hl.bind(mainMod .. " + Control_L", hl.dsp.submap("movement"))

hl.define_submap("movement", function()
	hl.bind("S", function()
		hl.dispatch(hl.dsp.exec_cmd("~/.config/hypr/scripts/movetospecial.sh extra"))
		hl.dispatch(hl.dsp.submap("reset"))
	end)
	hl.bind("D", function()
		hl.dispatch(hl.dsp.exec_cmd("~/.config/hypr/scripts/movetospecial.sh dashboard"))
		hl.dispatch(hl.dsp.submap("reset"))
	end)
	hl.bind("L", hl.dsp.exec_cmd("hyprsel action hl.dsp.window.move({ workspace = 'm+1' })"))
	hl.bind("H", hl.dsp.exec_cmd("hyprsel action hl.dsp.window.move({ workspace = 'm-1' })"))
	for i = 1, 9 do
		local n = i
		hl.bind(tostring(n), function()
			sel_move_to_ws(tostring(n))()
			hl.dispatch(hl.dsp.submap("reset"))
		end)
	end
	hl.bind("0", function()
		sel_move_to_ws("10")()
		hl.dispatch(hl.dsp.submap("reset"))
	end)
	-- Group in/out are about the active window's relationship to a group;
	-- multi-window doesn't have a clean interpretation, so we leave these
	-- single-target.
	hl.bind("I", hl.dsp.window.move({ into_group = "r" }))
	hl.bind("O", hl.dsp.window.move({ out_of_group = true }))
	hl.bind("Escape", hl.dsp.submap("reset"))
end)

-- ============================================================================
-- PROPERTIES SUBMAP  (selection-aware where it makes sense)
-- ============================================================================
-- SUPER+P ->
--   T -> toggle pin
--   S -> toggle layout split direction (layout-level, not per-window)
--   F -> toggle floating
--   P -> toggle pseudo-tiling

hl.bind(mainMod .. " + P", hl.dsp.submap("properties"))

hl.define_submap("properties", function()
	hl.bind("T", hl.dsp.exec_cmd("hyprsel action 'hl.dsp.window.pin({ window = \"{}\" })'"))
	hl.bind("S", hl.dsp.layout("togglesplit")) -- not per-window
	hl.bind("F", hl.dsp.exec_cmd('hyprsel action \'hl.dsp.window.float({ action = "toggle", window = "{}" })\''))
	hl.bind("P", hl.dsp.exec_cmd('hyprsel action \'hl.dsp.window.pseudo({ action = "toggle", window = "{}" })\''))
	hl.bind("Escape", hl.dsp.submap("reset"))
end)

-- ============================================================================
-- TAG SUBMAP  (the selection itself - not wrapped)
-- ============================================================================
-- SUPER+T ->
--   S -> add the active window to the selection (idempotent)
--   D -> clear ALL tags from the active window
--        (matches your old D behavior; gets the window completely out of
--         both "selected" and "prev_selected")
--   R -> restore the previous selection: prev_selected -> selected
--   X -> clear the "selected" tag from every window (drop the whole batch
--        without acting on it)

hl.bind(mainMod .. " + T", hl.dsp.submap("tagging"))

hl.define_submap("tagging", function()
	-- Add to selection. "+" prefix means "add if not present" so pressing
	-- S twice on the same window is a no-op rather than a toggle, which is
	-- usually what you want when building up a set.
	hl.bind("S", function()
		hl.dispatch(hl.dsp.window.tag({ tag = "+selected" }))
	end)

	-- Clear all tags from the active window (kills both selected and prev_selected on it).
	hl.bind("D", function()
		hl.dispatch(hl.dsp.window.clear_tags({}))
	end)

	-- Re-select: take whatever currently has "prev_selected" and turn it
	-- back into "selected". We clear the existing "selected" set first so
	-- the restored selection is the only one active.
	hl.bind("R", function()
		clear_tag_everywhere("selected")
		local addrs = addresses_with_tag("prev_selected")
		rotate_addresses(addrs, "prev_selected", "selected")
	end)

	-- Drop the whole live selection without performing an action.
	hl.bind("X", function()
		clear_tag_everywhere("selected")
	end)

	hl.bind("Escape", hl.dsp.submap("reset"))
end)

-- ============================================================================
-- MOUSE
-- ============================================================================

hl.bind("SUPER + Control_L", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "m-1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "m+1" }))
