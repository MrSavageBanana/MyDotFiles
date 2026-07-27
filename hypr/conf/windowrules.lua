-- created with Claude. Account: Milobowler
-- See https://wiki.hypr.land/Configuring/Window-Rules/

-- Rofi: always float, centered, no animation, no border
hl.window_rule({
	match = { class = "^(rofi)$" },
	float = true,
	center = true,
	no_anim = true,
	border_size = 0,
})

-- KRuler: float with border
hl.window_rule({
	match = { class = "^(org.kde.kruler)$" },
	float = true,
})

-- XDG Desktop Portal: float
hl.window_rule({
	match = { class = "xdg-desktop-portal-gtk" },
	float = true,
})

-- Vivaldi profile picker / popup terminal
hl.window_rule({
	match = { class = "^(popup_term)$" },
	float = true,
	center = true,
	size = { 350, 280 },
})
-- Vivaldi per-profile border colors
-- Tags are applied by the launch script after each window opens.
-- Profile 1 — Milo (magenta)
hl.window_rule({
	border_color = "rgb(ff00ff) rgb(ff00ff)",
	match = { title = [[.*\[Milo\].*]] },
})

-- Profile 2 — Nasr (orange)
hl.window_rule({
	border_color = "rgb(ff8800) rgb(ff8800)",
	match = { title = [[.*\[Nasr\].*]] },
})

-- Profile 3 — Unscripted (cyan)
hl.window_rule({
	border_color = "rgb(00ccff) rgb(00ccff)",
	match = { title = [[.*\[Unscripted\].*]] },
})

-- Profile 4 — TT (yellow)
hl.window_rule({
	border_color = "rgb(ffee00) rgb(ffee00)",
	match = { title = [[.*\[TT\].*]] },
})

-- Profile 5 — Burhan (lime)
hl.window_rule({
	border_color = "rgb(88ff00) rgb(88ff00)",
	match = { title = [[.*\[Burhan\].*]] },
})

-- Profile 6 — Amy (pink)
hl.window_rule({
	border_color = "rgb(ff69b4) rgb(ff69b4)",
	match = { title = [[.*\[Amy\].*]] },
})

-- Profile 7 — Pics (purple)
hl.window_rule({
	border_color = "rgb(9900ff) rgb(9900ff)",
	match = { title = [[.*\[Pics\].*]] },
})
-- I think the latest takes precedence. Yup
-- I think the latest takes precedence
-- Selecting
hl.window_rule({
	border_color = "rgb(ff1493) rgb(ff1493)",
	match = { tag = "selected" },
})

hl.window_rule({
	border_color = "rgb(00ff00) rgb(00ff00)",
	match = { tag = "prev_selected" },
})
-- To get more information about a window’s class, title, XWayland status or its size, you can use `hyprctl clients`. (From Hyprland Wiki)
local windowrulev2 = {
	"float,class:^(one.alynx.showmethekey)$",
	"float,class:^(showmethekey-gtk)$", -- make window floating
	"pin,class:^(showmethekey-gtk)$", -- pin window
}

-- If your Lua setup expects them to be assigned directly to a config table:
-- config.windowrulev2 = windowrulev2
