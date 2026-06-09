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
hl.bind(
	mainMod .. " + SHIFT + F1",
	hl.dsp.exec_cmd(
		"bash -c 'pkill -f whichkey-listen.sh; sleep 0.2; ~/.config/hypr/hyprvim/scripts/whichkey-listen.sh &'"
	)
)
local function hsel(action, params, multi_action, multi_params)
	local function build(act, p)
		if p and p ~= "" then
			return "dispatch hl.dsp.window." .. act .. "({ " .. p .. ', window = "{}" })'
		end
		return "dispatch hl.dsp.window." .. act .. '({ window = "{}" })'
	end
	local s = build(action, params)
	local m = build(multi_action or action, multi_params ~= nil and multi_params or params)
	if multi_action then
		return "hyprsel action '" .. s .. "' '" .. m .. "'"
	end
	return "hyprsel action '" .. s .. "'"
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

-- Region screenshot to swappy
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd([[grim -g "$(slurp)" - | swappy -f -]]))

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
	mainMod .. " + SHIFT + X",
	hl.dsp.exec_cmd(
		[[hyprctl eval 'hl.dispatch(hl.dsp.send_shortcut({ mods = "SHIFT", key = "F10" }))']],
		{ submap_universal = true }
	)
)

-- Exit Hyprland (long press, so it can't be accidental)
hl.bind(mainMod .. " + N", hl.dsp.exit(), { long_press = true, submap_universal = true })

-- ============================================================================
-- WINDOW ACTIONS  (selection-aware)
-- ============================================================================

-- Close
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd(hsel("close")), { submap_universal = true })

-- Kill (long press, locked)
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd(hsel("kill")), { long_press = true, locked = true, submap_universal = true })

-- Kill (long press)
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(hsel("kill")), { long_press = true, locked = true, submap_universal = true })

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
	hl.dsp.exec_cmd("/home/shayan/.config/hypr/scripts/ws-move-next.sh"),
	{ submap_universal = true }
)
hl.bind(
	mainMod .. " + SHIFT + H",
	hl.dsp.exec_cmd("/home/shayan/.config/hypr/scripts/ws-move-prev.sh"),
	{ submap_universal = true }
)

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
	hl.bind("H", hl.dsp.exec_cmd(hsel("resize", "x = -20, y = 0, relative = true")), { repeating = true })
	hl.bind("L", hl.dsp.exec_cmd(hsel("resize", "x = 20, y = 0, relative = true")), { repeating = true })
	hl.bind("K", hl.dsp.exec_cmd(hsel("resize", "x = 0, y = 20, relative = true")), { repeating = true })
	hl.bind("J", hl.dsp.exec_cmd(hsel("resize", "x = 0, y = -20, relative = true")), { repeating = true })
	hl.bind("Escape", hl.dsp.submap("resize"))
end)

hl.define_submap("Decrease_size", function()
	hl.bind("H", hl.dsp.exec_cmd(hsel("resize", "x = 20, y = 0, relative = true")), { repeating = true })
	hl.bind("L", hl.dsp.exec_cmd(hsel("resize", "x = -20, y = 0, relative = true")), { repeating = true })
	hl.bind("K", hl.dsp.exec_cmd(hsel("resize", "x = 0, y = -20, relative = true")), { repeating = true })
	hl.bind("J", hl.dsp.exec_cmd(hsel("resize", "x = 0, y = 20, relative = true")), { repeating = true })
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
	hl.bind("A", hl.dsp.group.toggle({}), { description = "Toggle Group" })
	hl.bind("S", function()
		hl.dispatch(hl.dsp.group.lock_active({}))
		hl.dispatch(hl.dsp.submap("reset"))
	end)
	hl.bind("D", hl.dsp.window.deny_from_group({}), { description = "Deny window from group" })
	hl.bind("F", hl.dsp.group.next({}), { description = "Next window in Group" })
	hl.bind("SHIFT + F", hl.dsp.group.prev({}), { description = "Previous window in Group" })
	hl.bind("Escape", hl.dsp.submap("reset"), { description = "Exit Group Submap" })
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
	hl.bind("G", hl.dsp.submap("focus"))
	hl.bind("H", hl.dsp.focus({ direction = "l" }), { repeating = true })
	hl.bind("J", hl.dsp.focus({ direction = "d" }), { repeating = true })
	hl.bind("K", hl.dsp.focus({ direction = "u" }), { repeating = true })
	hl.bind("L", hl.dsp.focus({ direction = "r" }), { repeating = true })
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
	hl.bind("L", function()
		hl.dispatch(hl.dsp.focus({ workspace = "m+1" }))
		hl.dispatch(hl.dsp.submap("reset"))
	end)
	hl.bind("H", function()
		hl.dispatch(hl.dsp.focus({ workspace = "m-1" }))
		hl.dispatch(hl.dsp.submap("reset"))
	end)
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
	hl.bind("Control_L", hl.dsp.window.drag(), { mouse = true })
	hl.bind("S", function()
		hl.dispatch(hl.dsp.exec_cmd("~/.config/hypr/scripts/movetospecial.sh extra"))
		hl.dispatch(hl.dsp.submap("reset"))
	end)
	hl.bind("D", function()
		hl.dispatch(hl.dsp.exec_cmd("~/.config/hypr/scripts/movetospecial.sh dashboard"))
		hl.dispatch(hl.dsp.submap("reset"))
	end)
	hl.bind("L", hl.dsp.exec_cmd(hsel("move", 'workspace = "m+1"', "move", 'workspace = "m+1", follow = false')))
	hl.bind("H", hl.dsp.exec_cmd(hsel("move", 'workspace = "m-1"', "move", 'workspace = "m-1", follow = false')))
	for i = 1, 9 do
		local n = i
		hl.bind(tostring(n), function()
			hl.dispatch(
				hl.dsp.exec_cmd(
					hsel("move", 'workspace = "' .. n .. '"', "move", 'workspace = "' .. n .. '", follow = false')
				)
			)
			hl.dispatch(hl.dsp.submap("reset"))
		end)
	end
	hl.bind("0", function()
		hl.dispatch(hl.dsp.exec_cmd(hsel("move", 'workspace = "10"', "move", 'workspace = "10", follow = false')))
		hl.dispatch(hl.dsp.submap("reset"))
	end)
	-- Group in/out are about the active window's relationship to a group;
	-- multi-window doesn't have a clean interpretation, so we leave these
	-- single-target.
	hl.bind("I", hl.dsp.window.move({ into_group = "r" }))
	hl.bind("O", hl.dsp.window.move({ out_of_group = true }))
	hl.bind("Control_L", hl.dsp.window.drag(), { mouse = true })
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
	hl.bind("T", hl.dsp.exec_cmd(hsel("pin")))
	hl.bind("S", hl.dsp.layout("togglesplit")) -- not per-window
	hl.bind("F", hl.dsp.exec_cmd(hsel("float")))
	hl.bind("P", hl.dsp.exec_cmd(hsel("pseudo")))
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

hl.bind("ALT + SPACE", function()
	hl.dispatch(hl.dsp.window.tag({ tag = "+selected" }))
	hl.dispatch(hl.dsp.exec_cmd("hyprsel select"))
end)
hl.define_submap("tagging", function()
	-- S: add active window to selection.
	-- hl.dsp.window.tag sets the Hyprland tag (border colour).
	-- hyprsel select syncs the daemon's internal selected set so that
	-- action binds know which windows to batch over.
	-- Both are required; one without the other is the bug that was here.
	hl.bind("S", function()
		hl.dispatch(hl.dsp.window.tag({ tag = "+selected" }))
		hl.dispatch(hl.dsp.exec_cmd("hyprsel select"))
	end)

	-- D: remove active window from selection (deselect, not clear-all).
	hl.bind("D", function()
		hl.dispatch(hl.dsp.window.tag({ tag = "-selected" }))
		hl.dispatch(hl.dsp.exec_cmd("hyprsel deselect"))
	end)

	-- X: drop the entire live selection without performing any action.
	hl.bind("X", function()
		hl.dispatch(hl.dsp.exec_cmd("hyprsel clear"))
		hl.dispatch(hl.dsp.submap("reset"))
	end)

	-- R: restore the previous selection (swap selected <-> prev_selected).
	hl.bind("R", function()
		hl.dispatch(hl.dsp.exec_cmd("hyprsel reselect"))
		hl.dispatch(hl.dsp.submap("reset"))
	end)

	hl.bind("Escape", hl.dsp.submap("reset"))
end)

-- ============================================================================
-- MOUSE
-- ============================================================================

hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "m-1" }), { mouse = true, submap_universal = true })
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "m+1" }), { mouse = true, submap_universal = true })
