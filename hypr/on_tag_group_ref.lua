-- =============================================================================
-- on_tag_group — reference
-- =============================================================================
--
-- SIGNATURE
--   on_tag_group(action)
--   action : function(win: HL.Window)  called once per resolved target
--
-- RESOLUTION
--   nothing focused              → no-op, action never runs
--   focused window has no tags  → action(focused_window)  (just that one)
--   focused window has tags     → action(win) for every window that shares
--                                 any tag with the focused window
--                                 (snapshot is taken before acting, so
--                                  closing window N doesn't skip window N+1)
--
-- BASIC SHAPE
--   hl.bind(mainMod .. " + KEY", function()
--     on_tag_group(function(win)
--       hl.dispatch(hl.dsp.window.DISPATCHER(..., win))
--     end)
--   end)
--
-- =============================================================================
-- HL.Window — properties available inside the callback
-- =============================================================================
--
--   win.address         string    "0x…"   unique handle; use for selectors
--   win.class           string    WM_CLASS (e.g. "firefox", "kitty")
--   win.title           string    current window title
--   win.initial_class   string    class at spawn time
--   win.initial_title   string    title at spawn time
--   win.pid             integer
--   win.tags            table     array of tag strings  (#win.tags == 0 → untagged)
--   win.floating        boolean
--   win.pinned          boolean
--   win.fullscreen      integer   0 none · 1 maximized · 2 fullscreen
--   win.xwayland        boolean
--   win.workspace       HL.Workspace  (or nil)
--   win.monitor         HL.Monitor    (or nil)
--   win.active          boolean   true if this is the currently focused window
--
-- =============================================================================
-- Window selector — how to pass `win` to a dispatcher
-- =============================================================================
--
--   PREFERRED — pass the object directly:
--     hl.dsp.window.close(win)
--     hl.dsp.window.float({ action = "toggle", window = win })
--
--   ALTERNATIVE — address string (identical effect):
--     hl.dsp.window.close("address:" .. win.address)
--     hl.dsp.window.float({ action = "toggle", window = "address:" .. win.address })
--
--   Other selector forms (rarely needed inside the callback):
--     "class:regex"         "title:regex"
--     "tag:name"            "pid:1234"
--     "activewindow"        "floating"       "tiled"
--
-- =============================================================================
-- hl.dsp.window — dispatchers useful with on_tag_group
-- =============================================================================
--
--   CLOSE / KILL
--     close(win?)                       graceful close (respects close events)
--     kill(win?)                        force-kill (SIGKILL equivalent)
--
--   MOVE
--     move({ workspace, window? })      move to workspace (see selectors below)
--     move({ monitor,   window? })      move to monitor   (name / id / direction)
--     move({ x, y, relative?, window? }) move floating window to / by a coord
--
--   FLOAT / PIN / PSEUDO
--     float({ action?, window? })       action: "toggle"(default) "set" "unset"
--     pin({   window? })                toggle pinned (visible on all workspaces)
--     pseudo({ action?, window? })      pseudotile toggle; action same as float
--
--   FULLSCREEN
--     fullscreen({ mode?, action?, window? })
--       mode:   "maximized" · "fullscreen"(default)
--       action: "toggle"(default) · "set" · "unset"
--
--     fullscreen_state({ internal, client, action?, window? })
--       internal / client values:  -1 current · 0 none · 1 maximize · 2 fullscreen
--       e.g. { internal=2, client=0 } → fullscreen Hyprland-side, client unaware
--
--   TAGS
--     tag({ tag, window? })             "+name" add · "-name" remove · "name" toggle
--     clear_tags({ window? })           remove all tags
--
--   APPEARANCE
--     set_prop({ prop, value, window? }) set a dynamic window property
--       useful props: "no_anim" "no_blur" "no_rounding" "opacity" "rounding"
--       value is always a string:  { prop = "opacity", value = "0.8" }
--     alter_zorder({ mode, window? })   mode: "top" · "bottom"
--     center({ window? })              center a floating window on screen
--
-- =============================================================================
-- Workspace selectors (for window.move { workspace = … })
-- =============================================================================
--
--   1, 2, 13           absolute ID
--   "+1"  "-1"         relative to current
--   "m+1" "m~2"        relative / absolute on current monitor
--   "name:Web"         named workspace
--   "special"          default special workspace (scratchpad)
--   "special:name"     named special workspace
--   "empty"            first available empty workspace
--   "previous"         last visited workspace
--
-- =============================================================================
-- Patterns
-- =============================================================================

-- Close group (or single window)
hl.bind(mainMod .. " + C", function()
  on_tag_group(function(win)
    hl.dispatch(hl.dsp.window.close(win))
  end)
end)

-- Move group to a scratchpad
hl.bind(mainMod .. " + S", function()
  on_tag_group(function(win)
    hl.dispatch(hl.dsp.window.move({ workspace = "special:scratch", window = win }))
  end)
end)

-- Float the whole group
hl.bind(mainMod .. " + SHIFT + F", function()
  on_tag_group(function(win)
    hl.dispatch(hl.dsp.window.float({ action = "set", window = win }))
  end)
end)

-- Move group to next workspace
hl.bind(mainMod .. " + SHIFT + Right", function()
  on_tag_group(function(win)
    hl.dispatch(hl.dsp.window.move({ workspace = "+1", window = win }))
  end)
end)

-- Strip all tags from the group (untag everything that matched)
hl.bind(mainMod .. " + T", function()
  on_tag_group(function(win)
    hl.dispatch(hl.dsp.window.clear_tags({ window = win }))
  end)
end)

-- Fade out a group (set opacity on each window)
hl.bind(mainMod .. " + O", function()
  on_tag_group(function(win)
    hl.dispatch(hl.dsp.window.set_prop({ prop = "opacity", value = "0.6", window = win }))
  end)
end)
