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
	match = { tag = "vivaldi_profile_1" },
})

-- Profile 2 — Nasr (orange)
hl.window_rule({
	border_color = "rgb(ff8800) rgb(ff8800)",
	match = { tag = "vivaldi_profile_2" },
})

-- Profile 3 — Unscripted (cyan)
hl.window_rule({
	border_color = "rgb(00ccff) rgb(00ccff)",
	match = { tag = "vivaldi_profile_3" },
})

-- Profile 4 — TT (yellow)
hl.window_rule({
	border_color = "rgb(ffee00) rgb(ffee00)",
	match = { tag = "vivaldi_profile_4" },
})

-- Profile 5 — Burhan (lime)
hl.window_rule({
	border_color = "rgb(88ff00) rgb(88ff00)",
	match = { tag = "vivaldi_profile_5" },
})

-- Profile 6 — Amy (pink)
hl.window_rule({
	border_color = "rgb(ff69b4) rgb(ff69b4)",
	match = { tag = "vivaldi_profile_6" },
})

-- Profile 7 — Pics (purple)
hl.window_rule({
	border_color = "rgb(9900ff) rgb(9900ff)",
	match = { tag = "vivaldi_profile_7" },
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
