-- created with Claude. Account: Milobowler
-- Environment variables via hl.env().
-- NOTE: If you use uwsm, the recommended approach is to put these in
--       ~/.config/uwsm/env (common) or ~/.config/uwsm/env-hyprland (Hyprland-specific)
--       instead of here. If you don't use uwsm, this file is fine.

-- XDG Desktop Portal
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE",    "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- QT
hl.env("QT_QPA_PLATFORM",                 "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME",            "qt6ct")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR",     "1")

-- GTK
hl.env("GDK_SCALE", "1")

-- Mozilla
hl.env("MOZ_ENABLE_WAYLAND", "1")

-- Cursor size (replaces the old cursor.conf)
hl.env("XCURSOR_SIZE", "24")

-- Disable AppImage Launcher by default
hl.env("APPIMAGELAUNCHER_DISABLE", "1")

-- Ozone (Electron/Chromium apps)
hl.env("OZONE_PLATFORM", "wayland")

-- NVIDIA (uncomment if needed)
-- hl.env("LIBVA_DRIVER_NAME",           "nvidia")
-- hl.env("GBM_BACKEND",                 "nvidia-drm")
-- hl.env("__GLX_VENDOR_LIBRARY_NAME",   "nvidia")
-- hl.env("__GL_VRR_ALLOWED",            "1")
-- hl.env("WLR_DRM_NO_ATOMIC",           "1")

-- KVM / Virtual Machine (uncomment if needed)
-- hl.env("WLR_NO_HARDWARE_CURSORS",     "1")
-- hl.env("WLR_RENDERER_ALLOW_SOFTWARE", "1")
