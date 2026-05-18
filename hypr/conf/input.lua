-- created with Claude. Account: Milobowler
-- See https://wiki.hypr.land/Configuring/Basics/Variables/

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "caps:escape",
        kb_rules   = "",

        follow_mouse = 1,
        sensitivity  = 0, -- -1.0 to 1.0, 0 = no modification

        touchpad = {
            natural_scroll       = true,
            disable_while_typing = true,
            -- scroll_factor = 0.07,
        },
    },
})
