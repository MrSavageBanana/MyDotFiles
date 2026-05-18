-- created with Claude. Account: Milobowler
-- See https://wiki.hypr.land/Configuring/Window-Rules/

-- Rofi: always float, centered, no animation, no border
hl.window_rule({
    match       = { class = "^(rofi)$" },
    float       = true,
    center      = true,
    no_anim     = true,
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
    match  = { class = "^(popup_term)$" },
    float  = true,
    center = true,
    size   = { x = 350, y = 280 },
})
