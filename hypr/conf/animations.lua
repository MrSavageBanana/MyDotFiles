-- created with Claude. Account: Milobowler
-- See https://wiki.hypr.land/Configuring/Animations/
-- NOTE: The bezier/animation Lua API may differ from hl.config() nesting.
--       If hl.bezier() / hl.animation() are available as top-level functions
--       in your Hyprland version, prefer those. Check the wiki link above.

hl.config({
    animations = {
        enabled = true,
    },
})

-- Animation curves (bezier definitions)
hl.bezier("linear",         0,    0,    1,    1)
hl.bezier("md3_standard",   0.2,  0,    0,    1)
hl.bezier("md3_decel",      0.05, 0.7,  0.1,  1)
hl.bezier("md3_accel",      0.3,  0,    0.8,  0.15)
hl.bezier("overshot",       0.05, 0.9,  0.1,  1.1)
hl.bezier("crazyshot",      0.1,  1.5,  0.76, 0.92)
hl.bezier("hyprnostretch",  0.05, 0.9,  0.1,  1.0)
hl.bezier("menu_decel",     0.1,  1,    0,    1)
hl.bezier("menu_accel",     0.38, 0.04, 1,    0.07)
hl.bezier("easeInOutCirc",  0.85, 0,    0.15, 1)
hl.bezier("easeOutCirc",    0,    0.55, 0.45, 1)
hl.bezier("easeOutExpo",    0.16, 1,    0.3,  1)
hl.bezier("softAcDecel",    0.26, 0.26, 0.15, 1)
hl.bezier("md2",            0.4,  0,    0.2,  1) -- use with .2s duration

-- Animation configs
hl.animation("windows",       true, 3,  "md3_decel",  "popin 60%")
hl.animation("windowsIn",     true, 3,  "md3_decel",  "popin 60%")
hl.animation("windowsOut",    true, 3,  "md3_accel",  "popin 60%")
hl.animation("border",        true, 10, "default")
hl.animation("fade",          true, 3,  "md3_decel")
-- hl.animation("layers",     true, 2,  "md3_decel",  "slide")
hl.animation("layersIn",      true, 3,  "menu_decel", "slide")
-- hl.animation("layersOut",  true, 1.6,"menu_accel")   -- Old ML4W
hl.animation("layersOut",     true, 0.5,"menu_accel")
hl.animation("fadeLayersIn",  true, 2,  "menu_decel")
-- fadeLayersOut disabled (only hyprpaper + waybar are other layers)
hl.animation("fadeLayersOut", false)
hl.animation("workspaces",    true, 7,  "menu_decel", "slide")
-- hl.animation("workspaces", true, 2.5,"softAcDecel", "slide")
-- hl.animation("workspaces", true, 7,  "menu_decel", "slidefade 15%")
-- hl.animation("specialWorkspace", true, 3, "md3_decel", "slidefadevert 15%")
hl.animation("specialWorkspace", true, 3, "md3_decel", "slidevert")
