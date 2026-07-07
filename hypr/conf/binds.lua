-- ============================================================================
-- Hyprland Lua binds (Hyprland 0.55+)
-- FAST
-- Last Edited: Baba. Title: Window tagging system for batch actions
-- Edited Before: Milobowler. Title: Hyprsel action calls not working despite correct syntax
-- Requires on PATH: hyprctl, jq, bash (jq is only used by the selection helpers).
-- ============================================================================
-- created with Claude. Account: Milobowler
local mainMod = "SUPER"

-- ============================================================================
-- hyprsel HELPER  (Hyprland 0.55+ Lua dispatch syntax)
-- ============================================================================
-- Builds the shell command string passed to hl.dsp.exec_cmd() for any
-- hyprsel action call. {} in the resulting template is replaced by hyprsel
-- with the real window selector at runtime.
--
-- action       : hl.dsp.window sub-method, e.g. "close", "kill", "resize"
-- params       : extra Lua table fields before window, e.g. 'x = -20, y = 0, relative = true'
--                pass nil or "" to omit
-- multi_action : optional second method used when a multi-window selection is
--                active (defaults to action if nil)
-- multi_params : extra fields for the multi template (defaults to params if nil)
--
-- Examples:
--   hsel("close")
--   hsel("resize", "x = 20, y = 0, relative = true")
--   hsel("move", 'workspace = "m+1"', "move", 'workspace = "m+1", follow = false')
-- created with Claude. Account: Milobowler
-- local function hsel(action, params, multi_action, multi_params)
-- 	local function build(act, p)
-- 		if p and p ~= "" then
-- 			return "dispatch hl.dsp.window." .. act .. "({ " .. p .. ', window = "{}" })'
-- 		end
-- 		return "dispatch hl.dsp.window." .. act .. '({ window = "{}" })'
-- 	end
-- 	local s = build(action, params)
-- 	local m = build(multi_action or action, multi_params ~= nil and multi_params or params)
-- 	if multi_action then
-- 		return "hyprsel action '" .. s .. "' '" .. m .. "'"
-- 	end
-- 	return "hyprsel action '" .. s .. "'"
-- end
local function on_tag_group(action)
	local active = hl.get_active_window()
	if not active then
		return
	end -- no focused window: do nothing

	local active_tags = active.tags

	if #active_tags == 0 then
		action(active) -- untagged: act on this window only
		return
	end

	-- Build a fast O(1) lookup from the active window's tags
	local tag_set = {}
	for _, t in ipairs(active_tags) do
		tag_set[t] = true
	end

	-- Snapshot matches BEFORE acting to avoid mutation-during-iteration issues
	local targets = {}
	for _, win in ipairs(hl.get_windows()) do
		for _, t in ipairs(win.tags) do
			if tag_set[t] then
				targets[#targets + 1] = win
				break -- found a match; don't double-add this window
			end
		end
	end

	for _, win in ipairs(targets) do
		action(win)
	end
end

-- ============================================================================
-- HARDWARE KEYS
-- ============================================================================
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%+"),
	{ repeating = true, submap_universal = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%-"),
	{ repeating = true, submap_universal = true }
)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 11%+"), { repeating = true, submap_universal = true })
hl.bind(
	"XF86MonBrightnessDown",
	hl.dsp.exec_cmd("brightnessctl set 10%-"),
	{ repeating = true, submap_universal = true }
)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { submap_universal = true })
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
	{ submap_universal = true }
)
hl.bind("XF86WLAN", hl.dsp.exec_cmd("nmcli radio wifi toggle"), { submap_universal = true })
hl.bind("XF86Refresh", hl.dsp.exec_cmd("xdotool key F5"), { submap_universal = true })

-- ============================================================================
-- LAUNCHERS & SHELL HELPERS
-- ============================================================================
-- Kitty (single instance)
hl.bind(mainMod .. " + ESCAPE", hl.dsp.exec_cmd("kitty --single-instance"), { submap_universal = true })
-- Kitty (single instance)
hl.bind(mainMod .. " + SHIFT + ESCAPE", hl.dsp.exec_cmd("kitten quick-access-terminal"), { submap_universal = true })

-- Rofi
hl.bind(
	mainMod .. " + SPACE",
	hl.dsp.exec_cmd("bash ~/.config/rofi/launchers/type-7/launcher.sh"),
	{ submap_universal = true }
)

-- CopyQ
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("copyq toggle"), { submap_universal = true })
hl.bind(
	mainMod .. " + SHIFT + V",
	hl.dsp.exec_cmd("kdeconnect-cli --send-clipboard -n Shayans-Desktop"),
	{ submap_universal = true }
)

-- Popup terminal / Vivaldi-profile picker script (VP)
hl.bind(
	mainMod .. " + A",
	hl.dsp.exec_cmd("kitty --class=popup_term -e bash ~/.local/bin/VP"),
	{ submap_universal = true }
)

-- Waybar: tap = SIGUSR1 reload; hold = full reload
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("killall -SIGUSR1 waybar"), { release = true }, { submap_universal = true })
hl.bind(
	mainMod .. " + B",
	hl.dsp.exec_cmd("/home/shayan/.config/hypr/scripts/reload-waybar.sh"),
	{ long_press = true, submap_universal = true }
)

-- Screen rotate
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("~/.config/hypr/scripts/rotate.sh"))

-- Screenshot: tap = screenshot, hold = OCR
hl.bind(
	mainMod .. " + W",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot_handler.sh hold"),
	{ long_press = true, submap_universal = true }
)
hl.bind(
	mainMod .. " + W",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot_handler.sh release"),
	{ release = true, submap_universal = true }
)

hl.bind(mainMod .. " + D", function()
	hl.dispatch(hl.dsp.exec_cmd("~/.config/hypr/scripts/gotospecial.sh dashboard"))
end, { description = "Go to Dashboard" })
-- Region screenshot to swappy
-- hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd([[grim -g "$(slurp)" - | swappy -f -]]))
-- hl.bind(
-- 	mainMod .. " + SHIFT + W",
-- 	hl.dsp.exec_cmd([[grim -g "$(slurp)" - | swappy -f - & hyprctl eval 'hl.dispatch(hl.dsp.submap("movement"))']])
-- )
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("/home/shayan/.config/hypr/scripts/reference_screenshot.sh"))

-- Vivaldi vim-style passthrough
hl.bind(
	"CTRL + J",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/vimviva.sh Down Control_L j"),
	{ repeating = true, submap_universal = true }
)
hl.bind(
	"CTRL + K",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/vimviva.sh Up   Control_L k"),
	{ repeating = true, submap_universal = true }
)
-- Vivaldi: focus tab bar, then open tab context menu
hl.bind(
	mainMod .. " + X",
	hl.dsp.exec_cmd(
		[[hyprctl eval 'hl.dispatch(hl.dsp.send_shortcut({ mods = "CTRL ALT SHIFT", key = "I" }))' && hyprctl eval 'hl.dispatch(hl.dsp.send_shortcut({ mods = "SHIFT", key = "F10" }))']]
	),
	{ submap_universal = true }
)
-- Just context menu
hl.bind(
	mainMod .. " + Z",
	hl.dsp.exec_cmd([[hyprctl eval 'hl.dispatch(hl.dsp.send_shortcut({ mods = "SHIFT", key = "F10" }))']]),
	{ submap_universal = true }
)

-- Exit Hyprland (long press, so it can't be accidental)
hl.bind(mainMod .. " + N", hl.dsp.exit(), { long_press = true, submap_universal = true })

-- hl.bind(mainMod .. " + semicolon", hl.dsp.focus({ direction = "l" }), { repeating = true })
hl.bind(mainMod .. " + semicolon", hl.dsp.window.cycle_next({}), { repeating = true })
-- hl.bind(mainMod .. " + apostrophe", hl.dsp.focus({ direction = "r" }), { repeating = true })
hl.bind(mainMod .. " + apostrophe", hl.dsp.window.cycle_next({ next = false }), { repeating = true })
hl.bind(mainMod .. " + bracketleft", hl.dsp.focus({ monitor = "+1" }), { repeating = true })

-- ============================================================================
-- WINDOW ACTIONS  (selection-aware)
-- ============================================================================

-- Close
hl.bind(mainMod .. " + C", function()
	on_tag_group(function(win)
		hl.dispatch(hl.dsp.window.close({ window = "address:" .. win.address }))
		hl.dispatch(hl.dsp.submap("reset"))
	end)
end, { submap_universal = true })
-- Kill
hl.bind(mainMod .. " + C", function()
	on_tag_group(function(win)
		hl.dispatch(hl.dsp.window.kill({ window = "address:" .. win.address }))
		hl.dispatch(hl.dsp.submap("reset"))
	end)
end, { long_press = true, locked = true, submap_universal = true })

hl.bind(mainMod .. " + Q", function()
	on_tag_group(function(win)
		hl.dispatch(hl.dsp.window.kill({ window = "address:" .. win.address }))
		hl.dispatch(hl.dsp.submap("reset"))
	end)
end, { long_press = true, locked = true, submap_universal = true })

-- Fullscreen maximize (mode = "maximized")
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "maximized" }), { submap_universal = true })

-- Real fullscreen (long press)
hl.bind(
	mainMod .. " + F",
	hl.dsp.window.fullscreen({ mode = "fullscreen" }),
	{ long_press = true, submap_universal = true }
)

-- Swap with the next window in the layout.
-- (Not selection-aware: swapping a *group* of windows pairwise doesn't have
-- a meaningful interpretation.)
hl.bind(mainMod .. " + S", hl.dsp.window.swap({ next = true }), { submap_universal = true })

-- ============================================================================
-- WORKSPACE NAVIGATION  (focus only - not selection-aware)
-- ============================================================================

-- Top-level: exact (relative across all workspaces, incl. empty)
hl.bind(mainMod .. " + L", hl.dsp.focus({ workspace = "r+1" }), { repeating = true, submap_universal = true })
hl.bind(mainMod .. " + H", hl.dsp.focus({ workspace = "r-1" }), { repeating = true, submap_universal = true })

-- ============================================================================
-- MOVE WINDOW TO ANOTHER WORKSPACE  (selection-aware)
-- ============================================================================

hl.bind(
	mainMod .. " + SHIFT + L",
	function() -- one moves to the workspace to the right and other moves two to the right
		on_tag_group(function(win)
			hl.dispatch(hl.dsp.window.move({ workspace = "r+1", window = win, follow = true }))
		end)
		-- hl.dispatch(hl.dsp.window.move({ workspace = "r+1", window = "tag:selected" }, { submap_universal = true }))
		-- hl.dispatch(hl.dsp.window.move({ workspace = "r+1" }, { submap_universal = true }))
	end,
	{ submap_universal = true }
)
hl.bind(mainMod .. " + SHIFT + H", function()
	on_tag_group(function(win)
		hl.dispatch(hl.dsp.window.move({ workspace = "r-1", window = win, follow = true }))
	end)
	-- hl.dispatch(hl.dsp.window.move({ workspace = "r-1", window = "tag:selected" }, { submap_universal = true }))
	-- hl.dispatch(hl.dsp.window.move({ workspace = "r-1" }, { submap_universal = true }))
end, { submap_universal = true })
hl.bind(
	mainMod .. " + SHIFT + apostrophe",
	function() -- one moves to the workspace to the right and other moves two to the right
		on_tag_group(function(win)
			hl.dispatch(hl.dsp.window.move({ workspace = "r+1", window = win, follow = false }))
			hl.dispatch(hl.dsp.window.clear_tags({ window = win }))
			hl.dispatch(hl.dsp.submap("reset"))
		end)
		-- hl.dispatch(hl.dsp.window.move({ workspace = "r+1", window = "tag:selected" }, { submap_universal = true }))
		-- hl.dispatch(hl.dsp.window.move({ workspace = "r+1" }, { submap_universal = true }))
	end,
	{ submap_universal = true }
)
hl.bind(mainMod .. " + SHIFT + semicolon", function()
	on_tag_group(function(win)
		hl.dispatch(hl.dsp.window.move({ workspace = "r-1", window = win, follow = false }))
		hl.dispatch(hl.dsp.window.clear_tags({ window = win }))
		hl.dispatch(hl.dsp.submap("reset"))
	end)
	-- hl.dispatch(hl.dsp.window.move({ workspace = "r-1", window = "tag:selected" }, { submap_universal = true }))
	-- hl.dispatch(hl.dsp.window.move({ workspace = "r-1" }, { submap_universal = true }))
end, { submap_universal = true })
-- ============================================================================
-- RESIZE SUBMAP  (selection-aware) | Super + R
-- ============================================================================
-- SUPER+R -> resize root. From there:
--   W -> Increase submap (HJKL grow on respective axis)
--   E -> Decrease submap (HJKL shrink on respective axis)
-- Escape returns one level; SUPER+R exits entirely.
-- on_tag_group(function(win)
-- 	hl.dispatch(hl.dsp.window.close({ window = "address:" .. win.address }))
-- end)

hl.bind(mainMod .. " + G", hl.dsp.submap("grouping"), { description = "Grouping Submap" })
hl.bind(mainMod .. " + Alt_L", hl.dsp.submap("navigation"), { description = "Navigation Submap" })
hl.bind(mainMod .. " + Control_L", hl.dsp.submap("movement"), { description = "Movement Submap" })
hl.bind(mainMod .. " + P", hl.dsp.submap("properties"), { description = "Properties Submap" })
hl.bind(mainMod .. " + R", hl.dsp.submap("resize"), { description = "Resize submap" })

hl.define_submap("resize", function()
	hl.bind("H", function()
		on_tag_group(function(win)
			hl.dispatch(hl.dsp.window.resize({ x = -20, y = 0, window = win, relative = true }))
		end)
	end, { repeating = true, description = "Increase Left" })
	hl.bind("L", function()
		on_tag_group(function(win)
			hl.dispatch(hl.dsp.window.resize({ x = 20, y = 0, window = win, relative = true }))
		end)
	end, { repeating = true, description = "Increase Left" })
	hl.bind("K", function()
		on_tag_group(function(win)
			hl.dispatch(hl.dsp.window.resize({ x = 0, y = -20, window = win, relative = true }))
		end)
	end, { repeating = true, description = "Increase Left" })
	hl.bind("J", function()
		on_tag_group(function(win)
			hl.dispatch(hl.dsp.window.resize({ x = 0, y = 20, window = win, relative = true }))
		end)
	end, { repeating = true, description = "Increase Left" })
	-- hl.bind(
	-- 	"H",
	-- 	hl.dsp.window.resize({ x = -20, y = 0, relative = true }),
	-- 	{ repeating = true, description = "Increase Left" }
	-- )
	-- hl.bind(
	-- 	"L",
	-- 	hl.dsp.window.resize({ x = 20, y = 0, relative = true }),
	-- 	{ repeating = true, description = "Increase Left" }
	-- )
	-- hl.bind(
	-- 	"K",
	-- 	hl.dsp.window.resize({ x = 0, y = -20, relative = true }),
	-- 	{ repeating = true, description = "Increase Left" }
	-- )
	-- hl.bind(
	-- 	"J",
	-- 	hl.dsp.window.resize({ x = 0, y = 20, relative = true }),
	-- 	{ repeating = true, description = "Increase Left" }
	-- )
	hl.bind(mainMod .. " + G", hl.dsp.submap("grouping"), { description = "Grouping Submap" })
	hl.bind(mainMod .. " + Alt_L", hl.dsp.submap("navigation"), { description = "Navigation Submap" })
	hl.bind(mainMod .. " + Control_L", hl.dsp.submap("movement"), { description = "Movement Submap" })
	hl.bind(mainMod .. " + P", hl.dsp.submap("properties"), { description = "Properties Submap" })
	hl.bind("Escape", hl.dsp.submap("reset"))
end)

-- ============================================================================
-- GROUP SUBMAP  (not selection-aware; groups are about the active window) | Super + G
-- ============================================================================
-- SUPER+G ->
--   A -> create / toggle group
--   S -> lock active group (then exit submap)
--   D -> deny active window from being grouped
--   F -> next window in group

hl.bind(mainMod .. " + G", hl.dsp.submap("grouping"))

hl.define_submap("grouping", function()
	hl.bind("A", function()
		hl.dispatch(hl.dsp.group.toggle({}), { description = "Toggle Group" })
		hl.dispatch(hl.dsp.submap("reset"))
	end)
	hl.bind("S", function()
		hl.dispatch(hl.dsp.group.lock_active({}))
		hl.dispatch(hl.dsp.submap("reset"))
	end, { description = "Lock group" })
	-- hl.bind("D", hl.dsp.window.deny_from_group({}), { description = "Deny window from group" }) -- this doesn't work
	hl.bind("F", hl.dsp.group.next({}), { description = "Next window in Group" })
	hl.bind("SHIFT + F", hl.dsp.group.prev({}), { description = "Previous window in Group" })
	hl.bind(mainMod .. " + Alt_L", hl.dsp.submap("navigation"), { description = "Navigation Submap" })
	hl.bind(mainMod .. " + Control_L", hl.dsp.submap("movement"), { description = "Movement Submap" })
	hl.bind(mainMod .. " + P", hl.dsp.submap("properties"), { description = "Properties Submap" })
	hl.bind(mainMod .. " + R", hl.dsp.submap("resize"), { description = "Resize submap" })
	hl.bind("Escape", hl.dsp.submap("reset"))
end)

-- ============================================================================
-- NAVIGATION SUBMAP  (focus only; never selection-aware) Super + Alt_L
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
	end, { description = "Go to Extra" })
	hl.bind("D", function()
		hl.dispatch(hl.dsp.exec_cmd("~/.config/hypr/scripts/gotospecial.sh dashboard"))
		hl.dispatch(hl.dsp.submap("reset"))
	end, { description = "Go to Dashboard" })
	hl.bind("G", hl.dsp.submap("relative"), { description = "Enter Relative Submap" })
	hl.bind("H", hl.dsp.focus({ direction = "l" }), { repeating = true })
	hl.bind("J", hl.dsp.focus({ direction = "d" }), { repeating = true })
	hl.bind("K", hl.dsp.focus({ direction = "u" }), { repeating = true })
	hl.bind("L", hl.dsp.focus({ direction = "r" }), { repeating = true })
	hl.bind("F", hl.dsp.window.tag({ tag = "selected" }), { auto_consuming = true, transparent = true })

	for i = 1, 9 do
		local n = i
		hl.bind(tostring(n), function()
			hl.dispatch(hl.dsp.focus({ workspace = n }))
			hl.dispatch(hl.dsp.submap("reset"))
		end, { description = "Move window(s) to " .. n })
	end
	hl.bind("0", function()
		hl.dispatch(hl.dsp.focus({ workspace = 10 }))
		hl.dispatch(hl.dsp.submap("reset"))
	end, { description = "Go to workspace 10" })
	hl.bind(mainMod .. " + G", hl.dsp.submap("grouping"), { description = "Grouping Submap" })
	hl.bind(mainMod .. " + Control_L", hl.dsp.submap("movement"), { description = "Movement Submap" })
	hl.bind(mainMod .. " + P", hl.dsp.submap("properties"), { description = "Properties Submap" })
	hl.bind(mainMod .. " + R", hl.dsp.submap("resize"), { description = "Resize submap" })
	hl.bind("Escape", hl.dsp.submap("reset"))
end)

hl.define_submap("relative", function()
	hl.bind("L", function()
		hl.dispatch(hl.dsp.focus({ workspace = "m+1" }))
		hl.dispatch(hl.dsp.submap("navigation"))
	end, { description = "Go to Right workspace" })
	hl.bind("H", function()
		hl.dispatch(hl.dsp.focus({ workspace = "m-1" }))
		hl.dispatch(hl.dsp.submap("navigation"))
	end, { description = "Go to Left workspace" })
	hl.bind("F", hl.dsp.window.tag({ tag = "selected" }), { auto_consuming = true, transparent = true })
	hl.bind("Escape", hl.dsp.submap("navigation"))
end)

-- ============================================================================
-- MOVEMENT SUBMAP  (selection-aware where it makes sense) | Super + Control_L
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
		hl.dispatch(hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/movetospecial.sh extra"))
		hl.dispatch(hl.dsp.submap("reset"))
	end, { description = "Move window to extra" })
	hl.bind("D", function()
		hl.dispatch(hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/movetospecial.sh dashboard"))
		hl.dispatch(hl.dsp.submap("reset"))
	end, { description = "Move window to dashboard" })
	hl.bind("G", hl.dsp.submap("Relative"), { description = "Enter Relative Submap" })
	-- hl.bind("H", hl.dsp.window.move({ direction = "l" }), { description = "Move window to left" })
	-- hl.bind("J", hl.dsp.window.move({ direction = "d" }), { description = "Move window to down" })
	-- hl.bind("K", hl.dsp.window.move({ direction = "u" }), { description = "Move window to up" })
	-- hl.bind("L", hl.dsp.window.move({ direction = "r" }), { description = "Move window to right" })
	hl.bind("H", function()
		on_tag_group(function(win)
			hl.dispatch(hl.dsp.window.move({ x = -20, y = 0, window = win, relative = true }))
		end)
	end, { repeating = true, description = "Increase Left" })
	hl.bind("L", function()
		on_tag_group(function(win)
			hl.dispatch(hl.dsp.window.move({ x = 20, y = 0, window = win, relative = true }))
		end)
	end, { repeating = true, description = "Increase Left" })
	hl.bind("K", function()
		on_tag_group(function(win)
			hl.dispatch(hl.dsp.window.move({ x = 0, y = -20, window = win, relative = true }))
		end)
	end, { repeating = true, description = "Increase Left" })
	hl.bind("J", function()
		on_tag_group(function(win)
			hl.dispatch(hl.dsp.window.move({ x = 0, y = 20, window = win, relative = true }))
		end)
	end, { repeating = true, description = "Increase Left" })
	for i = 1, 9 do
		local n = i
		hl.bind(tostring(n), function()
			on_tag_group(function(win)
				hl.dispatch(hl.dsp.window.move({ workspace = n, window = win }))
				hl.dispatch(hl.dsp.window.clear_tags({ window = win }))
			end)
			hl.dispatch(hl.dsp.submap("reset"))
		end, { description = "Move window(s) to " .. n })
	end
	hl.bind("0", function()
		on_tag_group(function(win)
			hl.dispatch(hl.dsp.window.move({ workspace = "10", window = win }))
			hl.dispatch(hl.dsp.window.clear_tags({ window = win }))
		end)
		hl.dispatch(hl.dsp.submap("reset"))
	end, { description = "Move window(s) to 10" })
	-- Group in/out are about the active window's relationship to a group;
	-- hl.bind("I", hl.dsp.window.move({ into_group = "r" }), { description = "Move window into group" })
	hl.bind("I", function()
		on_tag_group(function(win)
			hl.dispatch(
				hl.dsp.window.move({ into_group = "r", window = win }),
				{ description = "Move window into group" }
			)
			hl.dispatch(hl.dsp.window.clear_tags({ window = win }))
		end)
	end)
	hl.bind("O", function()
		on_tag_group(function(win)
			hl.dispatch(
				hl.dsp.window.move({ out_of_group = true, window = win }),
				{ description = "Move window out of group" }
			)
			hl.dispatch(hl.dsp.window.clear_tags({ window = win }))
		end)
	end)
	-- hl.bind("O", hl.dsp.window.move({ out_of_group = true }), { description = "Move window out of group" })
	hl.bind("Control_L", hl.dsp.window.drag(), { mouse = true })
	hl.bind(mainMod .. " + G", hl.dsp.submap("grouping"), { description = "Grouping Submap" })
	hl.bind(mainMod .. " + Alt_L", hl.dsp.submap("navigation"), { description = "Navigation Submap" })
	hl.bind(mainMod .. " + P", hl.dsp.submap("properties"), { description = "Properties Submap" })
	hl.bind(mainMod .. " + R", hl.dsp.submap("resize"), { description = "Resize submap" })
	hl.bind("Escape", hl.dsp.submap("reset"))
end)
hl.define_submap(
	"Relative",
	function() -- unfortunately, this also moves the first workspace to the first non-empty workspace in that direction and then the second to second non-empty workspace in that direction
		hl.bind("L", function()
			on_tag_group(function(win)
				hl.dispatch(hl.dsp.window.move({ window = win, workspace = "m+1" }))
			end)
		end, { description = "Move window(s) to Right workspace" })
		hl.bind("H", function()
			on_tag_group(function(win)
				hl.dispatch(hl.dsp.window.move({ window = win, workspace = "m-1" }))
			end)
		end, { description = "Move window(s) to Right workspace" })
		hl.bind(mainMod .. " + G", hl.dsp.submap("grouping"), { description = "Grouping Submap" })
		hl.bind(mainMod .. " + Alt_L", hl.dsp.submap("navigation"), { description = "Navigation Submap" })
		hl.bind(mainMod .. " + Control_L", hl.dsp.submap("movement"), { description = "Movement Submap" })
		hl.bind(mainMod .. " + P", hl.dsp.submap("properties"), { description = "Properties Submap" })
		hl.bind(mainMod .. " + R", hl.dsp.submap("resize"), { description = "Resize submap" })
		hl.bind("Escape", hl.dsp.submap("navigation"))
	end
)

-- ============================================================================
-- PROPERTIES SUBMAP  (selection-aware where it makes sense) | Super + P
-- ============================================================================
-- SUPER+P ->
--   T -> toggle pin
--   S -> toggle layout split direction (layout-level, not per-window)
--   F -> toggle floating
--   P -> toggle pseudo-tiling

hl.bind(mainMod .. " + P", hl.dsp.submap("properties"))

hl.define_submap("properties", function()
	hl.bind("T", function()
		on_tag_group(function(win)
			hl.dispatch(hl.dsp.window.pin({ window = "address:" .. win.address }))
		end)
	end, { description = "Pin window(s)" })
	hl.bind("S", hl.dsp.layout("togglesplit"), { description = "Toggle split" })
	hl.bind("F", function()
		on_tag_group(function(win)
			hl.dispatch(hl.dsp.window.float({ window = "address:" .. win.address }))
		end)
	end, { description = "Float window(s)" })
	hl.bind("P", function()
		on_tag_group(function(win)
			hl.dispatch(hl.dsp.window.pseudo({ window = "address:" .. win.address }))
		end)
	end, { description = "Toggle pseudo" })
	hl.bind(mainMod .. " + G", hl.dsp.submap("grouping"), { description = "Grouping Submap" })
	hl.bind(mainMod .. " + Alt_L", hl.dsp.submap("navigation"), { description = "Navigation Submap" })
	hl.bind(mainMod .. " + Control_L", hl.dsp.submap("movement"), { description = "Movement Submap" })
	hl.bind(mainMod .. " + R", hl.dsp.submap("resize"), { description = "Resize submap" })
	hl.bind("Escape", hl.dsp.submap("reset"))
end)

-- ============================================================================
-- TAGGING (the selection itself - not wrapped)
-- ============================================================================
-- SUPER+T ->
--   S -> add the active window to the selection (idempotent)
--   D -> clear ALL tags from the active window
--        (matches your old D behavior; gets the window completely out of
--         both "selected" and "prev_selected")

-- I don't think i need another keybind to select tabs. I am only batch action(and therefore navigating to all of the tabs ) in navigation submap
-- hl.bind(mainMod .. " + Return", function()
-- 	hl.dispatch(hl.dsp.window.tag({ tag = "selected" }), { non_consuming = true })
-- end, { submap_universal = true })
hl.bind(mainMod .. " + Return", function()
	on_tag_group(function(win)
		hl.dispatch(hl.dsp.window.clear_tags({ window = win }), { non_consuming = true })
	end)
end, { submap_universal = true })
-- I am contemplating removing this submap since tagging is needed to make so much of this script work
-- hl.bind(mainMod .. " + T", hl.dsp.submap("tagging"))
-- hl.define_submap("tagging", function()
-- 	-- S: add active window to selection.
-- 	-- hl.dsp.window.tag sets the Hyprland tag (border colour).
-- 	-- action binds know which windows to batch over.
-- 	-- Both are required; one without the other is the bug that was here.
-- 	hl.bind("S", function()
-- 		hl.dispatch(hl.dsp.window.tag({ tag = "+selected" }))
-- 		hl.dispatch(hl.dsp.window.tag({ tag = "-selected", window = "tag:selected" }))
-- 		hl.dispatch(hl.dsp.window.tag({ tag = "-selected" }))
-- 	end)
--
-- 	hl.bind("Escape", hl.dsp.submap("reset"))
-- end)

-- ============================================================================
-- MOUSE
-- ============================================================================

hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "m-1" }), { mouse = true, submap_universal = true })
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "m+1" }), { mouse = true, submap_universal = true })
